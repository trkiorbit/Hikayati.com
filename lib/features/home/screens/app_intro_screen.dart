import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppIntroScreen extends StatefulWidget {
  const AppIntroScreen({super.key});

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _playIntroVideo();
  }

  Future<void> _playIntroVideo() async {
    // تشغيل الفيديو الجديد من الجذر كما طلب المستخدم
    _videoController = VideoPlayerController.asset('sug.hkoty.mp4');
    try {
      await _videoController.initialize();
      if (!mounted) return;

      setState(() => _isVideoInitialized = true);
      await _videoController.play();

      // عند الانتهاء من الفيديو، ننتقل
      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration) {
          _navigateNext();
        }
      });
    } catch (e) {
      debugPrint('[AppIntro] حدث خطأ في تشغيل الفيديو: $e');
      _navigateNext();
    }
  }

  void _navigateNext() {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    try {
      _videoController.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // زر التخطي
          Positioned(
            top: 50,
            right: 20,
            child: TextButton.icon(
              onPressed: _navigateNext,
              icon: const Text('تخطي', style: TextStyle(color: Colors.white70, fontSize: 16)),
              label: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black45,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
