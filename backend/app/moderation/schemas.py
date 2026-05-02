from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.moderation.models import ReportReason, ReportStatus

class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

# ─── Reporte ─────────────────────────────────────────────

class ReportBase(BaseSchema):
    reported_user_id: Optional[UUID] = None
    reported_pet_id: Optional[UUID] = None
    reason: ReportReason
    description: str

class ReportCreate(ReportBase):
    pass

class ReportRead(ReportBase):
    id: UUID
    reporter_id: UUID
    status: ReportStatus
    moderator_id: Optional[UUID]
    resolution_notes: Optional[str]
    created_at: datetime
    resolved_at: Optional[datetime]


class ReportUpdate(BaseSchema):
    status: ReportStatus
    resolution_notes: Optional[str] = None

# ─── Review / Valoración ─────────────────────────────────

class ReviewBase(BaseSchema):
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class ReviewCreate(ReviewBase):
    match_id: UUID
    reviewed_id: UUID

class ReviewRead(ReviewBase):
    id: UUID
    match_id: UUID
    reviewer_id: UUID
    reviewed_id: UUID
    created_at: datetime
