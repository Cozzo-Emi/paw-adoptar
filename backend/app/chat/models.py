"""
PAW — Modelos de Chat y Mensajes.
Chat P2P habilitado únicamente post-match (según doc del proyecto).
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


# ─── Modelo: Chat ────────────────────────────────────────

class Chat(Base):
    """
    Sala de chat entre adoptante y donante.
    Se crea automáticamente cuando un match es aceptado.
    Relación 1:1 con Match.
    """
    __tablename__ = "chats"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        unique=True,  # Un chat por match
        nullable=False,
    )
    adopter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    donor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    match: Mapped["Match"] = relationship("Match", backref="chat")  # noqa: F821
    messages: Mapped[list["Message"]] = relationship(
        back_populates="chat", cascade="all, delete-orphan",
        order_by="Message.created_at",
    )

    def __repr__(self) -> str:
        return f"<Chat match={self.match_id} active={self.is_active}>"


# ─── Modelo: Mensaje ─────────────────────────────────────

class Message(Base):
    """
    Mensaje individual dentro de un chat.
    Solo usuarios del match pueden enviar mensajes.
    """
    __tablename__ = "messages"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    chat_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("chats.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    sender_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    content: Mapped[str] = mapped_column(Text, nullable=False)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    chat: Mapped["Chat"] = relationship(back_populates="messages")
    sender: Mapped["User"] = relationship("User", backref="messages_sent")  # noqa: F821

    def __repr__(self) -> str:
        return f"<Message chat={self.chat_id} sender={self.sender_id}>"
