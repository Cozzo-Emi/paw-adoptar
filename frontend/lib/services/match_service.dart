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

  Future<Map<String, dynamic>> submitEvidence({
    required String matchId,
    required String photoUrl,
    required String cloudinaryPublicId,
    required String statusNote,
  }) async {
    final response = await _client.dio.post(
      '/matches/$matchId/evidence',
      data: {
        'match_id': matchId,
        'photo_url': photoUrl,
        'cloudinary_public_id': cloudinaryPublicId,
        'status_note': statusNote,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitReview({
    required String matchId,
    required String reviewedId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.dio.post(
      '/moderation/reviews',
      data: {
        'match_id': matchId,
        'reviewed_id': reviewedId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
