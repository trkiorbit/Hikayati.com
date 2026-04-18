import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:audioplayers/audioplayers.dart';

class CinemaScreen extends StatefulWidget {
  final Map<String, dynamic> storyData;
  final String voice;
  final bool fromLibrary;

  const CinemaScreen({
    super.key,
    required this.storyData,
    required this.voice,
    this.fromLibrary = false,
  });

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _currentIndex = 0;
  late List<dynamic> _scenes;

  Timer? _bufferTimer;
  static const int _postTtsBufferSeconds = 1;
  int _bufferSecondsLeft = 0;
  bool _isPlaying = false;
  bool _bufferActive = false;

  late AnimationController _imageAnimController;
  late AnimationController _textAnimController;
  late Animation<double> _imageScaleAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _textFadeAnim;

  static const platform = MethodChannel('com.hikayati/secure');

  @override
  void initState() {
    super.initState();
    _secureScreen();
    _scenes = widget.storyData['scenes'] ?? [];

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

  Future<void> _secureScreen() async {
    try { await platform.invokeMethod('secureScreen'); } catch (_) {}
  }

  Future<void> _unsecureScreen() async {
    try { await platform.invokeMethod('unsecureScreen'); } catch (_) {}
  }

  // ── تحميل مشهد: أنيميشن → صوت محفوظ → buffer → انتقال ──
  void _loadScene(int index) async {
    _bufferTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _bufferActive = false;
      _bufferSecondsLeft = 0;
    });

    _imageAnimController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    _textAnimController.forward(from: 0);

    final scene = _scenes[index] as Map;
    final savedAudioUrl = scene['audio_url']?.toString();

    // تشغيل الصوت المحفوظ فقط — لا TTS، لا توليد
    if (savedAudioUrl != null && savedAudioUrl.isNotEmpty) {
      setState(() => _isPlaying = true);
      await _playSavedAudio(savedAudioUrl);
      if (!mounted) return;
      setState(() => _isPlaying = false);
    }
    // إذا لم يكن هناك صوت محفوظ → انتظر ثانيتين وانتقل

    if (index < _scenes.length - 1) {
      _startBuffer();
    } else {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _onStoryComplete();
    }
  }

  Future<void> _playSavedAudio(String url) async {
    debugPrint('[Cinema] 🎵 تشغيل الصوت المحفوظ: $url');
    try {
      final completer = Completer<void>();
      final sub = _audioPlayer.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await _audioPlayer.play(UrlSource(url));
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {},
      );
      sub.cancel();
    } catch (e) {
      debugPrint('[Cinema] ⚠️ فشل تشغيل الصوت المحفوظ: $e');
    }
  }

  void _stopAudio() {
    _audioPlayer.stop();
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
    _stopAudio();
    // الرسالة تعكس المصدر الحقيقي
    final msg = widget.fromLibrary
        ? '✨ انتهت القصة!'
        : '✨ تم الحفظ في المكتبة الخاصة!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _unsecureScreen();
    _bufferTimer?.cancel();
    _imageAnimController.dispose();
    _textAnimController.dispose();
    _stopAudio();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scenes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              const Text('لا توجد مشاهد', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('العودة للرئيسية', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
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
            _stopAudio();
            _bufferTimer?.cancel();
            if (widget.fromLibrary) {
              context.go('/private-library'); // ✅ المسار الصحيح
            } else {
              context.go('/');
            }
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'المشهد ${_currentIndex + 1} / ${_scenes.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (_isPlaying) ...[
              const SizedBox(width: 8),
              const Icon(Icons.volume_up, color: AppColors.primary, size: 16),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _stopAudio();
                _bufferTimer?.cancel();
                _loadScene(index);
              },
              itemCount: _scenes.length,
              itemBuilder: (_, index) =>
                  _buildScenePage(_scenes[index] as Map<String, dynamic>),
            ),
          ),

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
                    height: 280,
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white30, size: 60),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

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
