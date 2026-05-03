import 'package:flutter_test/flutter_test.dart';
import 'package:paw/providers/auth_provider.dart';
import 'package:paw/providers/pet_provider.dart';
import 'package:paw/providers/match_provider.dart';
import 'package:paw/models/user.dart';
import 'package:paw/models/pet.dart';
import 'package:paw/models/match.dart';
import 'package:paw/services/auth_service.dart';
import 'package:paw/services/pet_service.dart';
import 'package:paw/services/match_service.dart';
import 'package:paw/services/api_client.dart';
import 'package:paw/services/token_storage.dart';

// ── Mocks ─────────────────────────────────────────────

class _FakeAuthService extends Fake implements AuthService {
  bool _hasSession = false;
  User? _user;
  @override
  Future<bool> hasValidSession() async => _hasSession;
  @override
  Future<User> fetchCurrentUser() async => _user ?? _throw();
  @override
  Future<AuthToken> login({required String email, required String password}) async =>
      AuthToken(accessToken: 'tok', refreshToken: 'ref');
  @override
  Future<User> register({required String email, required String password, required String fullName, String? phone, String role = 'adopter'}) async =>
      User(id: '1', email: email, fullName: fullName, role: role, isActive: true, isVerifiedEmail: false, isVerifiedPhone: false, verificationLevel: 0, reputationScore: 0, reputationCount: 0, createdAt: DateTime.now());
  @override
  Future<User> updateProfile({String? role, String? city, String? province}) async =>
      User(id: '1', email: 'x@x.com', fullName: 'X', role: role ?? 'adopter', isActive: true, isVerifiedEmail: false, isVerifiedPhone: false, verificationLevel: 0, reputationScore: 0, reputationCount: 0, createdAt: DateTime.now());
  @override
  Future<void> logout() async {}
  @override
  Future<String?> getAccessToken() async => 'tok';

  Never _throw() => throw Exception('not set');
}

class _FakePetService extends Fake implements PetService {
  List<Pet> _pets = [];
  @override
  Future<List<Pet>> fetchPets({String? species, String? size, int? ageMin, int? ageMax, String? city, String? province, String? donorId, int limit = 20, int offset = 0}) async => _pets;
  @override
  Future<Pet> fetchPet(String petId) async => _throw();
  @override
  Future<Pet> createPet(Map<String, dynamic> data) async => _throw();
  @override
  Future<Pet> updatePet(String petId, Map<String, dynamic> data) async => _throw();
  @override
  Future<Map<String, dynamic>> getSignedUploadParams() async => {};
  Never _throw() => throw Exception('mock');
}

class _FakeMatchService extends Fake implements MatchService {
  List<Match> _matches = [];
  @override
  Future<List<Match>> fetchMyMatches() async => _matches;
  @override
  Future<Match> createMatch({required String petId, String? adopterMessage}) async => _throw();
  @override
  Future<Match> acceptMatch(String matchId) async => _throw();
  @override
  Future<Match> rejectMatch(String matchId) async => _throw();
  Never _throw() => throw Exception('mock');
}

// ── Tests ─────────────────────────────────────────────

void main() {
  group('AuthProvider', () {
    test('initial status is unknown', () {
      final auth = AuthProvider(authService: _FakeAuthService());
      expect(auth.status, AuthStatus.unknown);
      expect(auth.isAuthenticated, false);
    });

    test('forceUnauthenticated sets status correctly', () {
      final auth = AuthProvider(authService: _FakeAuthService());
      auth.forceUnauthenticated();
      expect(auth.status, AuthStatus.unauthenticated);
    });
  });

  group('PetProvider', () {
    test('loadPets populates pets list', () async {
      final svc = _FakePetService();
      final pet = Pet(id: '1', donorId: '2', name: 'Firulais', species: 'dog', ageMonths: 12, sex: 'male', size: 'medium', isNeutered: false, isVaccinated: false, energyLevel: 'medium', description: 'x', requiresYard: false, requiresExperience: false, status: 'available', createdAt: DateTime.now(), updatedAt: DateTime.now());
      svc._pets = [pet];
      final provider = PetProvider(petService: svc);
      await provider.loadPets(refresh: true);
      expect(provider.pets.length, 1);
      expect(provider.pets[0].name, 'Firulais');
      expect(provider.isLoading, false);
    });
  });
}
