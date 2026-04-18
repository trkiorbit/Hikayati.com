import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/library/services/library_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String _email = '';
  int _credits = 0;
  bool _hasAvatar = false;
  bool _hasVoice = false;
  int _storyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _email = user.email ?? '';

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('credits, avatar_profile_summary')
          .eq('user_id', user.id)
          .maybeSingle();

      if (res != null) {
        _credits = res['credits'] as int? ?? 0;
        _hasAvatar = res['avatar_profile_summary'] != null;
      }

      final prefs = await SharedPreferences.getInstance();
      _hasVoice = prefs.getString('cloned_voice_id') != null;

      _storyCount = await LibraryService().getStoryCount();
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _requestDataDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('تأكيد حذف البيانات',
            style: TextStyle(color: AppColors.glassWhite)),
        content: const Text(
          'سيتم حذف جميع بياناتك بما في ذلك القصص والأفاتار والصوت المستنسخ. هذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(color: AppColors.glassWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف نهائي',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'تم إرسال طلب حذف البيانات. سيتم التنفيذ خلال 48 ساعة.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('حسابي'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.glassWhite,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.vibrantOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- بطاقة المستخدم ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primaryDeepPurple,
                          child: Icon(Icons.person,
                              size: 40, color: AppColors.vibrantOrange),
                        ),
                        const SizedBox(height: 12),
                        Text(_email,
                            style: TextStyle(
                                color: AppColors.glassWhite, fontSize: 16)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.vibrantOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars,
                                  color: AppColors.vibrantOrange, size: 24),
                              const SizedBox(width: 8),
                              Text('$_credits جوهرة',
                                  style: TextStyle(
                                      color: AppColors.vibrantOrange,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- حالة الميزات ---
                  _buildStatusTile(
                    icon: Icons.face,
                    title: 'الأفاتار',
                    value: _hasAvatar ? 'محفوظ' : 'لم يُنشأ بعد',
                    active: _hasAvatar,
                  ),
                  _buildStatusTile(
                    icon: Icons.mic,
                    title: 'الصوت المستنسخ',
                    value: _hasVoice ? 'محفوظ' : 'لم يُنشأ بعد',
                    active: _hasVoice,
                  ),
                  _buildStatusTile(
                    icon: Icons.menu_book,
                    title: 'القصص المحفوظة',
                    value: '$_storyCount من 10',
                    active: _storyCount > 0,
                  ),

                  const SizedBox(height: 20),

                  // --- الإجراءات ---
                  _buildActionTile(
                    icon: Icons.account_balance_wallet,
                    title: 'شحن الرصيد',
                    onTap: () => context.push('/store'),
                  ),
                  _buildActionTile(
                    icon: Icons.privacy_tip,
                    title: 'سياسة الخصوصية',
                    onTap: () => context.push('/privacy-policy'),
                  ),
                  _buildActionTile(
                    icon: Icons.gavel,
                    title: 'الشروط والأحكام',
                    onTap: () => context.push('/terms'),
                  ),
                  _buildActionTile(
                    icon: Icons.description,
                    title: 'سياسة المحتوى والملكية',
                    onTap: () => context.push('/content-policy'),
                  ),
                  _buildActionTile(
                    icon: Icons.delete_forever,
                    title: 'طلب حذف البيانات',
                    onTap: _requestDataDeletion,
                    color: AppColors.error,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: Icon(Icons.logout, color: AppColors.error),
                      label: Text('تسجيل الخروج',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required String title,
    required String value,
    required bool active,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: active ? AppColors.success : AppColors.glassWhite,
              size: 24),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: AppColors.glassWhite, fontSize: 15)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: active ? AppColors.success : AppColors.glassWhite,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.glassWhite;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: c),
        title: Text(title, style: TextStyle(color: c)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: c),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppColors.cardSurface,
      ),
    );
  }
}
