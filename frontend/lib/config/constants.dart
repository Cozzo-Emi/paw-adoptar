class AppConstants {
  AppConstants._();

  static const String appName = 'PAW';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration accessTokenExpiry = Duration(minutes: 30);
  static const Duration requestTimeout = Duration(seconds: 30);
}
