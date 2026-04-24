import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/application/use_cases/get_private_stories_use_case.dart';
import 'package:hikayati/application/use_cases/delete_story_use_case.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';

class PrivateLibraryScreen extends StatefulWidget {
  const PrivateLibraryScreen({super.key});

  @override
  State<PrivateLibraryScreen> createState() => _PrivateLibraryScreenState();
}

class _PrivateLibraryScreenState extends State<PrivateLibraryScreen> {
  final _getPrivateStoriesUseCase = GetPrivateStoriesUseCase();
  final _deleteStoryUseCase = DeleteStoryUseCase();

  List<dynamic> _stories = [];
  bool _isLoading = true;

  // وضع الحذف المتعدد
  bool _isDeleteMode = false;
  final Set<String> _selectedIds = {};

  static const int maxStories = 10;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      final data = await _getPrivateStoriesUseCase.execute();
      if (mounted) setState(() { _stories = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب القصص: $e')),
        );
      }
    }
  }

  void _openStory(Map<String, dynamic> savedStory) {
    if (_isDeleteMode) {
      _toggleSelect(savedStory['id'].toString());
      return;
    }

    final dynamic rawScenes = savedStory['scenes_json'];
    List<dynamic> parsedScenes = [];
    if (rawScenes is List) {
      parsedScenes = rawScenes;
    } else if (rawScenes is String) {
      try { parsedScenes = jsonDecode(rawScenes) as List<dynamic>; } catch (_) {}
    }

    if (parsedScenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً، لا توجد مشاهد محفوظة لهذه القصة.')),
      );
      return;
    }

    GoRouter.of(context).push('/cinema', extra: {
      'storyData': {
        'title': savedStory['title'] ?? 'قصة محفوظة',
        'scenes': parsedScenes,
        'coverImage': savedStory['cover_image'] ?? '',
        'id': savedStory['id'],
      },
      'voice': savedStory['voice_type'] ?? 'nova',
      'fromLibrary': true,
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _selectedIds.clear();
    });
  }

  void _exitDeleteMode() {
    setState(() {
      _isDeleteMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم تختر أي قصة')),
      );
      return;
    }

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'سيتم حذف $count ${count == 1 ? 'قصة' : 'قصص'} نهائياً. هل تريد المتابعة؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    int deleted = 0;
    for (final id in List<String>.from(_selectedIds)) {
      try {
        await _deleteStoryUseCase.execute(id);
        deleted++;
      } catch (e) {
        debugPrint('[Library] خطأ حذف $id: $e');
      }
    }

    if (mounted) {
      setState(() {
        _stories.removeWhere((s) => _selectedIds.contains(s['id']?.toString()));
        _isDeleteMode = false;
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ تم حذف $deleted قصة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E1E3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: _isDeleteMode
            ? Text(
                'تحديد للحذف (${_selectedIds.length} محدد)',
                style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              )
            : const Text('📚 مكتبتي الخاصة',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _isDeleteMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitDeleteMode,
              )
            : null,
        actions: _isDeleteMode
            ? [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _stories.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_stories.map((s) => s['id'].toString()));
                      }
                    });
                  },
                  child: const Text('تحديد الكل', style: TextStyle(color: Colors.white70)),
                ),
              ]
            : const [CreditsBadge()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // ===== شريط العداد =====
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.collections_bookmark, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'القصص: ${_stories.length} / $maxStories',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _stories.isEmpty ? 0 : _stories.length / maxStories,
                            backgroundColor: Colors.white12,
                            color: _stories.length >= maxStories ? Colors.orange : AppColors.primary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== أزرار الأكشن (أعلى المكتبة) =====
                if (!_isDeleteMode) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildActionBtn(
                          icon: Icons.delete_sweep_rounded,
                          label: 'حذف',
                          color: Colors.red,
                          onTap: _stories.isEmpty ? null : _enterDeleteMode,
                        ),
                        const SizedBox(width: 10),
                        _buildActionBtn(
                          icon: Icons.menu_book_rounded,
                          label: 'طباعة كتيب',
                          color: const Color(0xFF4CAF50),
                          onTap: () => _showComingSoon('📖 قريباً: طلب كتيب القصة المطبوع!'),
                        ),
                        const SizedBox(width: 10),
                        _buildActionBtn(
                          icon: Icons.checkroom_rounded,
                          label: 'تيشيرت البطل',
                          color: const Color(0xFFFF9800),
                          onTap: () => _showComingSoon('👕 قريباً: طلب تيشيرت بطل قصتك!'),
                        ),
                      ],
                    ),
                  ),
                ],

                // ===== زر تأكيد الحذف في وضع الحذف =====
                if (_isDeleteMode) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedIds.isEmpty ? Colors.grey : Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.delete_forever, color: Colors.white),
                        label: Text(
                          _selectedIds.isEmpty
                              ? 'اختر القصص المراد حذفها'
                              : 'حذف ${_selectedIds.length} قصة',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // ===== الشبكة =====
                Expanded(
                  child: _stories.isEmpty
                      ? _buildEmpty()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _stories.length,
                          itemBuilder: (context, index) =>
                              _buildStoryCard(_stories[index] as Map<String, dynamic>),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 72, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('مكتبتك فارغة',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('ابدأ برحلتك وصنع قصتك الأولى!',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final id = story['id']?.toString() ?? '';
    final coverUrl = story['cover_image']?.toString() ?? '';
    final title = story['title']?.toString() ?? 'قصة';
    final isSelected = _selectedIds.contains(id);

    return GestureDetector(
      onTap: () => _openStory(story),
      onLongPress: () {
        if (!_isDeleteMode) _enterDeleteMode();
        _toggleSelect(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: Colors.red, width: 3)
              : Border.all(color: Colors.transparent),
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
            // ===== صورة الغلاف =====
            Positioned.fill(
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),

            // ===== تدرج للنص =====
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.92),
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

            // ===== زر التشغيل المركزي (أكبر بكثير) =====
            if (!_isDeleteMode)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              ),

            // ===== علامة التحديد (وضع الحذف) =====
            if (_isDeleteMode)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isSelected ? Colors.red : Colors.white54, width: 2.5),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.radio_button_unchecked,
                    color: Colors.white,
                    size: 36,
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