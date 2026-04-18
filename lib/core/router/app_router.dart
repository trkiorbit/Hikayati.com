import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/app_intro_screen.dart';
import '../../features/story_engine/screens/story_creation_screen.dart';
import '../../features/story_engine/screens/cinema_screen.dart';
import '../../features/story_engine/screens/intro_cinematic_screen.dart';
import '../../features/story_engine/screens/generation_loading_screen.dart';
import '../../features/library/screens/public_library_screen.dart';
import '../../features/library/screens/private_library_screen.dart';
import '../../features/hakeem/screens/hakeem_chat_screen.dart';
import '../../features/avatar_lab/screens/avatar_lab_screen.dart';
import '../../features/voice_clone/screens/voice_clone_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/store/screens/store_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/legal/screens/data_deletion_screen.dart';
import '../../features/legal/screens/content_policy_screen.dart';

/// يستمع لتغييرات Auth ويُعيد تقييم redirect تلقائياً
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

class AppRouter {
  static final _authNotifier = _AuthNotifier();

  /// التحقق من صلاحية الجلسة (وليس مجرد وجودها)
  static bool _isSessionValid() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
        .isAfter(DateTime.now());
  }

  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isAuth = _isSessionValid();
      final loc = state.matchedLocation;

      if (loc == '/app-intro') return null;

      if (!isAuth && loc != '/login') return '/login';
      if (isAuth && loc == '/login') return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/app-intro', builder: (context, state) => const AppIntroScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/hakeem', builder: (context, state) => const HakeemChatScreen()),
      GoRoute(path: '/avatar-lab', builder: (context, state) => const AvatarLabScreen()),
      GoRoute(
        path: '/create-story',
        builder: (context, state) => const StoryCreationScreen(),
      ),
      GoRoute(
        path: '/cinema',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CinemaScreen(
            storyData: extra['storyData'] ?? {},
            voice: extra['voice'] ?? '',
            fromLibrary: extra['fromLibrary'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/generation-loading',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return GenerationLoadingScreen(
              requestData: extra['requestData'] ?? {}, voice: extra['voice'] ?? '');
        },
      ),
      GoRoute(
        path: '/intro-cinematic',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return IntroCinematicScreen(
            requestData: extra['requestData'] as Map<String, dynamic>? ?? {},
            voice: extra['voice'] ?? '',
            saveToLibrary: extra['saveToLibrary'] as bool? ?? true,
          );
        },
      ),
      GoRoute(path: '/public-library', builder: (context, state) => const PublicLibraryScreen()),
      GoRoute(path: '/private-library', builder: (context, state) => const PrivateLibraryScreen()),
      GoRoute(path: '/voice-clone', builder: (context, state) => const VoiceCloneScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/store', builder: (context, state) => const StoreScreen()),
      GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms', builder: (context, state) => const TermsOfServiceScreen()),
      GoRoute(path: '/data-deletion', builder: (context, state) => const DataDeletionScreen()),
      GoRoute(path: '/content-policy', builder: (context, state) => const ContentPolicyScreen()),
    ],
  );
}
