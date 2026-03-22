import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/application/use_cases/get_private_stories_use_case.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // الألوان الرسمية من الهوية البصرية
  static const Color primaryPurple = Color(0xFF6A0DAD);
  static const Color warmGold = Color(0xFFFFD700);
  static const Color deepBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '';

    final creditsStream = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((maps) => maps.isNotEmpty ? (maps.first['credits'] as int? ?? 0) : 0);

    return StreamBuilder<int>(
      stream: creditsStream,
      initialData: 0,
      builder: (context, snapshot) {
        final credits = snapshot.data ?? 0;

        return Scaffold(
          backgroundColor: Colors.white,
          // 1. شريط علوي
          appBar: AppBar(
            title: const Text('حكواتي', style: TextStyle(fontWeight: FontWeight.bold, color: warmGold)),
            backgroundColor: deepBlack,
            foregroundColor: Colors.white,
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(credits.toString(), style: const TextStyle(color: warmGold, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 4),
                    const Icon(Icons.stars, color: warmGold, size: 28),
                  ],
                ),
              ),
            ],
          ),
          // 7. روابط الحساب والسياسات (القائمة الجانبية)
          drawer: _buildDrawer(context, user, credits),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. بانر رئيسي
                _buildMainBanner(context, credits),
            
            const SizedBox(height: 20),
            
            // 3. قسم القصص العامة
            _buildSectionTitle('المكتبة العامة', () => context.push('/public-library')),
            _buildHorizontalStoryList(),
            
            const SizedBox(height: 20),
            
            // 4. زر إنشاء قصة
            _buildCreateStoryButton(context),
            
            const SizedBox(height: 20),
            
            // 5. قسم بناء الأبطال وحكيم
            _buildHeroesAndHakeemSection(context),

            const SizedBox(height: 20),
            
            // 6. قسم مكتبتي (مكان القصص المميزة سابقاً)
            _buildSectionTitle('مكتبتي', () => context.push('/private-library')),
            _buildPrivateLibraryHorizontalList(),
            
            const SizedBox(height: 20),
            
            // 6. قسم المتجر
            _buildSectionTitle('متجر حكواتي', () {}),
            _buildStoreSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  });
  }

  // --- بناء أجزاء الشاشة حسب الدستور ---

  Widget _buildDrawer(BuildContext context, User? user, int credits) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: deepBlack),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.account_circle, size: 50, color: warmGold),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'مستخدم',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text('الرصيد: $credits كريدت', style: const TextStyle(color: warmGold, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: primaryPurple),
            title: const Text('المكتبة الخاصة'),
            onTap: () => context.push('/private-library'),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: primaryPurple),
            title: const Text('اصنع بطلك'),
            onTap: () => context.push('/avatar-lab'),
          ),
          ListTile(
            leading: const Icon(Icons.mic, color: primaryPurple),
            title: const Text('اروي القصة بصوتك'),
            onTap: () => context.push('/voice-clone'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: primaryPurple),
            title: const Text('الشحن'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('واجهة الشراء قريباً!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.store, color: primaryPurple),
            title: const Text('المتجر'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('المتجر الملموس قريباً!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: primaryPurple),
            title: const Text('سياسة الخصوصية'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainBanner(BuildContext context, int credits) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: deepBlack, // خلفية سوداء ليتناسق مع الهوية
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // يبدأ من اليمين في RTL
          children: [
            const Icon(Icons.stars, color: warmGold, size: 40),
            const SizedBox(height: 10),
            const Text(
              'اجعل طفلك بطل القصة',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'قصص مخصصة، تجربة سينمائية، وذكريات لا تُنسى',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // أيقونات صغيرة سريعة (فعالة)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMiniIconButton(Icons.person, () => _showTopSnackBar(context, 'صفحة الملف الشخصي')),
                _buildMiniIconButton(Icons.face, () => context.push('/avatar-lab')),
                _buildMiniIconButton(Icons.mic, () => context.push('/voice-clone')),
                _buildMiniIconButton(Icons.account_balance_wallet, () => _showTopSnackBar(context, 'إعادة الشحن (الكريدت الحالي: $credits)')),
                _buildMiniIconButton(Icons.store, () => _showTopSnackBar(context, 'متجر حكواتي')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTopSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMiniIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white.withOpacity(0.1),
        child: Icon(icon, color: warmGold, size: 20),
      ),
    );
  }

  Widget _buildCreateStoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: warmGold,
            foregroundColor: deepBlack,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 5,
          ),
          onPressed: () => context.push('/create-story'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 28),
              SizedBox(width: 10),
              Text('أنشئ قصة جديدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroesAndHakeemSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildActionCard(
            context,
            title: 'اصنع بطلك',
            subtitle: 'ارفع صورة ليقوم حكيم بصنع بصمتك البصرية الخاصة للمغامرات!',
            icon: Icons.face,
            bgColor: deepBlack,
            textColor: warmGold,
            outlineColor: Colors.transparent,
            onTap: () => context.push('/avatar-lab'),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'المستشار حكيم',
            subtitle: 'تحدث مع حكيم للحصول على أفكار قصص أو مساعدة في التطبيق.',
            icon: Icons.psychology,
            bgColor: deepBlack,
            textColor: warmGold,
            outlineColor: Colors.transparent,
            onTap: () => context.push('/hakeem'),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'استنسخ صوتك',
            subtitle: 'سجل صوتك ليقرأ التطبيق القصص بصوتك أنت (ميزة خاصة).',
            icon: Icons.record_voice_over,
            bgColor: deepBlack,
            textColor: warmGold,
            outlineColor: Colors.transparent,
            onTap: () => context.push('/voice-clone'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color outlineColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: textColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: deepBlack)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('عرض الكل', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStoryList({bool isFeatured = false}) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 130,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: isFeatured ? warmGold.withOpacity(0.2) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: isFeatured ? Border.all(color: warmGold, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 50, color: isFeatured ? primaryPurple : Colors.grey),
                const SizedBox(height: 10),
                Text('قصة ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (!isFeatured) const Text('10 كريدت', style: TextStyle(color: primaryPurple, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivateLibraryHorizontalList() {
    return FutureBuilder<List<dynamic>>(
      future: GetPrivateStoriesUseCase().execute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: primaryPurple)),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox(
            height: 180,
            child: Center(child: Text('حدث خطأ في جلب مكتبتك')),
          );
        }
        
        final stories = snapshot.data ?? [];
        if (stories.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'لم تصنع قصصاً بعد! ابدأ مغامرتك الآن.',
                style: TextStyle(color: deepBlack, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: warmGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warmGold, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (story['cover_image'] != null && story['cover_image'].toString().isNotEmpty)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: Image.network(
                            story['cover_image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported, size: 50, color: primaryPurple),
                          ),
                        ),
                      )
                    else
                      const Expanded(child: Center(child: Icon(Icons.menu_book, size: 50, color: primaryPurple))),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        story['title'] ?? 'قصة مجهولة',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStoreSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryPurple.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.shopping_bag, size: 50, color: primaryPurple),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حوّل القصة إلى كتاب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepBlack)),
                  Text('اطبع قصة طفلك ككتيب أو تيشيرت!', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
