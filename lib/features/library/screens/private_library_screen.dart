import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/application/use_cases/get_private_stories_use_case.dart';

class PrivateLibraryScreen extends StatefulWidget {
  const PrivateLibraryScreen({super.key});

  @override
  State<PrivateLibraryScreen> createState() => _PrivateLibraryScreenState();
}

class _PrivateLibraryScreenState extends State<PrivateLibraryScreen> {
  final _getPrivateStoriesUseCase = GetPrivateStoriesUseCase();
  List<dynamic> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrivateStories();
  }

  Future<void> _fetchPrivateStories() async {
    try {
      final data = await _getPrivateStoriesUseCase.execute();
      if (mounted) {
        setState(() {
          _stories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب القصص: $e')),
        );
      }
    }
  }

  void _onStoryTap(BuildContext context, Map<String, dynamic> savedStory) {
    final dynamic rawScenes = savedStory['scenes_json'];
    
    List<dynamic> parsedScenes = [];
    if (rawScenes is List) {
      parsedScenes = rawScenes;
    } else if (rawScenes is String) {
      try {
        parsedScenes = jsonDecode(rawScenes) as List<dynamic>;
      } catch (e) {
        debugPrint('[Library] خطأ في فك تشفير المشاهد: $e');
      }
    }

    if (parsedScenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً، لا توجد مشاهد محفوظة لهذه القصة.')),
      );
      return;
    }

    final Map<String, dynamic> storyData = {
      'title': savedStory['title'] ?? 'قصة محفوظة',
      'scenes': parsedScenes,
      'coverImage': savedStory['cover_image'] ?? '',
      'id': savedStory['id'],
    };

    GoRouter.of(context).push(
      '/cinema',
      extra: {
        'storyData': storyData,
        'voice': savedStory['voice_type'] ?? 'nova', 
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبتي الخاصة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
          ? const Center(child: Text('لم تصنع أي قصص بعد. ابدأ رحلتك الآن!'))
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
                  onTap: () => _onStoryTap(context, story),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: story['cover_image'] != null && story['cover_image'].toString().isNotEmpty
                              ? Image.network(story['cover_image'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.menu_book, size: 50))
                              : const Icon(Icons.menu_book, size: 50),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            story['title'] ?? 'قصة مجهولة',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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