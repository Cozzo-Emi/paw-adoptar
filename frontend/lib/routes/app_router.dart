import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/match_provider.dart';
import '../providers/pet_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/feed/pet_feed_screen.dart';
import '../screens/feed/pet_detail_screen.dart';
import '../screens/donor/donor_dashboard_screen.dart';
import '../screens/donor/pet_creation_screen.dart';
import '../screens/matches/match_inbox_screen.dart';
import '../screens/matches/chat_list_screen.dart';
import '../screens/matches/chat_room_screen.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/match_service.dart';
import '../services/pet_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({
  required AuthProvider authProvider,
  required ApiClient apiClient,
  required FlutterSecureStorage secureStorage,
}) {
  final petService = PetService(client: apiClient);
  final petProvider = PetProvider(petService: petService);

  final matchService = MatchService(client: apiClient);
  final matchProvider = MatchProvider(matchService: matchService);

  final chatService = ChatService(client: apiClient, storage: secureStorage);
  final chatProvider = ChatProvider(chatService: chatService);

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
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: petProvider),
              ChangeNotifierProvider.value(value: matchProvider),
            ],
            child: const PetFeedScreen(),
          );
        },
      ),
      GoRoute(
        path: '/feed/:petId',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: petProvider),
              ChangeNotifierProvider.value(value: matchProvider),
            ],
            child: PetDetailScreen(petId: petId),
          );
        },
      ),
      GoRoute(
        path: '/donor',
        builder: (context, state) => ChangeNotifierProvider.value(
          value: matchProvider,
          child: const DonorDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/donor/publish',
        builder: (context, state) => const PetCreationScreen(),
      ),
      GoRoute(
        path: '/matches',
        builder: (context, state) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: matchProvider),
              ChangeNotifierProvider.value(value: chatProvider),
            ],
            child: const MatchInboxScreen(),
          );
        },
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => ChangeNotifierProvider.value(
          value: chatProvider,
          child: const ChatListScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChangeNotifierProvider.value(
            value: chatProvider,
            child: ChatRoomScreen(chatId: chatId),
          );
        },
      ),
    ],
  );
}
