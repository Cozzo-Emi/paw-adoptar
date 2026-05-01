import '../models/pet.dart';
import 'api_client.dart';

class PetService {
  final ApiClient _client;

  PetService({required ApiClient client}) : _client = client;

  Future<List<Pet>> fetchPets({
    String? species,
    String? size,
    int? ageMin,
    int? ageMax,
    String? city,
    String? province,
    String? donorId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (species != null) queryParams['species'] = species;
    if (size != null) queryParams['size'] = size;
    if (ageMin != null) queryParams['age_min'] = ageMin.toString();
    if (ageMax != null) queryParams['age_max'] = ageMax.toString();
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (province != null && province.isNotEmpty) {
      queryParams['province'] = province;
    }
    if (donorId != null) queryParams['donor_id'] = donorId;

    final response = await _client.dio.get(
      '/pets',
      queryParameters: queryParams,
    );

    final list = response.data as List<dynamic>;
    return list
        .map((json) => Pet.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Pet> fetchPet(String petId) async {
    final response = await _client.dio.get('/pets/$petId');
    return Pet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSignedUploadParams() async {
    final response = await _client.dio.get('/pets/signed-upload');
    return response.data as Map<String, dynamic>;
  }

  Future<Pet> createPet(Map<String, dynamic> petData) async {
    final response = await _client.dio.post('/pets', data: petData);
    return Pet.fromJson(response.data as Map<String, dynamic>);
  }
}
