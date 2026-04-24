import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';
import 'package:hikayati/features/library/services/library_service.dart';
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
  final _libraryService = LibraryService();

  List<dynamic> _stories = [];
  Set<String> _unlockedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final stories = await _getPublicStoriesUseCase.execute();
      final unlockedList = await _libraryService.getUnlockedPublicStories();
      
      if (mounted) {
        setState(() {
          _stories = stories;
          _unlockedIds = unlockedList.toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب القصص العامة: $e')),
        );
      }
    }
  }

  void _openStory(Map<String, dynamic> story) {
    final dynamic rawScenes = story['scenes_json'];
    List<dynamic> parsedScenes = [];
    if (rawScenes is List) {
      parsedScenes = rawScenes;
    } else if (rawScenes is String) {
      try { parsedScenes = jsonDecode(rawScenes) as List<dynamic>; } catch (_) {}
    }

    if (parsedScenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('محتوى هذه القصة غير متوفر حالياً.')),
      );
      return;
    }

    context.push('/cinema', extra: {
      'storyData': {
        'title': story['title'] ?? 'قصة عامة',
        'scenes': parsedScenes,
        'coverImage': story['cover'] ?? '',
        'id': story['id'],
      },
      'voice': story['voice_type'] ?? 'alloy',
      'fromLibrary': true, // العودة ستكون للمكتبة
    });
  }

  Future<void> _purchaseAndReadStory(Map<String, dynamic> story) async {
    final price = story['price_credits'] as int;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('💎 فتح القصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'سيتم خصم $price أرصدة لفتح قصة "${story['title']}".\nستبقى القصة مفتوحة لك دائماً.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('نعم، افتحها', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await _unlockPublicStoryUseCase.execute(story);

      if (mounted) {
        setState(() {
          _unlockedIds.add(story['id'].toString());
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم فتح القصة بنجاح! استمتع بقراءتها.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // فتح القصة فوراً بعد الشراء
        _openStory(story);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleStoryTap(Map<String, dynamic> story) {
    if (_unlockedIds.contains(story['id'].toString())) {
      _openStory(story);
    } else {
      _purchaseAndReadStory(story);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('🌍 المكتبة العامة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [CreditsBadge()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _stories.isEmpty
              ? _buildEmpty()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _stories.length,
                  itemBuilder: (context, index) {
                    final story = _stories[index] as Map<String, dynamic>;
                    return _buildStoryCard(story);
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 72, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('المكتبة العامة فارغة حالياً',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final id = story['id']?.toString() ?? '';
    String coverUrl = story['cover']?.toString() ?? story['cover_image']?.toString() ?? '';
    final title = story['title']?.toString() ?? 'قصة';
    final price = story['price_credits'] ?? 5;
    final isUnlocked = _unlockedIds.contains(id);

    // إذا لم تكن هناك صورة غلاف صريحة، حاول جلبها من المشهد الأول
    if (coverUrl.isEmpty) {
      final dynamic rawScenes = story['scenes_json'];
      List<dynamic> parsedScenes = [];
      if (rawScenes is List) {
        parsedScenes = rawScenes;
      } else if (rawScenes is String) {
        try { parsedScenes = jsonDecode(rawScenes) as List<dynamic>; } catch (_) {}
      }
      
      if (parsedScenes.isNotEmpty && parsedScenes[0] is Map && parsedScenes[0]['imageUrl'] != null) {
        coverUrl = parsedScenes[0]['imageUrl'].toString();
      }
    }


    return GestureDetector(
      onTap: () => _handleStoryTap(story),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // صورة الغلاف (مظللة إذا كانت مقفلة)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: isUnlocked 
                    ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) 
                    : ImageFilter.blur(sigmaX: 5, sigmaY: 5), // تظليل للقصص المقفلة
                child: coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),
            
            // لون داكن خفيف فوق الصورة
            Positioned.fill(
              child: Container(
                color: isUnlocked ? Colors.black26 : Colors.black54,
              ),
            ),

            // تدرج للنص بالأسفل
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // أيقونة الوسط (مقفلة/مفتوحة)
            Center(
              child: Container(
                padding: EdgeInsets.all(isUnlocked ? 16 : 12),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? AppColors.primary.withValues(alpha: 0.88)
                      : Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: isUnlocked ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ] : null,
                ),
                child: Icon(
                  isUnlocked ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: isUnlocked ? 36 : 28,
                ),
              ),
            ),

            // بطاقة السعر أو علامة (مفتوح) بالأعلى
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.green.withValues(alpha: 0.9) : const Color(0xFF1E1E3A).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isUnlocked ? Colors.greenAccent : AppColors.primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUnlocked) const Icon(Icons.diamond, color: AppColors.primary, size: 14),
                    if (!isUnlocked) const SizedBox(width: 4),
                    Text(
                      isUnlocked ? 'مفتوح' : '$price',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF252540),
      child: const Center(
        child: Icon(Icons.auto_stories, color: Colors.white24, size: 48),
      ),
    );
  }
}
