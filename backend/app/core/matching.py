"""
PAW — Algoritmo de Matching
Calcula el score de compatibilidad entre un adoptante y una mascota.
Score = 40% compatibilidad + 25% reputación + 20% proximidad + 15% afinidad
"""

import math
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.pets.models import Pet
    from app.users.models import AdopterProfile, User


def calculate_compatibility(
    adopter_profile: "AdopterProfile | None",
    adopter_user: "User",
    pet: "Pet",
    donor_user: "User",
) -> float:
    """
    Calcula el score de compatibilidad (0.0 a 1.0).
    Si el adoptante no tiene perfil, usa valores por defecto.
    Retorna None si los filtros duros no se cumplen.
    """
    if not _passes_hard_filters(adopter_profile, pet):
        return 0.0

    compatibility = _calc_requirements_match(adopter_profile, pet) * 0.40
    reputation = _calc_reputation(adopter_user) * 0.25
    proximity = _calc_proximity(adopter_profile, adopter_user, pet) * 0.20
    affinity = _calc_affinity(adopter_profile, pet) * 0.15

    return round(compatibility + reputation + proximity + affinity, 4)


def _passes_hard_filters(adopter_profile: "AdopterProfile | None", pet: "Pet") -> bool:
    if adopter_profile is None:
        return True
    if (
        adopter_profile.preferred_species
        and adopter_profile.preferred_species.value == "dog"
        and pet.species.value == "cat"
    ):
        return False
    if (
        adopter_profile.preferred_species
        and adopter_profile.preferred_species.value == "cat"
        and pet.species.value == "dog"
    ):
        return False
    return True


def _calc_requirements_match(
    adopter_profile: "AdopterProfile | None", pet: "Pet"
) -> float:
    if adopter_profile is None:
        return 0.3

    checks = 0
    passed = 0

    if pet.requires_yard:
        checks += 1
        if adopter_profile.has_yard:
            passed += 1

    if pet.requires_experience:
        checks += 1
        if (
            adopter_profile.experience_level
            and adopter_profile.experience_level.value in ("some", "experienced")
        ):
            passed += 1

    if checks == 0:
        return 0.5

    return passed / checks


def _calc_reputation(adopter_user: "User") -> float:
    if adopter_user.reputation_score == 0:
        return 0.5
    return min(adopter_user.reputation_score / 5.0, 1.0)


def _calc_proximity(
    adopter_profile: "AdopterProfile | None",
    adopter_user: "User",
    pet: "Pet",
) -> float:
    max_km = adopter_profile.max_distance_km if adopter_profile else 50

    # If coordinates available, calculate haversine distance
    if (
        adopter_user.latitude is not None
        and adopter_user.longitude is not None
        and pet.latitude is not None
        and pet.longitude is not None
    ):
        distance_km = _haversine(
            adopter_user.latitude,
            adopter_user.longitude,
            pet.latitude,
            pet.longitude,
        )
        if distance_km > max_km:
            return 0.0
        return 1.0 - min(distance_km / max_km, 1.0)

    # Fallback: city/province match
    if adopter_user.city and pet.city:
        if adopter_user.city.lower() == pet.city.lower():
            return 1.0
        if (
            adopter_user.province
            and pet.province
            and adopter_user.province.lower() == pet.province.lower()
        ):
            return 0.6

    return 0.3


def _calc_affinity(adopter_profile: "AdopterProfile | None", pet: "Pet") -> float:
    if adopter_profile is None:
        return 0.5

    checks = 0
    passed = 0

    if adopter_profile.preferred_size and adopter_profile.preferred_size.value != "any":
        checks += 1
        if pet.size.value == adopter_profile.preferred_size.value:
            passed += 1

    if (
        adopter_profile.preferred_energy_level
        and adopter_profile.preferred_energy_level.value != "any"
    ):
        checks += 1
        if pet.energy_level.value == adopter_profile.preferred_energy_level.value:
            passed += 1

    if checks == 0:
        return 0.5

    return passed / checks


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c
