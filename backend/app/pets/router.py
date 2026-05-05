"""
PAW — Pets Router
Endpoints para publicar, listar y gestionar fichas de mascotas.
Incluye integración con Cloudinary para uploads firmados.
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.auth.dependencies import get_current_user
from app.core.cloudinary_utils import generate_signed_upload_params
from app.core.matching import calculate_compatibility
from app.database import get_db
from app.main import get_rate_limit, limiter
from app.pets.models import Pet, PetPhoto, PetStatus, Species, PetSize
from app.pets.schemas import PetCreate, PetPhotoCreate, PetPhotoRead, PetRead, PetUpdate
from app.users.models import AdopterProfile, User

router = APIRouter(prefix="/pets", tags=["Pets"])


@router.get("/signed-upload")
@limiter.limit(get_rate_limit("10 per day"))
async def get_signed_upload(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    """
    Genera parámetros firmados para que el cliente suba una foto
    directamente a Cloudinary sin pasar el archivo por nuestro backend.
    Esto ahorra ancho de banda y costos en el free tier.
    """
    return generate_signed_upload_params(
        folder="pets",
        user_id=str(current_user.id),
    )


@router.post("", response_model=PetRead, status_code=status.HTTP_201_CREATED)
async def create_pet(
    pet_in: PetCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Publica una nueva ficha de mascota.
    Requiere al menos 2 fotos (ya subidas a Cloudinary).
    El usuario debe tener rol de donante o ambos.
    """
    # Validar que el usuario tenga permiso para publicar
    if current_user.role.value not in ["donor", "both", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only donors can publish pets. Update your role first.",
        )

    # Crear la mascota
    pet_data = pet_in.model_dump(exclude={"photos"})
    db_pet = Pet(
        donor_id=current_user.id,
        # Heredar ubicación del donante si no se especifica
        latitude=pet_data.pop("latitude", None) or current_user.latitude,
        longitude=pet_data.pop("longitude", None) or current_user.longitude,
        **pet_data,
    )
    db.add(db_pet)
    await db.flush()  # Para obtener el ID antes de crear las fotos

    # Crear las fotos asociadas
    for i, photo_data in enumerate(pet_in.photos):
        db_photo = PetPhoto(
            pet_id=db_pet.id,
            cloudinary_url=photo_data.cloudinary_url,
            cloudinary_public_id=photo_data.cloudinary_public_id,
            is_primary=(i == 0),  # La primera foto es la principal
            order=i,
        )
        db.add(db_photo)

    await db.commit()

    # Recargar con fotos incluidas para la respuesta
    stmt = select(Pet).where(Pet.id == db_pet.id).options(selectinload(Pet.photos))
    result = await db.execute(stmt)
    return result.scalar_one()


@router.get("", response_model=list[PetRead])
async def list_pets(
    species: Optional[Species] = None,
    size: Optional[PetSize] = None,
    age_min: Optional[int] = Query(None, ge=0, description="Edad mínima en meses"),
    age_max: Optional[int] = Query(None, ge=0, description="Edad máxima en meses"),
    city: Optional[str] = None,
    province: Optional[str] = None,
    donor_id: Optional[UUID] = Query(
        None, description="Filtrar por donante (muestra todos los estados)"
    ),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Lista mascotas con filtros básicos.
    Si no se especifica donor_id, solo muestra mascotas con status 'available'.
    Si se especifica donor_id, muestra TODOS los estados de ese donante.
    """
    stmt = select(Pet).options(selectinload(Pet.photos))

    if donor_id:
        stmt = stmt.where(Pet.donor_id == donor_id)
    else:
        stmt = stmt.where(Pet.status == PetStatus.AVAILABLE)

    # Aplicar filtros
    if species:
        stmt = stmt.where(Pet.species == species)
    if size:
        stmt = stmt.where(Pet.size == size)
    if age_min is not None:
        stmt = stmt.where(Pet.age_months >= age_min)
    if age_max is not None:
        stmt = stmt.where(Pet.age_months <= age_max)
    if city:
        stmt = stmt.where(Pet.city.ilike(f"%{city}%"))
    if province:
        stmt = stmt.where(Pet.province.ilike(f"%{province}%"))

    stmt = stmt.order_by(Pet.created_at.desc()).offset(offset).limit(limit)

    result = await db.execute(stmt)
    pets = result.scalars().all()

    # Calculate compatibility for adopters viewing the feed
    enriched = []
    if not donor_id and current_user.role.value in ("adopter", "both", "admin"):
        profile_stmt = select(AdopterProfile).where(
            AdopterProfile.user_id == current_user.id
        )
        profile_result = await db.execute(profile_stmt)
        adopter_profile = profile_result.scalar_one_or_none()

        for pet in pets:
            donor_stmt = select(User).where(User.id == pet.donor_id)
            donor_result = await db.execute(donor_stmt)
            donor = donor_result.scalar_one_or_none()

            pet_data = PetRead.model_validate(pet)
            pet_data.compatibility_score = calculate_compatibility(
                adopter_profile, current_user, pet, donor
            )
            enriched.append(pet_data)
        return enriched

    return [PetRead.model_validate(p) for p in pets]


@router.get("/{pet_id}", response_model=PetRead)
async def get_pet(
    pet_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Obtiene el detalle completo de una mascota incluyendo sus fotos.
    """
    stmt = select(Pet).where(Pet.id == pet_id).options(selectinload(Pet.photos))
    result = await db.execute(stmt)
    pet = result.scalar_one_or_none()

    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet not found",
        )

    return pet


@router.patch("/{pet_id}", response_model=PetRead)
async def update_pet(
    pet_id: UUID,
    pet_in: PetUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Actualiza los datos de una mascota.
    Solo el tutor de la mascota puede modificarla.
    """
    stmt = select(Pet).where(Pet.id == pet_id).options(selectinload(Pet.photos))
    result = await db.execute(stmt)
    pet = result.scalar_one_or_none()

    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet not found",
        )

    if pet.donor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update your own pets.",
        )

    update_data = pet_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(pet, key, value)

    await db.commit()
    await db.refresh(pet)

    return pet


@router.post(
    "/{pet_id}/photos", response_model=PetPhotoRead, status_code=status.HTTP_201_CREATED
)
async def add_pet_photo(
    pet_id: UUID,
    photo_in: PetPhotoCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Agrega una foto adicional a una mascota existente.
    Solo el donante dueño de la publicación puede agregar fotos.
    """
    stmt = select(Pet).where(Pet.id == pet_id)
    result = await db.execute(stmt)
    pet = result.scalar_one_or_none()

    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet not found",
        )

    if pet.donor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only add photos to your own pets.",
        )

    # Contar fotos existentes para definir el orden
    count_stmt = select(PetPhoto).where(PetPhoto.pet_id == pet_id)
    count_result = await db.execute(count_stmt)
    existing_count = len(count_result.scalars().all())

    db_photo = PetPhoto(
        pet_id=pet_id,
        cloudinary_url=photo_in.cloudinary_url,
        cloudinary_public_id=photo_in.cloudinary_public_id,
        is_primary=photo_in.is_primary,
        order=existing_count,
    )
    db.add(db_photo)
    await db.commit()
    await db.refresh(db_photo)

    return db_photo
