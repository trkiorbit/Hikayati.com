import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/story_engine/screens/story_creation_screen.dart';
import '../../features/story_engine/screens/cinema_screen.dart';
import '../../features/library/screens/public_library_screen.dart';
import '../../features/library/screens/private_library_screen.dart';

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
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/create-story',
        builder: (context, state) => const StoryCreationScreen(),
      ),
      GoRoute(
        path: '/cinema',
        builder: (context, state) {
          final storyData = state.extra as Map<String, dynamic>? ?? {};
          return CinemaScreen(storyData: storyData);
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
