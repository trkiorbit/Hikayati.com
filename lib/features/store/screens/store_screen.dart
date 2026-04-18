import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/theme/app_colors.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _credits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCredits();
  }

  Future<void> _fetchCredits() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('credits')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _credits = res['credits'] as int? ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('شحن الرصيد',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.glassWhite,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── الرصيد الحالي ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDeepPurple,
                    AppColors.primaryDeepPurple.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('رصيدك الحالي',
                      style: TextStyle(
                          color: AppColors.glassWhite.withValues(alpha: 0.8),
                          fontSize: 14)),
                  const SizedBox(height: 10),
                  _loading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.vibrantOrange))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$_credits',
                                style: const TextStyle(
                                    color: AppColors.vibrantOrange,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.stars,
                                color: AppColors.vibrantOrange, size: 32),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── عنوان ──
            Text('اختر باقة الشحن',
                style: TextStyle(
                    color: AppColors.glassWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('سيتم ربط الدفع عبر المتاجر الرسمية قريبًا',
                style: TextStyle(
                    color: AppColors.glassWhite.withValues(alpha: 0.5),
                    fontSize: 13)),
            const SizedBox(height: 20),

            // ── الباقات ──
            _buildPackage(
              gems: 50,
              name: 'باقة المبتدئ',
              price: '4.99',
              icon: Icons.star_outline,
            ),
            _buildPackage(
              gems: 100,
              name: 'باقة المغامر',
              price: '8.99',
              icon: Icons.star_half,
              badge: 'شائعة',
            ),
            _buildPackage(
              gems: 250,
              name: 'باقة الحكواتي',
              price: '19.99',
              icon: Icons.star,
            ),
            _buildPackage(
              gems: 500,
              name: 'باقة الأسطورة',
              price: '34.99',
              icon: Icons.auto_awesome,
              highlighted: true,
              badge: 'أفضل قيمة',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPackage({
    required int gems,
    required String name,
    required String price,
    required IconData icon,
    bool highlighted = false,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('سيتم تفعيل الشراء عبر المتاجر الرسمية قريبًا')),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.vibrantOrange.withValues(alpha: 0.08)
                : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? AppColors.vibrantOrange
                  : Colors.white.withValues(alpha: 0.06),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // أيقونة
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: highlighted
                      ? AppColors.vibrantOrange.withValues(alpha: 0.2)
                      : AppColors.primaryDeepPurple.withValues(alpha: 0.3),
                ),
                child: Icon(icon, color: AppColors.vibrantOrange, size: 24),
              ),
              const SizedBox(width: 14),

              // اسم + جواهر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name,
                            style: TextStyle(
                                color: AppColors.glassWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.vibrantOrange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(badge,
                                style: TextStyle(
                                    color: AppColors.deepNight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('$gems',
                            style: TextStyle(
                                color: AppColors.vibrantOrange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 3),
                        Icon(Icons.stars,
                            color: AppColors.vibrantOrange, size: 16),
                      ],
                    ),
                  ],
                ),
              ),

              // سعر + زر
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$$price',
                      style: TextStyle(
                          color: AppColors.glassWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? AppColors.vibrantOrange
                          : AppColors.vibrantOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('شراء',
                        style: TextStyle(
                            color: highlighted
                                ? AppColors.deepNight
                                : AppColors.vibrantOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
