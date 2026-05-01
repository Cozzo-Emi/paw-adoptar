from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.users.models import (
    EnergyLevel,
    ExperienceLevel,
    HousingType,
    PreferredSize,
    PreferredSpecies,
    UserRole,
    VerificationLevel,
    YardSize,
)

# ─── Schemas Base ────────────────────────────────────────

class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

# ─── Usuario ──────────────────────────────────────────────

class UserBase(BaseSchema):
    email: EmailStr
    full_name: str = Field(..., max_length=150)
    phone: Optional[str] = Field(None, max_length=20)
    avatar_url: Optional[str] = Field(None, max_length=500)
    role: UserRole = UserRole.ADOPTER
    city: Optional[str] = Field(None, max_length=100)
    province: Optional[str] = Field(None, max_length=100)

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserRead(UserBase):
    id: UUID
    is_active: bool
    is_verified_email: bool
    is_verified_phone: bool
    verification_level: VerificationLevel
    reputation_score: float
    reputation_count: int
    fcm_token: Optional[str] = None
    created_at: datetime

class FCMTokenUpdate(BaseSchema):
    token: str = Field(..., max_length=255)

# ─── Perfil Adoptante ────────────────────────────────────

class AdopterProfileBase(BaseSchema):
    housing_type: Optional[HousingType] = None
    has_yard: bool = False
    yard_size: Optional[YardSize] = None
    
    has_other_pets: bool = False
    other_pets_details: Optional[str] = None
    has_children: bool = False
    children_ages: Optional[str] = Field(None, max_length=100)
    
    daily_hours_alone: Optional[int] = Field(None, ge=0, le=24)
    experience_level: Optional[ExperienceLevel] = None
    
    preferred_species: Optional[PreferredSpecies] = PreferredSpecies.BOTH
    preferred_size: Optional[PreferredSize] = PreferredSize.ANY
    preferred_age_min: Optional[int] = Field(None, ge=0)
    preferred_age_max: Optional[int] = Field(None, ge=0)
    preferred_energy_level: Optional[EnergyLevel] = EnergyLevel.ANY
    max_distance_km: int = Field(50, ge=1, le=1000)
    
    additional_notes: Optional[str] = None

class AdopterProfileCreate(AdopterProfileBase):
    pass

class AdopterProfileRead(AdopterProfileBase):
    id: UUID
    user_id: UUID
    created_at: datetime
    updated_at: datetime

# ─── Perfil Donante ──────────────────────────────────────

class DonorProfileBase(BaseSchema):
    is_organization: bool = False
    organization_name: Optional[str] = Field(None, max_length=200)
    bio: Optional[str] = None

class DonorProfileCreate(DonorProfileBase):
    pass

class DonorProfileRead(DonorProfileBase):
    id: UUID
    user_id: UUID
    total_pets_donated: int
    created_at: datetime
    updated_at: datetime
