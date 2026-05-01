from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.pets.models import PetEnergyLevel, PetSize, PetStatus, Sex, Species

class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

# ─── Fotos de Mascota ────────────────────────────────────

class PetPhotoBase(BaseSchema):
    cloudinary_url: str = Field(..., max_length=500)
    cloudinary_public_id: str = Field(..., max_length=255)
    is_primary: bool = False
    order: int = 0

class PetPhotoCreate(PetPhotoBase):
    pass

class PetPhotoRead(PetPhotoBase):
    id: UUID
    pet_id: UUID
    created_at: datetime

# ─── Mascota ─────────────────────────────────────────────

class PetBase(BaseSchema):
    name: str = Field(..., max_length=100)
    species: Species
    breed: Optional[str] = Field(None, max_length=100)
    age_months: int = Field(..., ge=0)
    sex: Sex
    size: PetSize
    weight_kg: Optional[float] = Field(None, gt=0)
    color: Optional[str] = Field(None, max_length=50)

    is_neutered: bool = False
    is_vaccinated: bool = False
    vaccination_details: Optional[str] = None
    health_status: Optional[str] = None

    energy_level: PetEnergyLevel = PetEnergyLevel.MEDIUM
    good_with_kids: Optional[bool] = None
    good_with_pets: Optional[bool] = None
    description: str

    requirements: Optional[str] = None
    requires_yard: bool = False
    requires_experience: bool = False

    city: Optional[str] = Field(None, max_length=100)
    province: Optional[str] = Field(None, max_length=100)

class PetCreate(PetBase):
    photos: List[PetPhotoCreate] = Field(..., min_length=2, description="Al menos 2 fotos requeridas")

class PetRead(PetBase):
    id: UUID
    donor_id: UUID
    status: PetStatus
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    photos: List[PetPhotoRead]
