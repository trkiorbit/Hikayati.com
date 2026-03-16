import 'package:go_router/go_router.dart';
import 'package:hikayati/features/home/screens/home_screen.dart';
import 'package:hikayati/features/story_engine/screens/story_creation_screen.dart';
import 'package:hikayati/features/story_engine/screens/cinema_screen.dart';
import 'package:hikayati/features/library/screens/private_library_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
      // تم التعليق مؤقتاً لتجنب الخطأ حتى يتم إنشاء ملف المتجر في المسار الجديد
      // GoRoute(
      //   path: '/store',
      //   builder: (context, state) => const StoreScreen(),
      // ),
    ],
  );
}
