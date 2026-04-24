import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/theme/app_colors.dart';

/// شريط الرصيد الموحّد — يُعرض في AppBar.actions لكل الشاشات
/// (عدا شاشة السينما ومسار توليد القصة).
///
/// يقرأ credits من profiles ويستمع للتحديثات اللحظية عبر Supabase Stream.
class CreditsBadge extends StatefulWidget {
  const CreditsBadge({super.key});

  @override
  State<CreditsBadge> createState() => _CreditsBadgeState();
}

class _CreditsBadgeState extends State<CreditsBadge> {
  int? _credits;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  Future<void> _bind() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _credits = 0);
      return;
    }

    // جلب فوري
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('credits')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() => _credits = res['credits'] as int? ?? 0);
      }
    } catch (_) {}

    // اشتراك لحظي
    _sub = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .listen((maps) {
      if (maps.isNotEmpty && mounted) {
        setState(() => _credits = maps.first['credits'] as int? ?? 0);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _credits == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.vibrantOrange),
                )
              : Text('$_credits',
                  style: const TextStyle(
                      color: AppColors.vibrantOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
          const SizedBox(width: 4),
          const Icon(Icons.stars,
              color: AppColors.vibrantOrange, size: 28),
        ],
      ),
    );
  }
}
