import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../services/match_service.dart';

class MatchProvider extends ChangeNotifier {
  final MatchService _matchService;

  List<Match> _matches = [];
  bool _isLoading = false;
  String? _error;

  MatchProvider({required MatchService matchService})
      : _matchService = matchService;

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Match> get pendingMatches =>
      _matches.where((m) => m.isPending).toList();
  List<Match> get acceptedMatches =>
      _matches.where((m) => m.isAccepted).toList();
  List<Match> get completedMatches =>
      _matches.where((m) => m.isCompleted).toList();

  Future<void> loadMatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _matches = await _matchService.fetchMyMatches();
    } catch (e) {
      _error = 'No se pudieron cargar los matches.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createMatch({
    required String petId,
    String? message,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _matchService.createMatch(
        petId: petId,
        adopterMessage: message,
      );
      await loadMatches();
      return true;
    } catch (e) {
      _error = 'No se pudo expresar interés.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptMatch(String matchId) async {
    _error = null;

    try {
      await _matchService.acceptMatch(matchId);
      await loadMatches();
      return true;
    } catch (e) {
      _error = 'No se pudo aceptar el match.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectMatch(String matchId) async {
    _error = null;

    try {
      await _matchService.rejectMatch(matchId);
      await loadMatches();
      return true;
    } catch (e) {
      _error = 'No se pudo rechazar el match.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitEvidence({
    required String matchId,
    required String photoUrl,
    required String cloudinaryPublicId,
    required String statusNote,
  }) async {
    _error = null;

    try {
      await _matchService.submitEvidence(
        matchId: matchId,
        photoUrl: photoUrl,
        cloudinaryPublicId: cloudinaryPublicId,
        statusNote: statusNote,
      );
      await loadMatches();
      return true;
    } catch (e) {
      _error = 'No se pudo subir la evidencia.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReview({
    required String matchId,
    required String reviewedId,
    required int rating,
    String? comment,
  }) async {
    _error = null;

    try {
      await _matchService.submitReview(
        matchId: matchId,
        reviewedId: reviewedId,
        rating: rating,
        comment: comment,
      );
      return true;
    } catch (e) {
      _error = 'No se pudo enviar la valoración.';
      notifyListeners();
      return false;
    }
  }
}
