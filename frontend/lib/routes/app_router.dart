import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/feed/pet_feed_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider authProvider) {
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

      // Still checking...
      if (authProvider.status == AuthStatus.unknown) {
        return '/splash';
      }

      // Not authenticated → redirect to login
      if (!isAuth && !isAuthRoute) return '/login';

      // Authenticated but on an auth route → redirect to home
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
        builder: (context, state) => const PetFeedScreen(),
      ),
    ],
  );
}
