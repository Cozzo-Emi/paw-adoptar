import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'token_storage.dart';

class AuthService {
  final ApiClient _client;
  final TokenStorage _storage;

  AuthService({required ApiClient client, required TokenStorage storage})
    : _client = client,
      _storage = storage;

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    // OAuth2PasswordRequestForm requires x-www-form-urlencoded
    final response = await _client.dio.post(
      '/auth/login',
      data: FormData.fromMap({
        'username': email,
        'password': password,
      }),
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

  Future<User> updateProfile({String? role, String? city, String? province}) async {
    final data = <String, dynamic>{};
    if (role != null) data['role'] = role;
    if (city != null) data['city'] = city;
    if (province != null) data['province'] = province;
    final response = await _client.dio.put('/users/me', data: data);
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
