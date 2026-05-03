import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(storage: tokenStorage);
  final authService = AuthService(client: apiClient, storage: tokenStorage);
  final authProvider = AuthProvider(authService: authService);

  try {
    await FCMService.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Firebase no configurado o timeout — modo sin push
  }

  runApp(PawApp(
    authProvider: authProvider,
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  ));
}

class PawApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  const PawApp({
    super.key,
    required this.authProvider,
    required this.apiClient,
    required this.tokenStorage,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authProvider,
      child: Provider<ApiClient>.value(
        value: apiClient,
        child: MaterialApp.router(
          title: 'PAW',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: buildRouter(
            authProvider: authProvider,
            apiClient: apiClient,
            tokenStorage: tokenStorage,
          ),
        ),
      ),
    );
  }
}
