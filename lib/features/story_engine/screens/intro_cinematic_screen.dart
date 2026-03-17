/// === IntroCinematicScreen ===
/// شاشة المقدمة المدمجة مع التوليد
///
/// المهام المتوازية في هذه الشاشة:
/// 1. تشغيل فيديو المقدمة (الشارة) - يمكن تغييره في أي وقت
/// 2. توليد القصة في الخلفية عبر UnifiedEngine
/// 3. عند اكتمال التوليد → تُقطع المقدمة وتبدأ السينما
///
/// المقدمة هي ملف محلي: assets/videos/intro_video.mp4
/// يمكن استبداله بأي فيديو في أي وقت دون تعديل الكود

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/story_engine/services/unified_engine.dart';

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
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isVideoInitialized = false;
  bool _isNavigating = false;

  // نتيجة التوليد
  Map<String, dynamic>? _generatedStoryData;
  String? _generationError;

  @override
  void initState() {
    super.initState();
    // الخطوتان تعملان بالتوازي بدون انتظار بعضهما
    _playIntroVideo();
    _generateStoryInBackground();
  }

  // ===================================================
  // 1. تشغيل المقدمة (مستقلة - لا تعرف شيئاً عن التوليد)
  // ===================================================
  Future<void> _playIntroVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/intro_video.mp4');
    try {
      await _videoController.initialize();
      if (!mounted) return;
      setState(() => _isVideoInitialized = true);
      await _videoController.play();
      await _audioPlayer.play(AssetSource('audio/intro_audio.mp3'));
    } catch (e) {
      debugPrint('[Intro] Video/Audio error: $e');
      // إن فشل الفيديو، انتظر القصة فقط لا تنقطع من هنا
    }
  }

  // ===================================================
  // 2. توليد القصة في الخلفية
  // ===================================================
  Future<void> _generateStoryInBackground() async {
    try {
      debugPrint('[Intro] بدء توليد القصة في الخلفية...');
      final storyData = await UnifiedEngine.generateStory(widget.requestData);

      if (!mounted) return;

      // التحقق من وجود خطأ في بيانات القصة
      final scenes = storyData['scenes'] as List?;
      if (scenes == null || scenes.isEmpty) {
        _generationError = 'لم يتم توليد مشاهد. يرجى المحاولة مجدداً.';
        _navigateOnError();
        return;
      }

      debugPrint('[Intro] اكتمل التوليد - الانتقال للسينما');
      _generatedStoryData = storyData;
      _navigateToCinema();
    } catch (e) {
      debugPrint('[Intro] خطأ في التوليد: $e');
      _generationError = 'حدث خطأ: ${e.toString()}';
      if (mounted) _navigateOnError();
    }
  }

  // ===================================================
  // الانتقال إلى السينما
  // ===================================================
  void _navigateToCinema() {
    if (_isNavigating || _generatedStoryData == null) return;
    _isNavigating = true;

    // إيقاف المقدمة
    try {
      _videoController.pause();
    } catch (_) {}
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

    try {
      _videoController.pause();
    } catch (_) {}
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
    try {
      _videoController.dispose();
    } catch (_) {}
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroName = widget.requestData['heroName'] ?? 'البطل';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. طبقة الفيديو
          if (_isVideoInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // 2. طبقة تلميح التوليد في الأسفل
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'نجهز قصة $heroName...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
