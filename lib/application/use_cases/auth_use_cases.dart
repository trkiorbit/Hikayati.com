import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/auth/auth_service.dart';

class AuthUseCases {
  final AuthService _authService = AuthService();

  Future<AuthResponse> signInEmail(String email, String password) async {
    try {
      return await _authService.signInEmail(email, password);
    } catch (e) {
      if (e is AuthException) {
        throw Exception(e.message);
      }
      throw Exception('فشل في تسجيل الدخول. تأكد من بياناتك.');
    }
  }

  Future<AuthResponse> signUpEmail(String email, String password) async {
    try {
      return await _authService.signUpEmail(email, password);
    } catch (e) {
      if (e is AuthException) {
        throw Exception(e.message);
      }
      throw Exception('فشل في إنشاء الحساب الجديد.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      if (e is AuthException) {
        throw Exception(e.message);
      }
      throw Exception('فشل في استعادة كلمة المرور.');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل الخروج.');
    }
  }
}
