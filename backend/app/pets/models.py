"""
PAW — Modelos de Mascota y Fotos de Mascota.
Ficha completa del animal con campos estructurados según el documento del proyecto.
"""

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    Float,
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


class Species(str, enum.Enum):
    DOG = "dog"
    CAT = "cat"


class Sex(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"


class PetSize(str, enum.Enum):
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"


class PetEnergyLevel(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class PetStatus(str, enum.Enum):
    """Estado de la publicación de la mascota."""

    AVAILABLE = "available"  # Visible en búsquedas
    MATCHED = "matched"  # Tiene un match activo
    ADOPTED = "adopted"  # Adopción confirmada
    REMOVED = "removed"  # Removida por donante o moderador


# ─── Modelo: Mascota ────────────────────────────────────


class Pet(Base):
    """
    Ficha de mascota publicada por un donante.
    Campos obligatorios según doc: fotos (mín 2), especie, raza, edad,
    sexo, salud, vacunas, comportamiento.
    """

    __tablename__ = "pets"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    donor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # ─── Datos básicos ────────────────────────────────
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    species: Mapped[Species] = mapped_column(Enum(Species), nullable=False)
    breed: Mapped[str | None] = mapped_column(String(100), nullable=True)
    age_months: Mapped[int] = mapped_column(Integer, nullable=False)
    sex: Mapped[Sex] = mapped_column(Enum(Sex), nullable=False)
    size: Mapped[PetSize] = mapped_column(Enum(PetSize), nullable=False)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    color: Mapped[str | None] = mapped_column(String(50), nullable=True)

    # ─── Salud y vacunas ──────────────────────────────
    is_neutered: Mapped[bool] = mapped_column(Boolean, default=False)
    is_vaccinated: Mapped[bool] = mapped_column(Boolean, default=False)
    vaccination_details: Mapped[str | None] = mapped_column(Text, nullable=True)
    health_status: Mapped[str | None] = mapped_column(Text, nullable=True)

    # ─── Comportamiento ──────────────────────────────
    energy_level: Mapped[PetEnergyLevel] = mapped_column(
        Enum(PetEnergyLevel), nullable=False, default=PetEnergyLevel.MEDIUM
    )
    good_with_kids: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    good_with_pets: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)

    # ─── Requisitos del donante ───────────────────────
    # Lo que el donante exige del adoptante (filtros duros del matching)
    requirements: Mapped[str | None] = mapped_column(Text, nullable=True)
    requires_yard: Mapped[bool] = mapped_column(Boolean, default=False)
    requires_experience: Mapped[bool] = mapped_column(Boolean, default=False)

    # ─── Estado de la publicación ─────────────────────
    status: Mapped[PetStatus] = mapped_column(
        Enum(PetStatus), nullable=False, default=PetStatus.AVAILABLE
    )

    # ─── Ubicación (hereda del donante o se pone explícita) ──
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    city: Mapped[str | None] = mapped_column(String(100), nullable=True)
    province: Mapped[str | None] = mapped_column(String(100), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    donor: Mapped["User"] = relationship("User", backref="pets")  # noqa: F821
    photos: Mapped[list["PetPhoto"]] = relationship(
        back_populates="pet",
        cascade="all, delete-orphan",
        order_by="PetPhoto.order",
    )

    def __repr__(self) -> str:
        return f"<Pet {self.name} ({self.species.value}) - {self.status.value}>"


# ─── Modelo: Fotos de Mascota ────────────────────────────


class PetPhoto(Base):
    """
    Foto de una mascota almacenada en Cloudinary.
    El doc del proyecto exige mínimo 2 fotos por ficha.
    """

    __tablename__ = "pet_photos"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    pet_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("pets.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    cloudinary_url: Mapped[str] = mapped_column(String(500), nullable=False)
    cloudinary_public_id: Mapped[str] = mapped_column(String(255), nullable=False)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)
    order: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    pet: Mapped["Pet"] = relationship(back_populates="photos")

    def __repr__(self) -> str:
        return f"<PetPhoto pet_id={self.pet_id} primary={self.is_primary}>"
