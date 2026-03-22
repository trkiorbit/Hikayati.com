import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/application/use_cases/get_public_stories_use_case.dart';
import 'package:hikayati/application/use_cases/unlock_public_story_use_case.dart';

class PublicLibraryScreen extends StatefulWidget {
  const PublicLibraryScreen({super.key});

  @override
  State<PublicLibraryScreen> createState() => _PublicLibraryScreenState();
}

class _PublicLibraryScreenState extends State<PublicLibraryScreen> {
  final _getPublicStoriesUseCase = GetPublicStoriesUseCase();
  final _unlockPublicStoryUseCase = UnlockPublicStoryUseCase();
  
  List<dynamic> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPublicStories();
  }

  Future<void> _fetchPublicStories() async {
    try {
      final data = await _getPublicStoriesUseCase.execute();

      if (mounted) {
        setState(() {
          _stories = data;
          _isLoading = false;
        });
      }
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
      await _unlockPublicStoryUseCase.execute(story);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح القصة بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Play story in cinema
        context.push('/cinema', extra: {'storyData': story, 'voice': 'alloy'});
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
