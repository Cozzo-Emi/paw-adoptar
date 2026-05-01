import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;

  AuthProvider({
    required AuthService authService,
  }) : _authService = authService;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuthStatus() async {
    final isValid = await _authService.hasValidSession();

    if (isValid) {
      _user = await _authService.fetchCurrentUser();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email: email, password: password);
      _user = await _authService.fetchCurrentUser();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'adopter',
  }) async {
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      // Auto-login after register
      await _authService.login(email: email, password: password);
      _user = await _authService.fetchCurrentUser();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateProfile({String? role, String? city, String? province}) async {
    _user = await _authService.updateProfile(
      role: role,
      city: city,
      province: province,
    );
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('400')) return 'Datos inválidos. Verificá tu información.';
      if (message.contains('401')) return 'Email o contraseña incorrectos.';
      if (message.contains('email already exists')) return 'El email ya está registrado.';
      return message.replaceAll('Exception: ', '');
    }
    return 'Error de conexión. Intentá de nuevo.';
  }
}
