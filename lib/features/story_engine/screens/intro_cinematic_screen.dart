// === IntroCinematicScreen ===
// شاشة المقدمة والتحميل — (UI فقط)
// التوليد يحصل هنا عبر GenerateStoryUseCase
// لا يوجد StoryLimitException — الحد يُفحص في StoryCreationScreen قبل الوصول هنا

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hikayati/application/use_cases/generate_story_use_case.dart';

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

  Timer? _progressTimer;
  int _currentStepIndex = 0;
  late List<String> _loadingSteps;

  final _generateStoryUseCase = GenerateStoryUseCase();

  // ===== موقّت الأداء =====
  late DateTime _generationStart;

  @override
  void initState() {
    super.initState();
    _generationStart = DateTime.now();

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
      _checkAndNavigate();

    } catch (e) {
      debugPrint('[Intro] خطأ: $e');
      _generationError = 'حدث خطأ: ${e.toString()}';
      if (mounted) _navigateOnError();
    }
  }

  void _checkAndNavigate() {
    if (_isAudioFinished && _isGenerationFinished) {
      _navigateToCinema();
    }
  }

  void _navigateToCinema() {
    if (_isNavigating || _generatedStoryData == null) return;
    _isNavigating = true;

    // ===== قياس وقت التوليد الكامل =====
    final totalMs = DateTime.now().difference(_generationStart).inMilliseconds;
    final totalSec = (totalMs / 1000).toStringAsFixed(1);
    debugPrint('');
    debugPrint('╔══════════════════════════════════════╗');
    debugPrint('║  ⏱️  وقت التوليد الكامل: ${totalSec}s   ║');
    debugPrint('╚══════════════════════════════════════╝');
    debugPrint('');

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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            tooltip: 'العودة',
            onPressed: () {
              _audioPlayer.stop();
              _progressTimer?.cancel();
              if (mounted) context.pop();
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
