import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('أمر خطير: لم يتم العثور على مفاتيح Supabase في ملف .env!');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Deducts credits securely using the RPC function `deduct_credits`.
  /// Returns `true` if successful, or throws an exception if insufficient credits.
  static Future<bool> deductCredits(int amount, String reason) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول لإتمام العملية');
    }

    try {
      final response = await client.rpc('deduct_credits', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_reason': reason,
      });
      return response['success'] == true;
    } catch (e) {
      if (e.toString().contains('Insufficient credits')) {
        throw Exception('رصيدك غير كافٍ. يرجى زيارة المتجر لشحن الرصيد.');
      }
      throw Exception('فشلت عملية الخصم: $e');
    }
  }
  /// يتحقق من وجود صف للمستخدم في جدول profiles.
  /// إذا لم يكن موجوداً يُنشئه تلقائياً (يمنع خطأ stories_user_id_fkey).
  static Future<void> ensureProfileExists(String userId) async {
    try {
      final existing = await client
          .from('profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await client.from('profiles').insert({
          'user_id': userId,
          'credits': 100,
          'language': 'ar',
        });
        debugPrint('[SupabaseService] ✅ تم إنشاء Profile جديد للمستخدم: $userId');
      } else {
        debugPrint('[SupabaseService] Profile موجود مسبقاً — لا حاجة للإنشاء.');
      }
    } catch (e) {
      // لا نرمي الخطأ — نستمر في الحفظ ونسمح لـ FK يحسم الوضع
      debugPrint('[SupabaseService] ⚠️ خطأ في ensureProfileExists: $e');
    }
  }
}
