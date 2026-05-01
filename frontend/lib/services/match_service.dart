import '../models/match.dart';
import 'api_client.dart';

class MatchService {
  final ApiClient _client;

  MatchService({
    required ApiClient client,
  }) : _client = client;

  Future<Match> createMatch({
    required String petId,
    String? adopterMessage,
  }) async {
    final body = <String, dynamic>{'pet_id': petId};
    if (adopterMessage != null) {
      body['adopter_message'] = adopterMessage;
    }

    final response = await _client.dio.post('/matches', data: body);
    return Match.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Match>> fetchMyMatches() async {
    final response = await _client.dio.get('/matches/me');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => Match.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Match> acceptMatch(String matchId) async {
    final response = await _client.dio.put('/matches/$matchId/accept');
    return Match.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Match> rejectMatch(String matchId) async {
    final response = await _client.dio.put('/matches/$matchId/reject');
    return Match.fromJson(response.data as Map<String, dynamic>);
  }
}
