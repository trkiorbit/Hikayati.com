import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/features/story_engine/services/tts_service.dart';
import 'package:hikayati/features/story_engine/services/elevenlabs_direct_service.dart';

class CinemaScreen extends StatefulWidget {
  final Map<String, dynamic> storyData;
  final String voice;

  const CinemaScreen({super.key, required this.storyData, required this.voice});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late List<dynamic> _scenes;

  // ==================================================
  // التايمر - يعمل فقط بعد انتهاء TTS (buffer فقط)
  // ==================================================
  Timer? _bufferTimer;
  /// مدة الانتظار بعد انتهاء التلاوة قبل الانتقال تم تقليلها إلى ثانية واحدة لسرعة التدفق
  static const int _postTtsBufferSeconds = 1;
  int _bufferSecondsLeft = 0;
  bool _isSpeaking = false;
  bool _bufferActive = false;

  // نصف الشاشة: الصورة تظهر بزوم، النص يدخل من الأسفل
  late AnimationController _imageAnimController;
  late AnimationController _textAnimController;
  late Animation<double> _imageScaleAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _textFadeAnim;


  static const platform = MethodChannel('com.hikayati/secure');

  bool get _isClonedVoice => widget.voice == 'cloned';
  String _clonedVoiceId = '';

  @override
  void initState() {
    super.initState();
    _secureScreen();
    _scenes = widget.storyData['scenes'] ?? [];
    _loadVoiceId();

    // إعداد الأنيميشن
    _imageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _imageScaleAnim = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _imageAnimController, curve: Curves.easeOut),
    );
    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textAnimController, curve: Curves.easeOut));
    _textFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textAnimController, curve: Curves.easeOut),
    );

    if (_scenes.isNotEmpty) {
      _loadScene(0);
    }
  }

  Future<void> _loadVoiceId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _clonedVoiceId = prefs.getString('cloned_voice_id') ?? '');
    }
  }

  Future<void> _secureScreen() async {
    try { await platform.invokeMethod('secureScreen'); } catch (_) {}
  }
  Future<void> _unsecureScreen() async {
    try { await platform.invokeMethod('unsecureScreen'); } catch (_) {}
  }



  // ==================================================
  // تحميل مشهد جديد: أنيميشن → TTS → buffer → انتقال
  // ==================================================
  void _loadScene(int index) async {
    // 1. إلغاء أي مؤقت سابق
    _bufferTimer?.cancel();
    setState(() {
      _isSpeaking = false;
      _bufferActive = false;
      _bufferSecondsLeft = 0;
    });

    // 2. تشغيل أنيميشن الصورة
    _imageAnimController.forward(from: 0);

    // 3. تأخير 0.55 ثانية ثم إظهار النص مع أنيميشن
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    _textAnimController.forward(from: 0);

    // 4. تشغيل TTS وانتظار اكتماله
    final text = (_scenes[index] as Map)['text']?.toString() ?? '';
    if (text.isNotEmpty) {
      setState(() => _isSpeaking = true);
      await _speakAndWait(text);
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    }

    // 5. بعد انتهاء القراءة: buffer 3 ثواني ثم انتقل
    if (index < _scenes.length - 1) {
      _startBuffer();
    } else {
      // آخر مشهد
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _onStoryComplete();
    }
  }

  Future<void> _speakAndWait(String text) async {
    final completer = Completer<void>();
    if (_isClonedVoice && _clonedVoiceId.isNotEmpty) {
      await ElevenLabsDirectService.speak(text: text, voiceId: _clonedVoiceId);
    } else {
      final voice = TtsService.resolveVoice(widget.voice);
      // TTS عبر Pollinations - نستخدم AudioPlayer مع onPlayerComplete
      await TtsService.speakAndWait(text, voice: voice, onComplete: () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    }
  }

  void _startBuffer() {
    setState(() {
      _bufferActive = true;
      _bufferSecondsLeft = _postTtsBufferSeconds;
    });
    _bufferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_bufferSecondsLeft > 1) {
          _bufferSecondsLeft--;
        } else {
          _bufferSecondsLeft = 0;
          _bufferActive = false;
          timer.cancel();
          // انتقل للمشهد التالي
          _pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  void _onStoryComplete() {
    if (!mounted) return;
    _stopAllAudio();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ تم الحفظ في المكتبة الخاصة'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/');
    });
  }

  void _stopAllAudio() {
    ElevenLabsDirectService.stop();
    TtsService.stop();
  }

  @override
  void dispose() {
    _unsecureScreen();
    _bufferTimer?.cancel();
    _imageAnimController.dispose();
    _textAnimController.dispose();
    _stopAllAudio();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scenes.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('لا توجد مشاهد', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () { 
            _stopAllAudio(); 
            _bufferTimer?.cancel();
            context.go('/home'); 
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'المشهد ${_currentIndex + 1} / ${_scenes.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (_isSpeaking) ...[
              const SizedBox(width: 8),
              const Icon(Icons.volume_up, color: AppColors.primary, size: 16),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // المشاهد
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _stopAllAudio();
                _bufferTimer?.cancel();
                _loadScene(index);
              },
              itemCount: _scenes.length,
              itemBuilder: (_, index) =>
                  _buildScenePage(_scenes[index] as Map<String, dynamic>),
            ),
          ),

          // شريط تقدم الـ buffer (يظهر فقط بعد انتهاء TTS)
          AnimatedOpacity(
            opacity: _bufferActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
              child: LinearProgressIndicator(
                value: _bufferActive
                    ? 1 - (_bufferSecondsLeft / _postTtsBufferSeconds)
                    : 0.0,
                backgroundColor: Colors.white12,
                color: AppColors.primary,
                minHeight: 3,
              ),
            ),
          ),

          // نقاط المشاهد
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _scenes.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == i ? 16 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentIndex == i ? AppColors.primary : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenePage(Map<String, dynamic> scene) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الصورة: زوم ناعم عند الدخول
          Flexible(
            flex: 3,
            child: AnimatedBuilder(
              animation: _imageScaleAnim,
              builder: (_, child) => Transform.scale(
                scale: _imageScaleAnim.value,
                child: child,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  scene['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (_, child, prog) {
                    if (prog == null) return child;
                    return Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 280, color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white30, size: 60),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // النص: يدخل من الأسفل مع fade
          Flexible(
            flex: 2,
            child: SlideTransition(
              position: _textSlideAnim,
              child: FadeTransition(
                opacity: _textFadeAnim,
                child: Text(
                  scene['text'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(offset: Offset(0, 1), blurRadius: 6, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
