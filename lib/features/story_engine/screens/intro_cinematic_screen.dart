// === IntroCinematicScreen ===
// شاشة المقدمة والتحميل — (UI فقط)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/application/use_cases/generate_story_use_case.dart';
import 'package:hikayati/application/use_cases/delete_story_use_case.dart';

class IntroCinematicScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final String voice;
  final bool saveToLibrary;

  const IntroCinematicScreen({
    super.key,
    required this.requestData,
    required this.voice,
    this.saveToLibrary = true,
  });

  @override
  State<IntroCinematicScreen> createState() => _IntroCinematicScreenState();
}

class _IntroCinematicScreenState extends State<IntroCinematicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isNavigating = false;

  Map<String, dynamic>? _generatedStoryData;
  String? _generationError;

  bool _isAudioFinished = false;
  bool _isGenerationFinished = false;
  bool _userDismissed = false; // المستخدم ضغط X ولكن التوليد يكمل في الخلفية

  Timer? _progressTimer;
  int _currentStepIndex = 0;
  late List<String> _loadingSteps;

  final _generateStoryUseCase = GenerateStoryUseCase();
  final _deleteStoryUseCase = DeleteStoryUseCase();

  @override
  void initState() {
    super.initState();

    final heroName = widget.requestData['heroName'] ?? 'البطل';
    _loadingSteps = [
      'بدء استدعاء السحر يا $heroName...',
      'جاري بناء حبكة القصة...',
      'جاري رسم المشهد الأول...',
      'تلوين المشهد الثاني...',
      'التقاط تفاصيل المشهد الثالث...',
      'اللمسات الأخـيرة، استعد يا $heroName!',
    ];

    _progressTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          if (_currentStepIndex < _loadingSteps.length - 1) _currentStepIndex++;
        });
      }
    });

    _playMagicAudioAfterDelay();
    _generateStoryInBackground();
  }

  Future<void> _playMagicAudioAfterDelay() async {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isAudioFinished = true);
        _checkAndNavigate();
      }
    });

    await Future.delayed(const Duration(seconds: 4));
    if (!mounted || _isNavigating) return;

    try {
      AudioCache.instance.prefix = '';
      await _audioPlayer.play(AssetSource('صوت كان ياما كان.m4a'));
      AudioCache.instance.prefix = 'assets/';
    } catch (e) {
      debugPrint('[Intro] خطأ في تشغيل الصوت: $e');
      if (mounted) {
        setState(() => _isAudioFinished = true);
        _checkAndNavigate();
      }
    }
  }

  Future<void> _generateStoryInBackground() async {
    try {
      debugPrint('[Intro] تفويض التوليد إلى GenerateStoryUseCase...');
      final storyData = await _generateStoryUseCase.execute(
          widget.requestData,
          voice: widget.voice,
          saveToLibrary: widget.saveToLibrary);

      if (!mounted) return;

      final scenes = storyData['scenes'] as List?;
      if (scenes == null || scenes.isEmpty) {
        _generationError = 'لم يتم توليد مشاهد. يرجى المحاولة مجدداً.';
        _navigateOnError();
        return;
      }

      if (!mounted) return;

      debugPrint('[Intro] استلمت النتيجة من UseCase — عدد المشاهد: ${scenes.length}');

      // Precache images
      if (mounted) {
        try {
          final cover = storyData['cover_url'] ?? storyData['cover_image'] ?? storyData['coverImageUrl'];
          if (cover != null && cover.toString().isNotEmpty) {
            precacheImage(NetworkImage(cover), context);
          }
          for (final scene in scenes) {
            final url = scene['imageUrl'] ?? scene['image_url'];
            if (url != null && url.toString().isNotEmpty) {
              precacheImage(NetworkImage(url), context);
            }
          }
        } catch (e) {
          debugPrint('[Intro] Precache ignore error: $e');
        }
      }

      _generatedStoryData = storyData;
      _isGenerationFinished = true;
      if (mounted) setState(() {});

      // إذا كان المستخدم ضغط X سابقاً → أبلغه بالانتهاء وارجع لصفحة التوليد
      if (_userDismissed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.saveToLibrary ? '✅ تم حفظ القصة في مكتبتك!' : 'تم التوليد للمشاهدة فقط'),
              backgroundColor: widget.saveToLibrary ? Colors.green : Colors.blueGrey,
              duration: const Duration(seconds: 3),
            ),
          );
          context.go('/create-story');
        }
        return;
      }
      _checkAndNavigate();

    } on StoryLimitException catch (e) {
      // ==============================
      // المستخدم تجاوز حد 5 قصص
      // ==============================
      debugPrint('[Intro] ⛔ حد القصص: ${e.currentCount} قصص — سيُعرض dialog الاستبدال');
      if (mounted) {
        _audioPlayer.stop();
        _progressTimer?.cancel();
        await _showStoryLimitDialog(e.existingStories);
      }

    } catch (e) {
      debugPrint('[Intro] خطأ: $e');
      _generationError = 'حدث خطأ: ${e.toString()}';
      if (mounted) _navigateOnError();
    }
  }

  /// dialog: "مكتبتك ممتلئة! هل تريد استبدال إحدى قصصك القديمة بهذه القصة الجديدة؟"
  Future<void> _showStoryLimitDialog(List<dynamic> existingStories) async {
    if (!mounted) return;

    String? selectedStoryId;
    String? selectedStoryTitle;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E3A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('📚', style: TextStyle(fontSize: 28)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مكتبتك ممتلئة!',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'لديك 5 قصص محفوظة. اختر قصة لاستبدالها بقصتك الجديدة:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...existingStories.take(5).map((story) {
                final id = story['id']?.toString() ?? '';
                final title = story['title']?.toString() ?? 'قصة';
                final isSelected = selectedStoryId == id;
                return GestureDetector(
                  onTap: () => setDialogState(() {
                    selectedStoryId = id;
                    selectedStoryTitle = title;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.25)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book,
                            color: isSelected ? AppColors.primary : Colors.white38,
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop('no_save');
              },
              child: const Text('عدم الحفظ', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: selectedStoryId == null
                  ? null
                  : () => Navigator.of(ctx).pop('confirm'),
              child: const Text('✅ استبدال واحفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result == 'no_save' && mounted) {
        // المستخدم اختار عدم الحفظ — ارجع لصفحة التوليد بدون حفظ
        debugPrint('[Intro] ❌ المستخدم اختار عدم الحفظ — الرجوع');
        context.go('/create-story');
        return;
      }
      if (result == 'confirm' && selectedStoryId != null && mounted) {
        // حذف القصة القديمة ثم توليد الجديدة
        try {
          await _deleteStoryUseCase.execute(selectedStoryId!);
          debugPrint('[Intro] ✅ تم حذف القصة القديمة "${selectedStoryTitle}" لفسح المجال');

          if (mounted) {
            // إعادة المحاولة بعد التخلص من القصة القديمة
            setState(() {
              _isGenerationFinished = false;
              _currentStepIndex = 0;
            });
            _progressTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
              if (mounted) {
                setState(() {
                  if (_currentStepIndex < _loadingSteps.length - 1) _currentStepIndex++;
                });
              }
            });
            _generateStoryInBackground();
          }
        } catch (e) {
          debugPrint('[Intro] خطأ في حذف القصة القديمة: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
            );
            context.pop();
          }
        }
      }
    });
  }

  void _checkAndNavigate() {
    if (_isAudioFinished && _isGenerationFinished) {
      _navigateToCinema();
    }
  }

  void _navigateToCinema() {
    if (_isNavigating || _generatedStoryData == null) return;
    _isNavigating = true;
    _audioPlayer.stop();
    if (mounted) {
      context.pushReplacement('/cinema', extra: {
        'storyData': _generatedStoryData!,
        'voice': widget.voice,
      });
    }
  }

  void _navigateOnError() {
    if (_isNavigating) return;
    _isNavigating = true;
    _audioPlayer.stop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_generationError ?? 'خطأ غير متوقع')),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا ضغط المستخدم X نعرض شاشة فارغة والتوليد يكمل في الخلفية
    if (_userDismissed) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            tooltip: 'متابعة الحفظ في الخلفية',
            onPressed: () {
              setState(() => _userDismissed = true);
              _audioPlayer.stop();
              _progressTimer?.cancel();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⏳ يتم الحفظ في الخلفية، ستجد القصة في مكتبتك قريباً'),
                  backgroundColor: Color(0xFF1E1E3A),
                  duration: Duration(seconds: 4),
                ),
              );
              context.go('/create-story');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Color(0xFFFFD700)),
            const SizedBox(height: 20),
            Text(
              _loadingSteps[_currentStepIndex],
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
