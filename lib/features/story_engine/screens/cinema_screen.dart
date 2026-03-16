import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hikayati/core/theme/app_colors.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  
  bool _isPlaying = false;
  double _bgmVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _playCinemaExperience();
  }

  void _playCinemaExperience() async {
    // 1. Play Background Music independently
    // (In a real scenario, you'd have a local asset or URL for BGM)
    // await _bgmPlayer.play(AssetSource('audio/magical_bgm.mp3'), volume: _bgmVolume);
    
    // 2. Play Narrative Voice independently
    // await _voicePlayer.play(UrlSource('Generated_Voice_URL'));

    setState(() => _isPlaying = true);
  }

  void _stopAndFadeOut() async {
    // Fade-out effect logic
    for (int i = 5; i > 0; i--) {
      _bgmVolume = i / 10;
      await _bgmPlayer.setVolume(_bgmVolume);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await _bgmPlayer.stop();
    await _voicePlayer.stop();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Cinematic black background
      body: Stack(
        children: [
          // Visual content representation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome, 
                  size: 100,
                  color: AppColors.secondary, // Gold magic
                ),
                const SizedBox(height: 24),
                Text(
                  '... كان يا ما كان',
                  style: TextStyle(
                    fontFamily: 'Cairo', // Added for cinematic arabic feel
                    fontSize: 32,
                    color: AppColors.primary, // Purple branding
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isPlaying) 
                  CircularProgressIndicator(color: AppColors.secondary),
                const SizedBox(height: 24),
                Text(
                  _isPlaying ? 'يتم عرض المشاهد الصوتية والبصرية...' : 'جاري التحضير...',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          // Close/Fade-out Button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: _stopAndFadeOut,
            ),
          ),
        ],
      ),
    );
  }
}
