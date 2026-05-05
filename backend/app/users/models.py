"""
PAW — Modelos de Usuario, Perfil Adoptante y Perfil Donante.
Tabla users soporta roles múltiples (un usuario puede ser adoptante Y donante).
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

class UserRole(str, enum.Enum):
    """Rol principal del usuario en la plataforma."""
    ADOPTER = "adopter"
    DONOR = "donor"
    BOTH = "both"
    MODERATOR = "moderator"
    ADMIN = "admin"


class HousingType(str, enum.Enum):
    """Tipo de vivienda del adoptante."""
    HOUSE = "house"
    APARTMENT = "apartment"
    RURAL = "rural"


class YardSize(str, enum.Enum):
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"


class ExperienceLevel(str, enum.Enum):
    """Experiencia previa del adoptante con mascotas."""
    FIRST_TIME = "first_time"
    SOME = "some"
    EXPERIENCED = "experienced"


class PreferredSpecies(str, enum.Enum):
    DOG = "dog"
    CAT = "cat"
    BOTH = "both"


class PreferredSize(str, enum.Enum):
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"
    ANY = "any"


class EnergyLevel(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    ANY = "any"


class VerificationLevel(int, enum.Enum):
    """Niveles de verificación del documento del proyecto."""
    NONE = 0        # Sin verificación
    BASIC = 1       # Email o teléfono verificado
    IDENTITY = 2    # Documento de identidad verificado
    PREMIUM = 3     # Videollamada (fase 2, fuera del MVP)


# ─── Modelo: Usuario ────────────────────────────────────

class User(Base):
    """
    Usuario base de la plataforma.
    Puede tener rol de adoptante, donante, ambos, moderador o admin.
    """
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, nullable=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole), nullable=False, default=UserRole.ADOPTER
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified_email: Mapped[bool] = mapped_column(Boolean, default=False)
    is_verified_phone: Mapped[bool] = mapped_column(Boolean, default=False)
    email_verification_token: Mapped[str | None] = mapped_column(
        String(8), nullable=True
    )
    verification_level: Mapped[int] = mapped_column(
        Integer, default=VerificationLevel.NONE
    )

    # Reputación (promedio de estrellas y cantidad de valoraciones)
    reputation_score: Mapped[float] = mapped_column(Float, default=0.0)
    reputation_count: Mapped[int] = mapped_column(Integer, default=0)

    # Ubicación aproximada (para cálculo de proximidad en matching)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    city: Mapped[str | None] = mapped_column(String(100), nullable=True)
    province: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # Firebase Cloud Messaging token (para notificaciones push)
    fcm_token: Mapped[str | None] = mapped_column(String(255), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    adopter_profile: Mapped["AdopterProfile"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    donor_profile: Mapped["DonorProfile"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<User {self.email} ({self.role.value})>"


# ─── Modelo: Perfil Adoptante ────────────────────────────

class AdopterProfile(Base):
    """
    Perfil del adoptante: información que demuestra aptitud para adoptar.
    Visible al donante tras match/consentimiento (según doc del proyecto).
    """
    __tablename__ = "adopter_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    # ─── Vivienda ─────────────────────────────────────
    housing_type: Mapped[HousingType | None] = mapped_column(
        Enum(HousingType), nullable=True
    )
    has_yard: Mapped[bool] = mapped_column(Boolean, default=False)
    yard_size: Mapped[YardSize | None] = mapped_column(
        Enum(YardSize), nullable=True
    )

    # ─── Convivencia ──────────────────────────────────
    has_other_pets: Mapped[bool] = mapped_column(Boolean, default=False)
    other_pets_details: Mapped[str | None] = mapped_column(Text, nullable=True)
    has_children: Mapped[bool] = mapped_column(Boolean, default=False)
    children_ages: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # ─── Disponibilidad y experiencia ─────────────────
    daily_hours_alone: Mapped[int | None] = mapped_column(
        Integer, nullable=True  # Horas que la mascota estaría sola por día
    )
    experience_level: Mapped[ExperienceLevel | None] = mapped_column(
        Enum(ExperienceLevel), nullable=True
    )

    # ─── Preferencias de mascota ──────────────────────
    preferred_species: Mapped[PreferredSpecies | None] = mapped_column(
        Enum(PreferredSpecies), nullable=True, default=PreferredSpecies.BOTH
    )
    preferred_size: Mapped[PreferredSize | None] = mapped_column(
        Enum(PreferredSize), nullable=True, default=PreferredSize.ANY
    )
    preferred_age_min: Mapped[int | None] = mapped_column(
        Integer, nullable=True  # Edad mínima en meses
    )
    preferred_age_max: Mapped[int | None] = mapped_column(
        Integer, nullable=True  # Edad máxima en meses
    )
    preferred_energy_level: Mapped[EnergyLevel | None] = mapped_column(
        Enum(EnergyLevel), nullable=True, default=EnergyLevel.ANY
    )
    max_distance_km: Mapped[int] = mapped_column(Integer, default=50)

    additional_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    user: Mapped["User"] = relationship(back_populates="adopter_profile")

    def __repr__(self) -> str:
        return f"<AdopterProfile user_id={self.user_id}>"


# ─── Modelo: Perfil Donante ──────────────────────────────

class DonorProfile(Base):
    """
    Perfil del donante: persona u organización que entrega mascotas.
    Visible a adoptantes según el documento del proyecto.
    """
    __tablename__ = "donor_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    is_organization: Mapped[bool] = mapped_column(Boolean, default=False)
    organization_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
    total_pets_donated: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # ─── Relaciones ──────────────────────────────────────
    user: Mapped["User"] = relationship(back_populates="donor_profile")

    def __repr__(self) -> str:
        return f"<DonorProfile user_id={self.user_id} org={self.is_organization}>"
