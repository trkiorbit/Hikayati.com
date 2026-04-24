import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: unused_import
import 'package:google_sign_in/google_sign_in.dart'; // محفوظ لـ Phase 6
import 'package:hikayati/core/network/supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  // To use Google Sign in you will need to provide the Web Client ID from GCP
  // We will leave this null/empty until you configure it.
  final String? webClientId = null;
  final String? iosClientId = null;

  Future<AuthResponse> signInEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // ═══════════════════════════════════════════════════════════════════
  // [DISABLED_FOR_FIRST_LAUNCH] — Phase 1 batch-002
  // Google Sign-In معطّل رسمياً للإطلاق الأول.
  // UI لا يعرض زر Google — هذه الدالة لا تُستدعى من أي مكان حالياً.
  //
  // TODO(phase-6): إعادة التفعيل بعد إعداد Google Cloud Console:
  //   1. إنشاء Web Client ID في GCP
  //   2. ربطه بـ Supabase Auth provider
  //   3. تعبئة webClientId + iosClientId أدناه
  //   4. إضافة زر Google في LoginScreen
  // ═══════════════════════════════════════════════════════════════════
  Future<AuthResponse?> signInWithGoogle() async {
    throw Exception(
      '[DISABLED_FOR_FIRST_LAUNCH] Google Sign-In غير مفعّل في الإطلاق الأول. '
      'سيُفعّل في Phase 6 بعد إعداد Google Cloud Console.',
    );

    // ──────────────────────────────────────────────────────────────
    // الكود التالي محفوظ للمرحلة 6 — لا تحذفه
    // ──────────────────────────────────────────────────────────────
    // final GoogleSignIn googleSignIn = GoogleSignIn(
    //   serverClientId: webClientId,
    //   clientId: iosClientId,
    // );
    // final googleUser = await googleSignIn.signIn();
    // final googleAuth = await googleUser!.authentication;
    // final accessToken = googleAuth.accessToken;
    // final idToken = googleAuth.idToken;
    // if (accessToken == null) throw 'No Access Token found.';
    // if (idToken == null) throw 'No ID Token found.';
    // return await _client.auth.signInWithIdToken(
    //   provider: OAuthProvider.google,
    //   idToken: idToken,
    //   accessToken: accessToken,
    // );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
