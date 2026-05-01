import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/feed/pet_feed_screen.dart';
import '../screens/feed/pet_detail_screen.dart';
import '../screens/donor/donor_dashboard_screen.dart';
import '../screens/donor/pet_creation_screen.dart';
import '../services/api_client.dart';
import '../services/pet_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({
  required AuthProvider authProvider,
  required ApiClient apiClient,
  required FlutterSecureStorage secureStorage,
}) {
  final petService = PetService(client: apiClient);
  final petProvider = PetProvider(petService: petService);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: authProvider,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/role-selection';

      if (authProvider.status == AuthStatus.unknown) {
        return '/splash';
      }

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/feed';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) {
          return ChangeNotifierProvider.value(
            value: petProvider,
            child: const PetFeedScreen(),
          );
        },
      ),
      GoRoute(
        path: '/feed/:petId',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return ChangeNotifierProvider.value(
            value: petProvider,
            child: PetDetailScreen(petId: petId),
          );
        },
      ),
      GoRoute(
        path: '/donor',
        builder: (context, state) => const DonorDashboardScreen(),
      ),
      GoRoute(
        path: '/donor/publish',
        builder: (context, state) => const PetCreationScreen(),
      ),
    ],
  );
}
