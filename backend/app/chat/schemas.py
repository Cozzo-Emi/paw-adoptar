from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

# ─── Mensaje ─────────────────────────────────────────────

class MessageBase(BaseSchema):
    content: str

class MessageCreate(MessageBase):
    pass

class MessageRead(MessageBase):
    id: UUID
    chat_id: UUID
    sender_id: UUID
    is_read: bool
    created_at: datetime

# ─── Chat ────────────────────────────────────────────────

class ChatRead(BaseSchema):
    id: UUID
    match_id: UUID
    adopter_id: UUID
    donor_id: UUID
    is_active: bool
    created_at: datetime
