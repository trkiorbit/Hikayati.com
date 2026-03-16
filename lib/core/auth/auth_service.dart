import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<AuthResponse?> signInWithGoogle() async {
    // You'll need to configure this Web Client ID from Google Cloud Console
    // specifically for your Supabase project. For now, it will throw an error
    // if webClientId is null.
    if (webClientId == null) {
      throw Exception(
        'Google Sign-In is not configured yet. Please add your webClientId.',
      );
    }

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      clientId: iosClientId,
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
