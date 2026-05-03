import 'package:flutter_test/flutter_test.dart';
import 'package:paw/models/pet.dart';
import 'package:paw/models/user.dart';
import 'package:paw/models/match.dart';
import 'package:paw/models/chat.dart';

void main() {
  group('Pet model', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': '123',
        'donor_id': '456',
        'name': 'Firulais',
        'species': 'dog',
        'breed': 'Labrador',
        'age_months': 24,
        'sex': 'male',
        'size': 'large',
        'weight_kg': 30.5,
        'color': 'Negro',
        'is_neutered': true,
        'is_vaccinated': true,
        'vaccination_details': 'Al día',
        'health_status': 'Sano',
        'energy_level': 'high',
        'good_with_kids': true,
        'good_with_pets': false,
        'description': 'Perro muy bueno',
        'requirements': 'Necesita patio',
        'requires_yard': true,
        'requires_experience': false,
        'status': 'available',
        'latitude': -34.6,
        'longitude': -58.4,
        'city': 'Buenos Aires',
        'province': 'CABA',
        'created_at': '2026-05-01T00:00:00Z',
        'updated_at': '2026-05-01T00:00:00Z',
        'photos': [],
        'compatibility_score': 0.85,
      };
      final pet = Pet.fromJson(json);
      expect(pet.name, 'Firulais');
      expect(pet.species, 'dog');
      expect(pet.speciesLabel, 'Perro');
      expect(pet.sexLabel, 'Macho');
      expect(pet.ageFormatted, '2 años');
      expect(pet.compatibilityScore, 0.85);
    });

    test('fromJson handles null photos gracefully', () {
      final json = {
        'id': '1', 'donor_id': '2', 'name': 'X', 'species': 'dog',
        'age_months': 1, 'sex': 'male', 'size': 'small', 'description': 'x',
        'is_neutered': false, 'is_vaccinated': false, 'energy_level': 'low',
        'requires_yard': false, 'requires_experience': false, 'status': 'available',
        'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z',
      };
      final pet = Pet.fromJson(json);
      expect(pet.photos, isEmpty);
      expect(pet.coverImage, '');
    });

    test('ageFormatted handles months and years', () {
      Pet makePet(int months) => Pet(
        id: '1', donorId: '2', name: 'X', species: 'dog', ageMonths: months,
        sex: 'male', size: 'small', isNeutered: false, isVaccinated: false,
        energyLevel: 'low', description: 'x', requiresYard: false,
        requiresExperience: false, status: 'available',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(makePet(1).ageFormatted, '1 mes');
      expect(makePet(5).ageFormatted, '5 meses');
      expect(makePet(12).ageFormatted, '1 año');
      expect(makePet(18).ageFormatted, '1 a. 6m.');
    });
  });

  group('PetPhoto model', () {
    test('fromJson handles null cloudinary_url', () {
      final json = {
        'id': '1', 'pet_id': '2', 'cloudinary_url': null,
        'cloudinary_public_id': null, 'is_primary': null,
        'order': null, 'created_at': '2026-01-01T00:00:00Z',
      };
      final photo = PetPhoto.fromJson(json);
      expect(photo.cloudinaryUrl, '');
      expect(photo.cloudinaryPublicId, '');
      expect(photo.isPrimary, false);
      expect(photo.order, 0);
    });
  });

  group('User model', () {
    test('isAdopter and isDonor', () {
      User makeUser(String role) => User(
        id: '1', email: 'x@x.com', fullName: 'X', role: role,
        isActive: true, isVerifiedEmail: false, isVerifiedPhone: false,
        verificationLevel: 0, reputationScore: 0, reputationCount: 0,
        createdAt: DateTime.now(),
      );
      expect(makeUser('adopter').isAdopter, true);
      expect(makeUser('adopter').isDonor, false);
      expect(makeUser('donor').isAdopter, false);
      expect(makeUser('donor').isDonor, true);
      expect(makeUser('both').isAdopter, true);
      expect(makeUser('both').isDonor, true);
    });
  });

  group('Match model', () {
    test('status helpers work', () {
      Match makeMatch(String status) => Match(
        id: '1', petId: '2', adopterId: '3', donorId: '4',
        status: status, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(makeMatch('pending').isPending, true);
      expect(makeMatch('accepted').isAccepted, true);
      expect(makeMatch('rejected').isRejected, true);
      expect(makeMatch('completed').isCompleted, true);
    });
  });
}
