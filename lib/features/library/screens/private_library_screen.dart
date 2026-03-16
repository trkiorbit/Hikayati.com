import 'package:flutter/material.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:hikayati/core/theme/app_colors.dart';

class PrivateLibraryScreen extends StatefulWidget {
  const PrivateLibraryScreen({super.key});

  @override
  State<PrivateLibraryScreen> createState() => _PrivateLibraryScreenState();
}

class _PrivateLibraryScreenState extends State<PrivateLibraryScreen> {
  final _client = SupabaseService.client;
  List<dynamic> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _client
          .from('stories')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _stories = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المكتبة: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبتي الخاصة'),
        leading: Icon(Icons.lock, color: AppColors.secondary), // Golden lock
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
          ? const Center(child: Text('لم تصنع أي قصص بعد. ابدأ المغامرة!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                return Card(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(Icons.menu_book, color: AppColors.secondary),
                    title: Text(
                      story['title'] ?? 'قصة بدون عنوان',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      story['created_at'].toString().split('T')[0],
                    ),
                    trailing: Icon(
                      Icons.play_circle_fill,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      // Open in CinemaScreen (passing story data to be played)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'سيتم تشغيل القصة في شاشة السينما قريباً',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
