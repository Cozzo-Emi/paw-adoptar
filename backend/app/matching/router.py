"""
PAW — Matching Router
Endpoints para expresar interés, aceptar/rechazar matches.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.auth.dependencies import get_current_user
from app.core.firebase import notify_new_match, notify_match_accepted
from app.database import get_db
from app.matching.models import Match, MatchStatus, PostAdoptionEvidence
from app.matching.schemas import MatchCreate, MatchRead, PostAdoptionEvidenceCreate, PostAdoptionEvidenceRead
from app.pets.models import Pet, PetStatus
from app.users.models import User

router = APIRouter(prefix="/matches", tags=["Matching"])


@router.post("", response_model=MatchRead, status_code=status.HTTP_201_CREATED)
async def create_match(
    match_in: MatchCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    El adoptante expresa interés en una mascota.
    Crea un match con status 'pending' que el donante debe aceptar.
    """
    # Validar que el usuario tenga rol de adoptante
    if current_user.role.value not in ["adopter", "both", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only adopters can express interest in pets.",
        )

    # Verificar que la mascota existe y está disponible
    stmt = select(Pet).where(Pet.id == match_in.pet_id)
    result = await db.execute(stmt)
    pet = result.scalar_one_or_none()

    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet not found",
        )
    if pet.status != PetStatus.AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This pet is not available for adoption.",
        )

    # Verificar que no haya un match activo duplicado
    existing_stmt = select(Match).where(
        and_(
            Match.pet_id == match_in.pet_id,
            Match.adopter_id == current_user.id,
            Match.status.in_([MatchStatus.PENDING, MatchStatus.ACCEPTED]),
        )
    )
    existing = await db.execute(existing_stmt)
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have an active match for this pet.",
        )

    # No te podés matchear con tu propia mascota
    if pet.donor_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot express interest in your own pet.",
        )

    db_match = Match(
        pet_id=match_in.pet_id,
        adopter_id=current_user.id,
        donor_id=pet.donor_id,
        adopter_message=match_in.adopter_message,
        status=MatchStatus.PENDING,
    )
    db.add(db_match)
    await db.commit()
    await db.refresh(db_match)

    # Fetch donor to get FCM token
    donor_stmt = select(User).where(User.id == pet.donor_id)
    donor_result = await db.execute(donor_stmt)
    donor = donor_result.scalar_one_or_none()

    if donor and donor.fcm_token:
        background_tasks.add_task(
            notify_new_match, 
            fcm_token=donor.fcm_token, 
            pet_name=pet.name, 
            adopter_name=current_user.full_name
        )

    return db_match


@router.get("/me", response_model=list[MatchRead])
async def list_my_matches(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Lista los matches del usuario actual.
    Si es adoptante: muestra sus solicitudes.
    Si es donante: muestra solicitudes recibidas.
    Si es ambos: muestra todo.
    """
    conditions = []

    if current_user.role.value in ["adopter", "both", "admin"]:
        conditions.append(Match.adopter_id == current_user.id)
    if current_user.role.value in ["donor", "both", "admin"]:
        conditions.append(Match.donor_id == current_user.id)

    if not conditions:
        return []

    # OR entre las condiciones
    from sqlalchemy import or_
    stmt = (
        select(Match)
        .where(or_(*conditions))
        .order_by(Match.created_at.desc())
    )

    result = await db.execute(stmt)
    return result.scalars().all()


@router.put("/{match_id}/accept", response_model=MatchRead)
async def accept_match(
    match_id: UUID,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    El donante acepta un match pendiente.
    Esto habilita el chat entre las partes (se crea en la Etapa 2).
    """
    stmt = select(Match).where(Match.id == match_id)
    result = await db.execute(stmt)
    match = result.scalar_one_or_none()

    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found",
        )

    if match.donor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the pet donor can accept this match.",
        )

    if match.status != MatchStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot accept a match with status '{match.status.value}'.",
        )

    from datetime import datetime, timezone
    match.status = MatchStatus.ACCEPTED
    match.matched_at = datetime.now(timezone.utc)

    # Actualizar estado de la mascota a 'matched'
    pet_stmt = select(Pet).where(Pet.id == match.pet_id)
    pet_result = await db.execute(pet_stmt)
    pet = pet_result.scalar_one()
    pet.status = PetStatus.MATCHED

    await db.commit()
    await db.refresh(match)

    # Fetch adopter to get FCM token
    adopter_stmt = select(User).where(User.id == match.adopter_id)
    adopter_result = await db.execute(adopter_stmt)
    adopter = adopter_result.scalar_one_or_none()

    if adopter and adopter.fcm_token:
        background_tasks.add_task(
            notify_match_accepted,
            fcm_token=adopter.fcm_token,
            pet_name=pet.name
        )

    return match


@router.put("/{match_id}/reject", response_model=MatchRead)
async def reject_match(
    match_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    El donante rechaza un match pendiente.
    """
    stmt = select(Match).where(Match.id == match_id)
    result = await db.execute(stmt)
    match = result.scalar_one_or_none()

    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found",
        )

    if match.donor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the pet donor can reject this match.",
        )

    if match.status != MatchStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot reject a match with status '{match.status.value}'.",
        )

    match.status = MatchStatus.REJECTED

    await db.commit()
    await db.refresh(match)

    return match


@router.post("/{match_id}/evidence", response_model=PostAdoptionEvidenceRead, status_code=status.HTTP_201_CREATED)
async def submit_evidence(
    match_id: UUID,
    evidence_in: PostAdoptionEvidenceCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Sube evidencia fotográfica post-adopción.
    Solo el adoptante puede subir evidencia para el match.
    El match pasa a estado COMPLETED la primera vez que se sube evidencia (si no lo estaba ya).
    """
    stmt = select(Match).where(Match.id == match_id)
    result = await db.execute(stmt)
    match = result.scalar_one_or_none()

    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Match not found"
        )
        
    if match.adopter_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Only the adopter can submit evidence."
        )
        
    if match.status not in [MatchStatus.ACCEPTED, MatchStatus.COMPLETED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Can only submit evidence for accepted or completed matches."
        )

    db_evidence = PostAdoptionEvidence(
        match_id=match_id,
        adopter_id=current_user.id,
        photo_url=evidence_in.photo_url,
        cloudinary_public_id=evidence_in.cloudinary_public_id,
        status_note=evidence_in.status_note,
    )
    db.add(db_evidence)
    
    # Auto-complete match on first evidence
    if match.status == MatchStatus.ACCEPTED:
        from datetime import datetime, timezone
        match.status = MatchStatus.COMPLETED
        match.completed_at = datetime.now(timezone.utc)
        
        # Update pet status
        pet_stmt = select(Pet).where(Pet.id == match.pet_id)
        pet_result = await db.execute(pet_stmt)
        pet = pet_result.scalar_one()
        pet.status = PetStatus.ADOPTED
        
    await db.commit()
    await db.refresh(db_evidence)
    
    return db_evidence
