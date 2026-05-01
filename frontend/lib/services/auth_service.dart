import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  final FlutterSecureStorage _storage;

  AuthService({required ApiClient client, required FlutterSecureStorage storage})
    : _client = client,
      _storage = storage;

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post(
      '/auth/login',
      data: {
        'username': email,
        'password': password,
      },
    );

    final token = AuthToken.fromJson(response.data as Map<String, dynamic>);
    await _persistToken(token);
    return token;
  }

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'adopter',
  }) async {
    final response = await _client.dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'role': role,
      },
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> fetchCurrentUser() async {
    final response = await _client.dio.get('/users/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> updateRole(String userId, String role) async {
    final response = await _client.dio.put(
      '/users/$userId',
      data: {'role': role},
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> hasValidSession() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) return false;

    try {
      await fetchCurrentUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  String? _cachedToken;

  Future<String?> getAccessToken() async {
    _cachedToken ??= await _storage.read(key: 'access_token');
    return _cachedToken;
  }

  Future<void> _persistToken(AuthToken token) async {
    await _storage.write(key: 'access_token', value: token.accessToken);
    await _storage.write(key: 'refresh_token', value: token.refreshToken);
    _cachedToken = token.accessToken;
  }
}
