from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.matching.models import MatchStatus

class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

# ─── Evidencia Post-Adopción ─────────────────────────────

class PostAdoptionEvidenceBase(BaseSchema):
    photo_url: str = Field(..., max_length=500)
    cloudinary_public_id: str = Field(..., max_length=255)
    status_note: str

class PostAdoptionEvidenceCreate(PostAdoptionEvidenceBase):
    match_id: UUID

class PostAdoptionEvidenceRead(PostAdoptionEvidenceBase):
    id: UUID
    match_id: UUID
    adopter_id: UUID
    submitted_at: datetime
    notification_sent_at: Optional[datetime]
    donor_viewed_at: Optional[datetime]

# ─── Match ───────────────────────────────────────────────

class MatchBase(BaseSchema):
    adopter_message: Optional[str] = None

class MatchCreate(MatchBase):
    pet_id: UUID

class MatchRead(MatchBase):
    id: UUID
    pet_id: UUID
    adopter_id: UUID
    donor_id: UUID
    status: MatchStatus
    compatibility_score: Optional[float]
    donor_response: Optional[str]
    matched_at: Optional[datetime]
    completed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
