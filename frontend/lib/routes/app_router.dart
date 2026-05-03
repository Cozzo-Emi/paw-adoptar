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
import '../screens/post_adoption/evidence_screen.dart';
import '../screens/post_adoption/review_screen.dart';
import '../screens/moderation/moderation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/adopter_profile_form.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/match_service.dart';
import '../services/pet_service.dart';
import '../widgets/scaffold_with_navbar.dart';

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

  final chatService = ChatService(client: apiClient);
  final chatProvider = ChatProvider(chatService: chatService);

  final shellProviders = [
    ChangeNotifierProvider.value(value: petProvider),
    ChangeNotifierProvider.value(value: matchProvider),
    ChangeNotifierProvider.value(value: chatProvider),
  ];

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: authProvider,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authProvider.status == AuthStatus.unknown) return '/splash';

      if (isSplash && !isAuth) return '/login';
      if (isSplash && isAuth) return '/feed';

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
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            builder: (context, state) => MultiProvider(
              providers: shellProviders,
              child: const PetFeedScreen(),
            ),
          ),
          GoRoute(
            path: '/feed/:petId',
            builder: (context, state) {
              final petId = state.pathParameters['petId']!;
              return MultiProvider(
                providers: shellProviders,
                child: PetDetailScreen(petId: petId),
              );
            },
          ),
          GoRoute(
            path: '/donor',
            builder: (context, state) => MultiProvider(
              providers: shellProviders,
              child: const DonorDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/donor/publish',
            builder: (context, state) => MultiProvider(
              providers: shellProviders,
              child: const PetCreationScreen(),
            ),
          ),
          GoRoute(
            path: '/matches',
            builder: (context, state) => MultiProvider(
              providers: shellProviders,
              child: const MatchInboxScreen(),
            ),
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
              final otherName = state.uri.queryParameters['name'];
              return ChangeNotifierProvider.value(
                value: chatProvider,
                child: ChatRoomScreen(chatId: chatId, otherName: otherName),
              );
            },
          ),
          GoRoute(
            path: '/evidence/:matchId',
            builder: (context, state) {
              final matchId = state.pathParameters['matchId']!;
              final match = matchProvider.matches
                  .where((m) => m.id == matchId)
                  .firstOrNull;
              if (match == null) return const SizedBox.shrink();
              return ChangeNotifierProvider.value(
                value: matchProvider,
                child: EvidenceScreen(match: match),
              );
            },
          ),
          GoRoute(
            path: '/review/:matchId',
            builder: (context, state) {
              final matchId = state.pathParameters['matchId']!;
              final match = matchProvider.matches
                  .where((m) => m.id == matchId)
                  .firstOrNull;
              if (match == null) return const SizedBox.shrink();
              return ChangeNotifierProvider.value(
                value: matchProvider,
                child: ReviewScreen(match: match),
              );
            },
          ),
          GoRoute(
            path: '/moderation',
            builder: (context, state) => const ModerationScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/adopter',
            builder: (context, state) => const AdopterProfileForm(),
          ),
        ],
      ),
    ],
  );
}
