import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = const FlutterSecureStorage();
  final apiClient = ApiClient(storage: secureStorage);
  final authService = AuthService(client: apiClient, storage: secureStorage);
  final authProvider = AuthProvider(authService: authService);

  runApp(PawApp(
    authProvider: authProvider,
    apiClient: apiClient,
    secureStorage: secureStorage,
  ));
}

class PawApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  const PawApp({
    super.key,
    required this.authProvider,
    required this.apiClient,
    required this.secureStorage,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authProvider,
      child: MaterialApp.router(
        title: 'PAW',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: buildRouter(
          authProvider: authProvider,
          apiClient: apiClient,
          secureStorage: secureStorage,
        ),
      ),
    );
  }
}
