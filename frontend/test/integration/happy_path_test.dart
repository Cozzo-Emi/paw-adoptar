import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:paw/config/theme.dart';
import 'package:paw/screens/auth/login_screen.dart';
import 'package:paw/screens/auth/register_screen.dart';
import 'package:paw/screens/auth/role_selection_screen.dart';
import 'package:paw/screens/feed/pet_feed_screen.dart';
import 'package:paw/screens/profile/profile_screen.dart';
import 'package:paw/providers/auth_provider.dart';
import 'package:paw/providers/pet_provider.dart';
import 'package:paw/providers/match_provider.dart';
import 'package:paw/providers/chat_provider.dart';
import 'package:paw/services/api_client.dart';
import 'package:paw/services/auth_service.dart';
import 'package:paw/services/pet_service.dart';
import 'package:paw/services/match_service.dart';
import 'package:paw/services/chat_service.dart';
import 'package:paw/services/token_storage.dart';

Widget _buildApp(Widget child, {AuthProvider? auth}) {
  final storage = TokenStorage();
  final apiClient = ApiClient(storage: storage);
  final authSvc = AuthService(client: apiClient, storage: storage);
  final petSvc = PetService(client: apiClient);
  final matchSvc = MatchService(client: apiClient);
  final chatSvc = ChatService(client: apiClient);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth ?? AuthProvider(authService: authSvc)),
      ChangeNotifierProvider.value(value: PetProvider(petService: petSvc)),
      ChangeNotifierProvider.value(value: MatchProvider(matchService: matchSvc)),
      ChangeNotifierProvider.value(value: ChatProvider(chatService: chatSvc)),
      Provider<ApiClient>.value(value: apiClient),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  testWidgets('Splash shows PAW branding', (tester) async {
    await tester.pumpWidget(_buildApp(const Text('PAW')));
    expect(find.text('PAW'), findsOneWidget);
  });

  testWidgets('Login → Register → Role → Feed flow renders sequentially', (tester) async {
    // 1. Login screen
    await tester.pumpWidget(_buildApp(const LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Registrate'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    // 2. Navigate to Register
    await tester.pumpWidget(_buildApp(const RegisterScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Crear Cuenta'), findsWidgets);
    expect(find.text('Nombre Completo'), findsOneWidget);
  });

  testWidgets('Role selection shows both cards', (tester) async {
    await tester.pumpWidget(_buildApp(const RoleSelectionScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Quiero Adoptar'), findsOneWidget);
    expect(find.text('Tengo mascotas para dar en adopción'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}

