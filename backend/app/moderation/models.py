"""
PAW — Modelos de Moderación: Reportes y Reviews.
Sistema de reportes visible para todos los usuarios con revisión humana.
"""

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


# ─── Enums ───────────────────────────────────────────────

class ReportReason(str, enum.Enum):
    """Motivos de reporte disponibles para los usuarios."""
    FRAUD = "fraud"
    ABUSE = "abuse"
    FAKE_LISTING = "fake_listing"
    INAPPROPRIATE = "inappropriate"
    OTHER = "other"


class ReportStatus(str, enum.Enum):
    """Estado del reporte en la cola de moderación."""
    PENDING = "pending"       # Recién creado
    REVIEWING = "reviewing"   # Un moderador lo está revisando
    RESOLVED = "resolved"     # Resuelto (acción tomada)
    DISMISSED = "dismissed"   # Descartado (sin mérito)


# ─── Modelo: Reporte ─────────────────────────────────────

class Report(Base):
    """
    Reporte de abuso o fraude generado por un usuario.
    Revisión humana por moderadores según doc del proyecto.
    """
    __tablename__ = "reports"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    reporter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Se puede reportar un usuario O una publicación de mascota
    reported_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    reported_pet_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("pets.id", ondelete="SET NULL"),
        nullable=True,
    )

    reason: Mapped[ReportReason] = mapped_column(
        Enum(ReportReason), nullable=False
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)

    status: Mapped[ReportStatus] = mapped_column(
        Enum(ReportStatus), nullable=False, default=ReportStatus.PENDING
    )

    # Moderador asignado (si está en revisión)
    moderator_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    resolution_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # ─── Relaciones ──────────────────────────────────────
    reporter: Mapped["User"] = relationship(  # noqa: F821
        "User", foreign_keys=[reporter_id], backref="reports_filed"
    )
    reported_user: Mapped["User"] = relationship(  # noqa: F821
        "User", foreign_keys=[reported_user_id], backref="reports_received"
    )
    moderator: Mapped["User"] = relationship(  # noqa: F821
        "User", foreign_keys=[moderator_id], backref="reports_moderated"
    )

    def __repr__(self) -> str:
        return f"<Report {self.reason.value} - {self.status.value}>"


# ─── Modelo: Review / Valoración ─────────────────────────

class Review(Base):
    """
    Valoración (1-5 estrellas) + comentario tras una adopción completada.
    Según doc: las estrellas y comentarios son visibles en el perfil.
    Incrementan o afectan la reputación del usuario.
    """
    __tablename__ = "reviews"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
    )

    # Quien deja la review y quien la recibe
    reviewer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    reviewed_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    rating: Mapped[int] = mapped_column(
        Integer, nullable=False  # 1-5 estrellas (validar en Pydantic)
    )
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    match: Mapped["Match"] = relationship("Match", backref="reviews")  # noqa: F821
    reviewer: Mapped["User"] = relationship(  # noqa: F821
        "User", foreign_keys=[reviewer_id], backref="reviews_given"
    )
    reviewed: Mapped["User"] = relationship(  # noqa: F821
        "User", foreign_keys=[reviewed_id], backref="reviews_received"
    )

    def __repr__(self) -> str:
        return f"<Review {self.rating}★ from={self.reviewer_id} to={self.reviewed_id}>"
