import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/story_engine/services/voice_clone_service.dart';
import 'package:hikayati/features/story_engine/services/elevenlabs_direct_service.dart';

class VoiceCloneScreen extends StatefulWidget {
  const VoiceCloneScreen({super.key});

  @override
  State<VoiceCloneScreen> createState() => _VoiceCloneScreenState();
}

class _VoiceCloneScreenState extends State<VoiceCloneScreen> {
  final _audioRecorder = AudioRecorder();

  bool _isInit = false;
  bool _isRecording = false;
  bool _isLoading = false;
  bool _isPreviewing = false;
  bool _hasRecording = false;
  String? _recordedFilePath;
  String? _savedVoiceId;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _savedVoiceId = prefs.getString('cloned_voice_id');
        _isInit = true; // لضمان عدم ظهور الشاشة السوداء أثناء التحميل البسيط
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  // بدء التسجيل
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ يجب منح إذن الميكروفون'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      _recordedFilePath = '${dir.path}/voice_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: _recordedFilePath!,
      );

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _hasRecording = false;
      });

      _startTimer();
    } catch (e) {
      debugPrint('[VoiceClone] Start error: $e');
    }
  }

  void _startTimer() async {
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 60) _stopRecording();
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
        _hasRecording = path != null && _recordingSeconds >= 10;
      });
      
      if (_recordingSeconds < 10 && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ التسجيل قصير جداً (يرجى التسجيل لـ 10 ثوانٍ على الأقل)'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint('[VoiceClone] Stop error: $e');
    }
  }

  Future<void> _uploadAndClone() async {
    if (_recordedFilePath == null) return;
    setState(() => _isLoading = true);
    try {
      final file = File(_recordedFilePath!);
      final bytes = await file.readAsBytes();
      final voiceId = await VoiceCloneService.cloneVoice(
        audioBytes: bytes,
        voiceName: 'بصمة_صوت_ولي_الأمر',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cloned_voice_id', voiceId);
      if (mounted) {
        setState(() {
          _savedVoiceId = voiceId;
          _isLoading = false;
          _hasRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تمت عملية الاستنساخ وحفظ البصمة بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _previewVoice() async {
    if (_savedVoiceId == null || _isPreviewing) return;
    setState(() => _isPreviewing = true);
    try {
      await ElevenLabsDirectService.speak(
        text: 'مرحباً، أنا صوتك المستنسخ، سأقوم برواية أجمل القصص لطفلك.',
        voiceId: _savedVoiceId!,
      );
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  Future<void> _deleteVoice() async {
    if (_savedVoiceId == null) return;
    setState(() => _isLoading = true);
    try {
      await VoiceCloneService.deleteVoice(_savedVoiceId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cloned_voice_id');
      if (mounted) {
        setState(() {
          _savedVoiceId = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف البصمة الصوتية بنجاح'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatSeconds(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('بصمة الصوت السحرية', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.mic_external_on, size: 80, color: AppColors.secondary),
            const SizedBox(height: 16),
            const Text(
              'حوّل صوتك إلى راوٍ سحري',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 32),

            if (_savedVoiceId != null && !_isLoading) ...[
              _buildSuccessState()
            ] else if (_isLoading) ...[
              _buildLoadingState()
            ] else ...[
              if (_isRecording) _buildRecordingState()
              else if (_hasRecording) _buildReadyToUploadState()
              else _buildInitialState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      children: [
        const Text(
          'تحدث لمدة 10 ثوانٍ على الأقل ليتمكن "حكيم" من تعلم نبرة صوتك.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.play_arrow),
          label: const Text('بدء التسجيل الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      children: [
        const Text('🔴 جاري الاستماع لنبرة صوتك...', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text(_formatSeconds(_recordingSeconds), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _stopRecording,
          icon: const Icon(Icons.stop),
          label: const Text('إيقاف وحفظ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyToUploadState() {
    return Column(
      children: [
        const Text('✅ تم التقاط العينة الصوتية!', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _uploadAndClone,
          icon: const Icon(Icons.cloud_upload),
          label: const Text('استنساخ الصوت الآن'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.deepBlack,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),
        TextButton(onPressed: () => setState(() => _hasRecording = false), child: const Text('إعادة التسجيل', style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1C2333), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.5))),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: Colors.greenAccent, size: 60),
          const SizedBox(height: 16),
          const Text('صوتك المستنسخ جاهز!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isPreviewing ? null : _previewVoice,
            icon: _isPreviewing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepBlack)) : const Icon(Icons.volume_up),
            label: const Text('اسمع كيف يبدو صوتك'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.deepBlack, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          ),
          const SizedBox(height: 32),
          TextButton.icon(onPressed: _deleteVoice, icon: const Icon(Icons.delete_forever, color: Colors.redAccent), label: const Text('حذف البصمة وتسجيل جديد', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      children: [
        CircularProgressIndicator(color: AppColors.secondary),
        const SizedBox(height: 20),
        Text('حكيم يقوم بتحليل بصمتك ورفعها للسحاب...', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
