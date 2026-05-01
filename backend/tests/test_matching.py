import pytest
from app.core.matching import calculate_compatibility, _haversine


class TestHaversine:
    def test_same_point(self):
        assert _haversine(0, 0, 0, 0) == 0.0

    def test_buenos_aires_to_cordoba(self):
        distance = _haversine(-34.6037, -58.3816, -31.4201, -64.1888)
        assert 600 < distance < 700

    def test_large_distance(self):
        distance = _haversine(0, 0, 89.9, 0)
        assert distance > 9000


def make_pet(**kwargs):
    class FakePet:
        pass
    pet = FakePet()

    class FakeSpecies:
        value = kwargs.get("species", "dog")

    class FakeSize:
        value = kwargs.get("size", "medium")

    class FakeEnergy:
        value = kwargs.get("energy", "medium")

    pet.species = FakeSpecies()
    pet.size = FakeSize()
    pet.energy_level = FakeEnergy()
    pet.requires_yard = kwargs.get("requires_yard", False)
    pet.requires_experience = kwargs.get("requires_experience", False)
    pet.latitude = kwargs.get("latitude")
    pet.longitude = kwargs.get("longitude")
    pet.city = kwargs.get("city")
    pet.province = kwargs.get("province")
    return pet


def make_user(**kwargs):
    class FakeUser:
        pass
    user = FakeUser()
    user.reputation_score = kwargs.get("reputation_score", 0.0)
    user.latitude = kwargs.get("latitude")
    user.longitude = kwargs.get("longitude")
    user.city = kwargs.get("city")
    user.province = kwargs.get("province")
    return user


def make_adopter_profile(**kwargs):
    class FakeProfile:
        pass
    profile = FakeProfile()

    class FakeSpecies:
        value = kwargs.get("preferred_species", "both")

    class FakeSize:
        value = kwargs.get("preferred_size", "any")

    class FakeEnergy:
        value = kwargs.get("preferred_energy", "any")

    class FakeExperience:
        value = kwargs.get("experience_level", "first_time")

    profile.preferred_species = FakeSpecies()
    profile.preferred_size = FakeSize()
    profile.preferred_energy_level = FakeEnergy()
    profile.experience_level = FakeExperience()
    profile.has_yard = kwargs.get("has_yard", False)
    profile.max_distance_km = kwargs.get("max_distance_km", 50)
    return profile


class TestCompatibility:
    def test_no_profile_returns_low_score(self):
        user = make_user()
        pet = make_pet()
        donor = make_user()
        score = calculate_compatibility(None, user, pet, donor)
        assert 0.2 < score < 0.6

    def test_hard_filter_cat_vs_dog_preference(self):
        user = make_user()
        pet = make_pet(species="dog")
        donor = make_user()
        profile = make_adopter_profile(preferred_species="cat")
        score = calculate_compatibility(profile, user, pet, donor)
        assert score == 0.0

    def test_requirements_match(self):
        user = make_user()
        pet = make_pet(requires_yard=True, requires_experience=True)
        donor = make_user()
        profile = make_adopter_profile(has_yard=True, experience_level="experienced")
        score = calculate_compatibility(profile, user, pet, donor)
        assert score > 0.5

    def test_reputation_boosts_score(self):
        pet = make_pet()
        donor = make_user()

        low_rep_user = make_user(reputation_score=0.0)
        profile = make_adopter_profile()
        low_score = calculate_compatibility(profile, low_rep_user, pet, donor)

        high_rep_user = make_user(reputation_score=5.0)
        high_score = calculate_compatibility(profile, high_rep_user, pet, donor)

        assert high_score > low_score

    def test_proximity_same_city(self):
        user = make_user(city="Buenos Aires")
        pet = make_pet(city="Buenos Aires")
        donor = make_user()
        score = calculate_compatibility(None, user, pet, donor)
        assert score > 0.5

    def test_score_is_between_0_and_1(self):
        user = make_user()
        pet = make_pet()
        donor = make_user()
        profile = make_adopter_profile()

        score = calculate_compatibility(profile, user, pet, donor)
        assert 0.0 <= score <= 1.0
