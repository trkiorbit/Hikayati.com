/// === IntroCinematicScreen ===
/// شاشة المقدمة والتحميل — (UI فقط)
///
/// مسؤولية هذه الشاشة:
/// 1. عرض تجربة تحميل بصرية وصوتية أثناء انتظار التوليد
/// 2. تشغيل صوت المقدمة
/// 3. استلام النتيجة من GenerateStoryUseCase والانتقال إلى CinemaScreen
///
/// ما لا يجوز لهذه الشاشة فعله (LAW 1 — HIKAYATI_AGENT_MASTER_SPEC.md):
/// - استدعاء UnifiedEngine مباشرة
/// - احتواء منطق توليد القصة

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/application/use_cases/generate_story_use_case.dart';

class IntroCinematicScreen extends StatefulWidget {
  /// بيانات الطلب لتوليد القصة (اسم البطل، عمره، الأسلوب...)
  final Map<String, dynamic> requestData;
  final String voice;

  const IntroCinematicScreen({
    super.key,
    required this.requestData,
    required this.voice,
  });

  @override
  State<IntroCinematicScreen> createState() => _IntroCinematicScreenState();
}

class _IntroCinematicScreenState extends State<IntroCinematicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isNavigating = false;

  // مسار التوليد
  Map<String, dynamic>? _generatedStoryData;
  String? _generationError;

  bool _isAudioFinished = false;
  bool _isGenerationFinished = false;

  // مؤقت نصوص التقدم الزمني
  Timer? _progressTimer;
  int _currentStepIndex = 0;
  late List<String> _loadingSteps;

  // إضافة وقت البدء لضمان الحد الأدنى قبل الانتقال
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    final heroName = widget.requestData['heroName'] ?? 'البطل';
    _loadingSteps = [
      'بدء استدعاء السحر يا $heroName...',
      'جاري بناء حبكة القصة...',
      'جاري رسم المشهد الأول...',
      'تلوين المشهد الثاني...',
      'التقاط تفاصيل المشهد الثالث...',
      'اللمسات الأخـيرة، استعد يا $heroName!',
    ];

    // تبديل النص كل ثانية ونصف
    _progressTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          if (_currentStepIndex < _loadingSteps.length - 1) {
            _currentStepIndex++;
          }
        });
      }
    });

    // تشغيل التأثير الصوتي بعد مرور 4 ثوانٍ
    _playMagicAudioAfterDelay();

    // تشغيل التوليد
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
      // إزالة مسار الأصول الافتراضي للوصول لملف الجذر كما طلب المستخدم
      AudioCache.instance.prefix = '';
      await _audioPlayer.play(AssetSource('صوت كان ياما كان.m4a'));
      AudioCache.instance.prefix = 'assets/'; // إعادته للوضع الطبيعي
    } catch (e) {
      debugPrint('[Intro] خطأ في تشغيل الصوت: $e');
      if (mounted) {
        setState(() => _isAudioFinished = true);
        _checkAndNavigate();
      }
    }
  }

  // تم إزالة ملف الفيديو بناء على طلب المستخدم ليكتفى بـ الصوت

  // ===================================================
  // 2. تفويض توليد القصة إلى الـ Use Case (LAW 1)
  // لا يوجد هنا أي منطق توليد — الشاشة تستقبل النتيجة فقط
  // ===================================================
  final _generateStoryUseCase = GenerateStoryUseCase();

  Future<void> _generateStoryInBackground() async {
    try {
      debugPrint('[Intro] تفويض التوليد إلى GenerateStoryUseCase...');
      final storyData = await _generateStoryUseCase.execute(widget.requestData, voice: widget.voice);

      if (!mounted) return;

      // التحقق من وجود مشاهد في النتيجة
      final scenes = storyData['scenes'] as List?;
      if (scenes == null || scenes.isEmpty) {
        _generationError = 'لم يتم توليد مشاهد. يرجى المحاولة مجدداً.';
        _navigateOnError();
        return;
      }

      if (!mounted) return;

      debugPrint('[Intro] استلمت النتيجة من UseCase — عدد المشاهد: ${scenes.length}');
      
      // [PERF] Precache images to prevent frame skips in CinemaScreen
      if (mounted) {
        try {
          // Precache cover image
          final cover = storyData['cover_url'] ?? storyData['cover_image'] ?? storyData['coverImageUrl'];
          if (cover != null && cover.toString().isNotEmpty) {
            precacheImage(NetworkImage(cover), context);
          }
          // Precache scenes
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
      setState(() => _isGenerationFinished = true);
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

  // ===================================================
  // الانتقال إلى السينما
  // ===================================================
  void _navigateToCinema() {
    if (_isNavigating || _generatedStoryData == null) return;
    _isNavigating = true;

    _audioPlayer.stop();

    if (mounted) {
      context.pushReplacement(
        '/cinema',
        extra: {
          'storyData': _generatedStoryData!,
          'voice': widget.voice,
        },
      );
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
    final heroName = widget.requestData['heroName'] ?? 'البطل';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // لون ليلي سحري
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. خلفية بديلة جميلة بدلاً من الفيديو
          Center(
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
              ],
            ),
          ),

          // تم إزالة طبقة التلميح السفلي القديمة لتجنب تكرار النصوص
        ],
      ),
    );
  }
}
