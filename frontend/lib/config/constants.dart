import 'platform_utils.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'PAW';

  /// Allows overriding at compile-time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  /// Resolves the correct backend URL per platform:
  /// - Android emulator: 10.0.2.2 (maps to host machine's localhost)
  /// - Everything else (Windows, web, iOS sim): localhost
  static String get apiBaseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;

    // Apuntar siempre a producción por defecto
    return 'https://paw-adoptar-production.up.railway.app';
  }

  static const Duration accessTokenExpiry = Duration(minutes: 30);
  static const Duration requestTimeout = Duration(seconds: 30);
}
