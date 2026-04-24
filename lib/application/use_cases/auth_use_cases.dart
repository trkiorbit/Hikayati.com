import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/core/auth/auth_service.dart';
import 'package:hikayati/core/network/supabase_service.dart';

class AuthUseCases {
  final AuthService _authService = AuthService();

  /// مفاتيح SharedPreferences الخاصة بالمستخدم — تُمسح عند signOut
  /// لمنع تسريب بيانات مستخدم سابق للمستخدم التالي على نفس الجهاز
  static const List<String> _userScopedPrefsKeys = [
    'cloned_voice_id',
    'saved_avatar',
  ];

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
      final response = await _authService.signUpEmail(email, password);
      // Phase 1 batch-002: eager profile creation
      // يُنشأ profile row فوراً بعد signup ليتجنّب lazy creation لاحقاً
      // ensureProfileExists يتعامل مع duplicate (لا crash إذا موجود)
      final userId = response.user?.id;
      if (userId != null) {
        await SupabaseService.ensureProfileExists(userId);
      }
      return response;
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
      // Phase 1 batch-003c: تنظيف أي cache محلي مربوط بالمستخدم السابق
      // يمنع تسريب voice_id/avatar للمستخدم التالي على نفس الجهاز
      final prefs = await SharedPreferences.getInstance();
      for (final key in _userScopedPrefsKeys) {
        await prefs.remove(key);
      }
      await _authService.signOut();
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل الخروج.');
    }
  }
}
