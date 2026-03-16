import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const HikayatiApp());
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
        Locale('ar', 'SA'), // Arabic (Saudi Arabia) as default
        Locale('en', 'US'), // English as fallback
      ],
      locale: const Locale('ar', 'SA'), // Force Arabic / RTL by default
      
      routerConfig: AppRouter.router,
    );
  }
}
