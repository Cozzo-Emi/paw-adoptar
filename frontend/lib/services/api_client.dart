import 'package:dio/dio.dart';

import '../config/constants.dart';
import '../models/user.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _storage;
  bool _isRefreshing = false;

  ApiClient({required TokenStorage storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Already tried refreshing, give up
    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        _isRefreshing = false;
        handler.next(err);
        return;
      }

      final response = await Dio(
        BaseOptions(baseUrl: AppConstants.apiBaseUrl),
      ).post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final authToken = AuthToken.fromJson(response.data as Map<String, dynamic>);
      await _storage.write(key: 'access_token', value: authToken.accessToken);
      await _storage.write(key: 'refresh_token', value: authToken.refreshToken);

      // Retry the original request with the new token
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer ${authToken.accessToken}';

      final retryResponse = await Dio().fetch(options);
      _isRefreshing = false;
      handler.resolve(retryResponse);
    } catch (e) {
      _isRefreshing = false;
      await _storage.deleteAll();
      handler.next(err);
    }
  }
}
