import 'package:go_router/go_router.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:hikayati/features/home/screens/home_screen.dart';
import 'package:hikayati/features/auth/screens/login_screen.dart';
import 'package:hikayati/features/story_engine/screens/cinema_screen.dart';
import 'package:hikayati/features/story_engine/screens/story_creation_screen.dart';
import 'package:hikayati/features/library/screens/private_library_screen.dart';
import 'package:hikayati/features/library/screens/public_library_screen.dart';
import 'package:hikayati/features/legal/screens/privacy_policy_screen.dart';
import 'package:hikayati/features/legal/screens/terms_of_service_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = SupabaseService.client.auth.currentSession;
      final loggingIn = state.matchedLocation == '/login';

      if (session == null && !loggingIn) return '/login';
      if (session != null && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/cinema',
        builder: (context, state) => const CinemaScreen(),
      ),
      GoRoute(
        path: '/story_creation',
        builder: (context, state) => const StoryCreationScreen(),
      ),
      GoRoute(
        path: '/private_library',
        builder: (context, state) => const PrivateLibraryScreen(),
      ),
      GoRoute(
        path: '/public_library',
        builder: (context, state) => const PublicLibraryScreen(),
      ),
      GoRoute(
        path: '/privacy_policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms_of_service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
    ],
  );
}
