import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // تنظيف الجلسات المنتهية قبل تحميل التطبيق
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    try {
      await Supabase.instance.client.auth.refreshSession();
      debugPrint('[Auth] تم تجديد الجلسة بنجاح');
    } catch (_) {
      debugPrint('[Auth] الجلسة منتهية — تسجيل خروج تلقائي');
      await Supabase.instance.client.auth.signOut();
    }
  }

  runApp(const ProviderScope(child: HikayatiApp()));
}

class HikayatiApp extends StatelessWidget {
  const HikayatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hikayati - حكواتي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // RTL Setup for Arabic
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ar', 'SA'),

      routerConfig: AppRouter.router,
    );
  }
}
