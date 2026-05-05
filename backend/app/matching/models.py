"""
PAW — Modelos de Match y Evidencia Post-Adopción.
Conecta adoptante con mascota/donante y gestiona el seguimiento.
"""

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    DateTime,
    Enum,
    Float,
    ForeignKey,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

# ─── Enums ───────────────────────────────────────────────


class MatchStatus(str, enum.Enum):
    """Ciclo de vida de un match según el doc del proyecto."""

    PENDING = "pending"  # Adoptante expresó interés
    ACCEPTED = "accepted"  # Donante aceptó → se habilita chat
    REJECTED = "rejected"  # Donante rechazó
    COMPLETED = "completed"  # Adopción confirmada por ambas partes
    CANCELLED = "cancelled"  # Cancelado por cualquiera de las partes


# ─── Modelo: Match ──────────────────────────────────────


class Match(Base):
    """
    Conexión entre un adoptante y una mascota/donante.
    Se crea cuando el adoptante expresa interés (status=pending).
    Se activa cuando el donante acepta (status=accepted → habilita chat).
    """

    __tablename__ = "matches"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    pet_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("pets.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    adopter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    donor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    status: Mapped[MatchStatus] = mapped_column(
        Enum(MatchStatus), nullable=False, default=MatchStatus.PENDING
    )

    # Score de compatibilidad calculado por el algoritmo de matching
    # Score = 40% compatibilidad + 25% reputación + 20% proximidad + 15% afinidad
    compatibility_score: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Mensaje opcional del adoptante al expresar interés
    adopter_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Respuesta del donante al aceptar/rechazar
    donor_response: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Timestamps del ciclo de vida
    matched_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True  # Cuando el donante acepta
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True  # Cuando se confirma la adopción
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    pet: Mapped["Pet"] = relationship("Pet", backref="matches")  # noqa: F821
    adopter: Mapped["User"] = relationship(  # noqa: F821
        "User", foreign_keys=[adopter_id], backref="matches_as_adopter"
    )
    donor: Mapped["User"] = relationship(  # noqa: F821
        "User", foreign_keys=[donor_id], backref="matches_as_donor"
    )
    evidence: Mapped[list["PostAdoptionEvidence"]] = relationship(
        back_populates="match", cascade="all, delete-orphan"
    )

    @property
    def pet_name(self) -> str | None:
        try:
            return self.pet.name if self.pet else None
        except Exception:
            return None

    @property
    def adopter_name(self) -> str | None:
        try:
            return self.adopter.full_name if self.adopter else None
        except Exception:
            return None

    @property
    def donor_name(self) -> str | None:
        try:
            return self.donor.full_name if self.donor else None
        except Exception:
            return None

    def __repr__(self) -> str:
        return (
            f"<Match adopter={self.adopter_id} pet={self.pet_id} ({self.status.value})>"
        )


# ─── Modelo: Evidencia Post-Adopción ─────────────────────


class PostAdoptionEvidence(Base):
    """
    Seguimiento post-adopción: foto + estado del animal.
    Según el doc: notificación a las 48-72h, si no sube en 7 días
    se marca para seguimiento manual.
    """

    __tablename__ = "post_adoption_evidence"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    match_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("matches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    adopter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    photo_url: Mapped[str] = mapped_column(String(500), nullable=False)
    cloudinary_public_id: Mapped[str] = mapped_column(String(255), nullable=False)
    status_note: Mapped[str] = mapped_column(Text, nullable=False)

    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    notification_sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    donor_viewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # ─── Relaciones ──────────────────────────────────────
    match: Mapped["Match"] = relationship(back_populates="evidence")
    adopter: Mapped["User"] = relationship(  # noqa: F821
        "User", backref="evidence_submitted"
    )

    def __repr__(self) -> str:
        return f"<PostAdoptionEvidence match={self.match_id}>"
