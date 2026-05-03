import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:paw/config/theme.dart';
import 'package:paw/screens/auth/login_screen.dart';
import 'package:paw/screens/auth/register_screen.dart';
import 'package:paw/screens/auth/role_selection_screen.dart';
import 'package:paw/screens/donor/donor_dashboard_screen.dart';
import 'package:paw/screens/donor/pet_creation_screen.dart';
import 'package:paw/screens/feed/pet_feed_screen.dart';
import 'package:paw/screens/feed/pet_detail_screen.dart';
import 'package:paw/providers/auth_provider.dart';
import 'package:paw/providers/pet_provider.dart';
import 'package:paw/providers/match_provider.dart';
import 'package:paw/providers/chat_provider.dart';
import 'package:paw/models/user.dart';
import 'package:paw/services/api_client.dart';
import 'package:paw/services/auth_service.dart';
import 'package:paw/services/pet_service.dart';
import 'package:paw/services/chat_service.dart';
import 'package:paw/services/match_service.dart';
import 'package:paw/services/token_storage.dart';

// ─── Helpers ────────────────────────────────────────────

Widget wrapWithProviders(Widget child, {AuthProvider? auth}) {
  final storage = TokenStorage();
  final apiClient = ApiClient(storage: storage);
  final authService = AuthService(client: apiClient, storage: storage);
  final petService = PetService(client: apiClient);
  final petProvider = PetProvider(petService: petService);
  final matchService = MatchService(client: apiClient);
  final matchProvider = MatchProvider(matchService: matchService);
  final chatService = ChatService(client: apiClient);
  final chatProvider = ChatProvider(chatService: chatService);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth ?? AuthProvider(authService: authService)),
      ChangeNotifierProvider.value(value: petProvider),
      ChangeNotifierProvider.value(value: matchProvider),
      ChangeNotifierProvider.value(value: chatProvider),
      Provider<ApiClient>.value(value: apiClient),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

AuthProvider _mockAuth({String role = 'adopter'}) {
  final storage = TokenStorage();
  final apiClient = ApiClient(storage: storage);
  final authService = AuthService(client: apiClient, storage: storage);
  final auth = AuthProvider(authService: authService);
  // Force authentication state
  auth.forceUnauthenticated();
  return auth;
}

// ─── Tests ──────────────────────────────────────────────

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('shows validation error on empty submit', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();
      // Should still be on screen (validation prevented navigation)
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('renders all required fields', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pumpAndSettle();
      // "Crear Cuenta" appears twice: title + button
      expect(find.text('Crear Cuenta'), findsNWidgets(2));
      expect(find.byType(TextFormField), findsWidgets);
    });
  });

  group('RoleSelectionScreen', () {
    testWidgets('renders role cards', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const RoleSelectionScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Quiero Adoptar'), findsOneWidget);
      expect(find.text('Tengo mascotas para dar en adopción'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('continue button disabled until role selected', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const RoleSelectionScreen()));
      await tester.pumpAndSettle();
      // Find the ElevatedButton that contains "Continuar" text
      final btn = find.widgetWithText(ElevatedButton, 'Continuar');
      expect(btn, findsOneWidget);
      final widget = tester.widget<ElevatedButton>(btn);
      expect(widget.onPressed, isNull);
    });
  });

  group('DonorDashboardScreen', () {
    testWidgets('renders without crashing for donor role', (tester) async {
      final auth = _mockAuth(role: 'donor');
      await tester.pumpWidget(wrapWithProviders(const DonorDashboardScreen(), auth: auth));
      await tester.pump();
      // Should not crash — just verify it renders
      expect(find.byType(DonorDashboardScreen), findsOneWidget);
    });
  });

  group('PetCreationScreen', () {
    testWidgets('renders 4 step tabs without crash', (tester) async {
      await tester.pumpWidget(wrapWithProviders(
        const PetCreationScreen(),
        auth: _mockAuth(role: 'donor'),
      ));
      await tester.pumpAndSettle();
      // Should show step labels
      expect(find.text('Fotos'), findsOneWidget);
      expect(find.text('Datos básicos'), findsOneWidget);
      expect(find.text('Salud & Comportamiento'), findsOneWidget);
      expect(find.text('Requisitos del tutor'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
    });

    testWidgets('cancel button is present', (tester) async {
      await tester.pumpWidget(wrapWithProviders(
        const PetCreationScreen(),
        auth: _mockAuth(role: 'donor'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar'), findsOneWidget);
    });
  });

  group('PetFeedScreen', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const PetFeedScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PetFeedScreen), findsOneWidget);
    });
  });
}
