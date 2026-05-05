import 'package:flutter/foundation.dart';

import '../models/pet.dart';
import '../services/pet_service.dart';

class PetProvider extends ChangeNotifier {
  final PetService _petService;

  List<Pet> _pets = [];
  Pet? _selectedPet;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;

  // Filtros activos
  String? _speciesFilter;
  String? _sizeFilter;
  int? _ageMinFilter;
  int? _ageMaxFilter;

  PetProvider({required PetService petService}) : _petService = petService;

  List<Pet> get pets => _pets;
  Pet? get selectedPet => _selectedPet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  String? get speciesFilter => _speciesFilter;
  String? get sizeFilter => _sizeFilter;
  int? get ageMinFilter => _ageMinFilter;
  int? get ageMaxFilter => _ageMaxFilter;

  Future<void> loadPets({bool refresh = false, String? donorId}) async {
    if (_isLoading) return;

    if (refresh) {
      _pets = [];
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPets = await _petService.fetchPets(
        species: _speciesFilter,
        size: _sizeFilter,
        ageMin: _ageMinFilter,
        ageMax: _ageMaxFilter,
        donorId: donorId,
        offset: _pets.length,
      );

      _pets = refresh ? newPets : [..._pets, ...newPets];
      _hasMore = newPets.length >= 20;
    } catch (e) {
      _error = 'No pudimos cargar las mascotas. Intentá de nuevo.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPetDetail(String petId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedPet = await _petService.fetchPet(petId);
    } catch (e) {
      _error = 'No se pudo cargar la mascota.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void applyFilters({
    String? species,
    String? size,
    int? ageMin,
    int? ageMax,
  }) {
    _speciesFilter = species;
    _sizeFilter = size;
    _ageMinFilter = ageMin;
    _ageMaxFilter = ageMax;
    // Force reset loading state in case it got stuck
    _isLoading = false;
    notifyListeners();
    loadPets(refresh: true);
  }

  void clearFilters() {
    _speciesFilter = null;
    _sizeFilter = null;
    _ageMinFilter = null;
    _ageMaxFilter = null;
    _isLoading = false;
    notifyListeners();
    loadPets(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updatePet(String petId, Map<String, dynamic> updateData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedPet = await _petService.updatePet(petId, updateData);
      
      // Update in lists
      final index = _pets.indexWhere((p) => p.id == petId);
      if (index != -1) {
        _pets[index] = updatedPet;
      }
      if (_selectedPet?.id == petId) {
        _selectedPet = updatedPet;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar la mascota.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
