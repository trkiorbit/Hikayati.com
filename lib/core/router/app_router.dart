import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/story_engine/screens/story_creation_screen.dart';
import '../../features/story_engine/screens/cinema_screen.dart';
import '../../features/library/screens/public_library_screen.dart';
import '../../features/library/screens/private_library_screen.dart';
import '../../features/story_engine/screens/intro_cinematic_screen.dart';
import '../../features/story_engine/screens/generation_loading_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuth && !isGoingToLogin) return '/login';
      if (isAuth && isGoingToLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/create-story',
        builder: (context, state) => const StoryCreationScreen(),
      ),
      GoRoute(
        path: '/cinema',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final storyData = extra['storyData'] ?? {};
          final voice = extra['voice'] ?? '';
          return CinemaScreen(storyData: storyData, voice: voice);
        },
      ),
      GoRoute(
        path: '/generation-loading',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final requestData = extra['requestData'] ?? {};
          final voice = extra['voice'] ?? '';
          return GenerationLoadingScreen(
              requestData: requestData, voice: voice);
        },
      ),
      GoRoute(
        path: '/intro-cinematic',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          // requestData: بيانات الطلب، التوليد يحدث داخل IntroCinematicScreen
          final requestData = extra['requestData'] as Map<String, dynamic>? ?? {};
          final voice = extra['voice'] ?? '';
          return IntroCinematicScreen(requestData: requestData, voice: voice);
        },
      ),
      GoRoute(
        path: '/public-library',
        builder: (context, state) => const PublicLibraryScreen(),
      ),
      GoRoute(
        path: '/private-library',
        builder: (context, state) => const PrivateLibraryScreen(),
      ),
    ],
  );
}
