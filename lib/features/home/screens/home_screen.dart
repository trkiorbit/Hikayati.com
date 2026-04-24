import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/application/use_cases/auth_use_cases.dart';
import 'package:hikayati/application/use_cases/get_private_stories_use_case.dart';
import 'package:hikayati/application/use_cases/get_public_stories_use_case.dart';
import 'dart:convert';
import 'package:hikayati/core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  int? _credits; // null = loading

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    final userId = _user?.id ?? '';

    if (userId.isNotEmpty) {
      // جلب فوري للرصيد الحقيقي
      _fetchCredits(userId);
      // الاشتراك في التحديثات اللحظية
      Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId)
          .listen((maps) {
        if (maps.isNotEmpty && mounted) {
          setState(() => _credits = maps.first['credits'] as int? ?? 0);
        }
      });
    } else {
      _credits = 0;
    }
  }

  Future<void> _fetchCredits(String userId) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final credits = _credits ?? 0;
    final isLoading = _credits == null;

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('حكواتي',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.vibrantOrange)),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.glassWhite,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.vibrantOrange))
                    : Text(credits.toString(),
                        style: const TextStyle(
                            color: AppColors.vibrantOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                const SizedBox(width: 4),
                const Icon(Icons.stars,
                    color: AppColors.vibrantOrange, size: 28),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, _user, credits),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainBanner(context, credits),
            const SizedBox(height: 20),
            _buildSectionTitle(
                'المكتبة العامة', () => context.push('/public-library')),
            _buildPublicLibraryHorizontalList(),
            const SizedBox(height: 20),
            _buildCreateStoryButton(context),
            const SizedBox(height: 20),
            _buildHeroesAndHakeemSection(context),
            const SizedBox(height: 20),
            _buildSectionTitle(
                'مكتبتي', () => context.push('/private-library')),
            _buildPrivateLibraryHorizontalList(),
            const SizedBox(height: 20),
            _buildSectionTitle('متجر حكواتي', () => context.push('/store')),
            _buildStoreSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user, int credits) {
    return Drawer(
      backgroundColor: AppColors.deepNight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.vibrantOrange.withValues(alpha: 0.15),
                  child: Icon(Icons.person, size: 30, color: AppColors.vibrantOrange),
                ),
                const SizedBox(height: 12),
                Text(user?.email ?? 'مستخدم',
                    style: TextStyle(color: AppColors.glassWhite, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.vibrantOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 16, color: AppColors.vibrantOrange),
                      const SizedBox(width: 4),
                      Text('$credits جوهرة',
                          style: TextStyle(
                              color: AppColors.vibrantOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(Icons.person, 'حسابي', () => context.push('/profile')),
          _drawerItem(Icons.menu_book, 'المكتبة الخاصة', () => context.push('/private-library')),
          _drawerItem(Icons.face, 'اصنع بطلك', () => context.push('/avatar-lab')),
          _drawerItem(Icons.mic, 'استنسخ صوتك', () => context.push('/voice-clone')),
          _drawerItem(Icons.account_balance_wallet, 'شحن الرصيد', () => context.push('/store')),
          _drawerItem(Icons.store, 'متجر حكواتي', () => context.push('/store')),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 16),
          _drawerItem(Icons.privacy_tip, 'سياسة الخصوصية', () => context.push('/privacy-policy')),
          _drawerItem(Icons.gavel, 'الشروط والأحكام', () => context.push('/terms')),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 16),
          _drawerItem(Icons.logout, 'تسجيل الخروج', () async {
            // AuthUseCases.signOut يمسح SharedPreferences (voice/avatar cache)
            await AuthUseCases().signOut();
            if (context.mounted) context.go('/login');
          }, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.vibrantOrange;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(title,
          style: TextStyle(color: color ?? AppColors.glassWhite, fontSize: 14)),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildMainBanner(BuildContext context, int credits) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.appBarBackground,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.stars, color: AppColors.vibrantOrange, size: 40),
            const SizedBox(height: 10),
            Text('اجعل طفلك بطل القصة',
                style: TextStyle(
                    color: AppColors.glassWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('قصص مخصصة، تجربة سينمائية، وذكريات لا تُنسى',
                style: TextStyle(
                    color: AppColors.glassWhite.withValues(alpha: 0.7),
                    fontSize: 14)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMiniIconButton(
                    Icons.person, () => context.push('/profile')),
                _buildMiniIconButton(
                    Icons.face, () => context.push('/avatar-lab')),
                _buildMiniIconButton(
                    Icons.mic, () => context.push('/voice-clone')),
                _buildMiniIconButton(
                    Icons.account_balance_wallet, () => context.push('/store')),
                _buildMiniIconButton(
                    Icons.store, () => context.push('/store')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceColor.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.vibrantOrange, size: 20),
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
            backgroundColor: AppColors.vibrantOrange,
            foregroundColor: AppColors.deepNight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 5,
          ),
          onPressed: () => context.push('/create-story'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 28),
              SizedBox(width: 10),
              Text('أنشئ قصة جديدة',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            subtitle:
                'ارفع صورة ليقوم حكيم بصنع بصمتك البصرية الخاصة للمغامرات!',
            icon: Icons.face,
            onTap: () => context.push('/avatar-lab'),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'استنسخ صوتك',
            subtitle:
                'سجل صوتك ليقرأ التطبيق القصص بصوتك أنت (ميزة خاصة).',
            icon: Icons.record_voice_over,
            onTap: () => context.push('/voice-clone'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.appBarBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.vibrantOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vibrantOrange)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.vibrantOrange.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.vibrantOrange.withValues(alpha: 0.5)),
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
          Text(title,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.glassWhite)),
          TextButton(
            onPressed: onSeeAll,
            child: Text('عرض الكل',
                style: TextStyle(
                    color: AppColors.purpleGlow,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.white24, blurRadius: 6),
                    ])),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicLibraryHorizontalList() {
    return FutureBuilder<List<dynamic>>(
      future: GetPublicStoriesUseCase().execute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180,
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.vibrantOrange)),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
              height: 180,
              child: Center(child: Text('حدث خطأ في جلب القصص')));
        }

        final stories = snapshot.data ?? [];
        if (stories.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('المكتبة العامة فارغة حاليًا.',
                  style: TextStyle(
                      color: AppColors.glassWhite,
                      fontWeight: FontWeight.bold)),
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

              String coverUrl = story['cover']?.toString() ??
                  story['cover_image']?.toString() ??
                  '';
              if (coverUrl.isEmpty) {
                final dynamic rawScenes = story['scenes_json'];
                List<dynamic> parsedScenes = [];
                if (rawScenes is List) {
                  parsedScenes = rawScenes;
                } else if (rawScenes is String) {
                  try {
                    parsedScenes = jsonDecode(rawScenes) as List<dynamic>;
                  } catch (_) {}
                }
                if (parsedScenes.isNotEmpty &&
                    parsedScenes[0] is Map &&
                    parsedScenes[0]['imageUrl'] != null) {
                  coverUrl = parsedScenes[0]['imageUrl'].toString();
                }
              }

              final price = story['price_credits'] ?? 5;

              return Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (coverUrl.isNotEmpty)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10)),
                          child: Image.network(coverUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (ctx, err, stack) => Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: AppColors.vibrantOrange)),
                        ),
                      )
                    else
                      Expanded(
                          child: Center(
                              child: Icon(Icons.menu_book,
                                  size: 50,
                                  color: AppColors.vibrantOrange))),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Column(
                        children: [
                          Text(story['title'] ?? 'قصة',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('$price جوهرة',
                              style: TextStyle(
                                  color: AppColors.purpleGlow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.white24, blurRadius: 4)])),
                        ],
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

  Widget _buildPrivateLibraryHorizontalList() {
    return FutureBuilder<List<dynamic>>(
      future: GetPrivateStoriesUseCase().execute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180,
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.vibrantOrange)),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
              height: 180,
              child: Center(child: Text('حدث خطأ في جلب مكتبتك')));
        }

        final stories = snapshot.data ?? [];
        if (stories.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('لم تصنع قصصًا بعد! ابدأ مغامرتك الآن.',
                  style: TextStyle(
                      color: AppColors.glassWhite,
                      fontWeight: FontWeight.bold)),
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
                  color: AppColors.vibrantOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.vibrantOrange, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (story['cover_image'] != null &&
                        story['cover_image'].toString().isNotEmpty)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10)),
                          child: Image.network(story['cover_image'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (ctx, err, stack) => Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: AppColors.vibrantOrange)),
                        ),
                      )
                    else
                      Expanded(
                          child: Center(
                              child: Icon(Icons.menu_book,
                                  size: 50,
                                  color: AppColors.vibrantOrange))),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(story['title'] ?? 'قصة',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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

  Widget _buildStoreSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () => context.push('/store'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.primaryDeepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primaryDeepPurple.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_bag,
                  size: 50, color: AppColors.vibrantOrange),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حوّل القصة إلى كتاب',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.glassWhite)),
                    Text('اطبع قصة طفلك ككتيب أو تيشيرت!',
                        style: TextStyle(
                            color:
                                AppColors.glassWhite.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.glassWhite.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
