import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // الألوان الرسمية من الهوية البصرية
  static const Color primaryPurple = Color(0xFF6A0DAD);
  static const Color warmGold = Color(0xFFFFD700);
  static const Color deepBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. شريط علوي
      appBar: AppBar(
        title: const Text('حكواتي', style: TextStyle(fontWeight: FontWeight.bold, color: warmGold)),
        backgroundColor: deepBlack,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الإعدادات')));
            },
          ),
        ],
      ),
      // 7. روابط الحساب والسياسات (القائمة الجانبية)
      drawer: _buildDrawer(context, user),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. بانر رئيسي
            _buildMainBanner(context),
            
            const SizedBox(height: 20),
            
            // 3. قسم القصص العامة
            _buildSectionTitle('المكتبة العامة', () => context.push('/public-library')),
            _buildHorizontalStoryList(),
            
            const SizedBox(height: 20),
            
            // 4. زر إنشاء قصة
            _buildCreateStoryButton(context),
            
            const SizedBox(height: 20),
            
            // 5. قسم القصص المميزة
            _buildSectionTitle('قصص مميزة', () {}),
            _buildHorizontalStoryList(isFeatured: true),
            
            const SizedBox(height: 20),
            
            // 6. قسم المتجر
            _buildSectionTitle('متجر حكواتي', () {}),
            _buildStoreSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- بناء أجزاء الشاشة حسب الدستور ---

  Widget _buildDrawer(BuildContext context, User? user) {
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
                const Text('الرصيد: 100 كريدت', style: TextStyle(color: warmGold, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: primaryPurple),
            title: const Text('المكتبة الخاصة'),
            onTap: () => context.push('/private-library'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: primaryPurple),
            title: const Text('سياسة الخصوصية'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description, color: primaryPurple),
            title: const Text('شروط الاستخدام'),
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

  Widget _buildMainBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, deepBlack],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, color: warmGold, size: 40),
          SizedBox(height: 10),
          Text(
            'اجعل طفلك بطل القصة',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'قصص مخصصة، تجربة سينمائية، وذكريات لا تُنسى',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
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
