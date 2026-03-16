import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/story_creation_screen.dart';
import '../../presentation/screens/cinema_screen.dart';
import '../../presentation/screens/private_library_screen.dart';
import '../../presentation/screens/store_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-story',
        builder: (context, state) => const StoryCreationScreen(),
      ),
      GoRoute(
        path: '/cinema',
        builder: (context, state) => const CinemaScreen(),
      ),
      GoRoute(
        path: '/private-library',
        builder: (context, state) => const PrivateLibraryScreen(),
      ),
      GoRoute(
        path: '/store',
        builder: (context, state) => const StoreScreen(),
      ),
    ],
  );
}
