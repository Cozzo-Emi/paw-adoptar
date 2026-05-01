"""
PAW — Users Router
Endpoints para gestión de usuarios y sus perfiles (adoptante / donante).
"""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.auth.dependencies import get_current_user
from app.database import get_db
from app.users.models import AdopterProfile, DonorProfile, User
from app.users.schemas import (
    AdopterProfileCreate,
    AdopterProfileRead,
    DonorProfileCreate,
    DonorProfileRead,
    FCMTokenUpdate,
    UserRead,
)

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserRead)
async def get_my_user(current_user: User = Depends(get_current_user)):
    """
    Devuelve los datos del usuario actualmente logueado.
    """
    return current_user


@router.post("/me/adopter-profile", response_model=AdopterProfileRead)
async def upsert_adopter_profile(
    profile_in: AdopterProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Crea o actualiza el perfil de adoptante del usuario actual.
    """
    stmt = select(AdopterProfile).where(AdopterProfile.user_id == current_user.id)
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()

    if profile:
        # Update existing profile
        for key, value in profile_in.model_dump(exclude_unset=True).items():
            setattr(profile, key, value)
    else:
        # Create new profile
        profile = AdopterProfile(user_id=current_user.id, **profile_in.model_dump())
        db.add(profile)

    await db.commit()
    await db.refresh(profile)
    return profile


@router.post("/me/donor-profile", response_model=DonorProfileRead)
async def upsert_donor_profile(
    profile_in: DonorProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Crea o actualiza el perfil de donante del usuario actual.
    """
    stmt = select(DonorProfile).where(DonorProfile.user_id == current_user.id)
    result = await db.execute(stmt)
    profile = result.scalar_one_or_none()

    if profile:
        # Update existing profile
        for key, value in profile_in.model_dump(exclude_unset=True).items():
            setattr(profile, key, value)
    else:
        # Create new profile
        profile = DonorProfile(user_id=current_user.id, **profile_in.model_dump())
        db.add(profile)

    await db.commit()
    await db.refresh(profile)
    return profile


@router.get("/{user_id}", response_model=UserRead)
async def get_user_by_id(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    # Solo usuarios logueados pueden ver perfiles
    current_user: User = Depends(get_current_user), 
):
    """
    Devuelve el perfil público de otro usuario.
    TODO: Filtrar campos privados en un schema público dedicado.
    """
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return user

@router.post("/me/fcm-token", response_model=dict)
async def update_fcm_token(
    fcm_data: FCMTokenUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Actualiza el token de Firebase Cloud Messaging del dispositivo del usuario
    para poder enviarle notificaciones push.
    """
    current_user.fcm_token = fcm_data.token
    db.add(current_user)
    await db.commit()
    
    return {"status": "success", "detail": "FCM token updated"}
