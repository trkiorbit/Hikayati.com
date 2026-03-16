import 'package:flutter/material.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:hikayati/core/theme/app_colors.dart';

class PublicLibraryScreen extends StatefulWidget {
  const PublicLibraryScreen({super.key});

  @override
  State<PublicLibraryScreen> createState() => _PublicLibraryScreenState();
}

class _PublicLibraryScreenState extends State<PublicLibraryScreen> {
  final _client = SupabaseService.client;
  List<dynamic> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPublicStories();
  }

  Future<void> _fetchPublicStories() async {
    try {
      final data = await _client
          .from('public_stories')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _stories = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _purchaseAndReadStory(Map<String, dynamic> story) async {
    final price = story['price_credits'] as int;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فتح القصة'),
        content: Text(
          'هل تريد فتح قصة "${story['title']}" مقابل $price جواهر؟',
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('نعم، افتحها'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      // Show loading indicator in dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Deduct Credits
      await SupabaseService.deductCredits(
        price,
        'Purchase public story: ${story['id']}',
      );

      // Record Purchase (Optional depending on how you structure access)
      await _client.from('purchases').insert({
        'user_id': _client.auth.currentUser!.id,
        'story_id': story['id'],
        'unlock_type': 'access',
        'credits_paid': price,
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح القصة بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Play story in cinema
        // context.push('/cinema', extra: story);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة العامة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
          ? const Center(child: Text('لا توجد قصص عامة حالياً.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                return InkWell(
                  onTap: () => _purchaseAndReadStory(story),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: story['cover'] != null
                              ? Image.network(story['cover'], fit: BoxFit.cover)
                              : Container(
                                  color: AppColors.primary,
                                  child: const Icon(
                                    Icons.menu_book,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                story['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.diamond,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${story['price_credits'] ?? 10} جواهر'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
