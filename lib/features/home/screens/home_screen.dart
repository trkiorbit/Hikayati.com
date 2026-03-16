import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/auth/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حكايتي'), // Hikayati in Arabic
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF6A0DAD)),
              child: Text(
                'حكايتي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('المكتبة الخاصة'),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                context.push('/private_library');
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('متجر حكواتي (رصيد)'),
              onTap: () {
                Navigator.pop(context);
                // Future Store Implementation conforming to Apple/Google guidelines
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سيتم توجيهك للمتجر قريباً...')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('سياسة الخصوصية'),
              onTap: () {
                Navigator.pop(context);
                context.push('/privacy_policy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('شروط الاستخدام'),
              onTap: () {
                Navigator.pop(context);
                context.push('/terms_of_service');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'استكشف أروع القصص!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book),
              onPressed: () {
                context.push('/public_library');
              },
              label: const Text('المكتبة العامة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/story_creation');
              },
              label: const Text('اصنع قصة جديدة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open Hakim AI Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حكيم في وضع الاستراحة حالياً!')),
          );
        },
        backgroundColor: const Color(0xFFFFD700), // Gold
        tooltip: 'اسأل حكيم',
        child: const Icon(Icons.auto_awesome, color: Colors.black),
      ),
    );
  }
}
