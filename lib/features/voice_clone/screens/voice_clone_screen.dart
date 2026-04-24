import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:hikayati/features/story_engine/services/voice_clone_service.dart';
import 'package:hikayati/features/story_engine/services/elevenlabs_direct_service.dart';

class VoiceCloneScreen extends StatefulWidget {
  const VoiceCloneScreen({super.key});

  @override
  State<VoiceCloneScreen> createState() => _VoiceCloneScreenState();
}

class _VoiceCloneScreenState extends State<VoiceCloneScreen> {
  static const int voiceCreationCost = 20;
  static const int voiceUsagePerStory = 10;

  final _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInit = false;
  bool _isRecording = false;
  bool _isLoading = false;
  bool _isPreviewing = false;
  bool _isPlayingLocal = false;
  bool _hasRecording = false;
  String? _recordedFilePath;
  String? _savedVoiceId;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// يقرأ حالة الصوت المستنسخ من Supabase (مصدر الحقيقة) ثم يزامن SharedPreferences.
  /// يضمن: لا يظهر "صوتك جاهز" لمستخدم لم ينشئ صوتاً.
  Future<void> _initData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isInit = true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // حاول أولاً قراءة العمودين معاً (يتطلب migration cloned_voice_id مُطبّقة)
    bool? enabled;
    dynamic remoteId;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('voice_clone_enabled, cloned_voice_id')
          .eq('user_id', userId)
          .maybeSingle();
      enabled = res?['voice_clone_enabled'] == true;
      remoteId = res?['cloned_voice_id'];
    } catch (e) {
      // العمود cloned_voice_id غير موجود — fallback إلى voice_clone_enabled وحده
      debugPrint('[VoiceClone] full read failed, trying minimal: $e');
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('voice_clone_enabled')
            .eq('user_id', userId)
            .maybeSingle();
        enabled = res?['voice_clone_enabled'] == true;
        remoteId = null; // العمود غير موجود — سنعتمد على prefs
      } catch (e2) {
        debugPrint('[VoiceClone] minimal read also failed: $e2');
        if (mounted) setState(() => _isInit = true);
        return;
      }
    }

    if (enabled != true) {
      // الحساب لا يملك صوتاً مستنسخاً — امسح أي بقايا محلية
      await prefs.remove('cloned_voice_id');
      if (mounted) {
        setState(() {
          _savedVoiceId = null;
          _isInit = true;
        });
      }
      return;
    }

    // الحساب يملك صوتاً — استخدم القيمة من Supabase إن توفرت، وإلا fallback محلي
    String? voiceId;
    if (remoteId is String && remoteId.isNotEmpty) {
      voiceId = remoteId;
      await prefs.setString('cloned_voice_id', voiceId);
    } else {
      voiceId = prefs.getString('cloned_voice_id');
    }

    if (mounted) {
      setState(() {
        _savedVoiceId = voiceId;
        _isInit = true;
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _showVoiceConsent() async {
    bool accepted = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C2333),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('موافقة استنساخ الصوت',
              style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('قبل بدء التسجيل، يرجى الإقرار بالتالي:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _consentBullet('أؤكد أنني أملك هذا الصوت أو لدي إذن صريح لاستخدامه.'),
                _consentBullet('سيتم استخدام التسجيل لإنشاء صوت سرد داخل التطبيق فقط.'),
                _consentBullet('قد يتم حفظ بيانات الصوت والمعالجة المرتبطة به لتوفير الخدمة.'),
                _consentBullet('يمكنني حذف الصوت المستنسخ في أي وقت من داخل التطبيق.'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: accepted,
                      activeColor: AppColors.secondary,
                      onChanged: (v) => setDialogState(() => accepted = v ?? false),
                    ),
                    Expanded(
                      child: Text('أوافق على الشروط أعلاه',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: accepted ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: const Text('بدء التسجيل', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
    if (result == true) _startRecording();
  }

  Widget _consentBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle_outline, size: 16, color: AppColors.secondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ),
        ],
      ),
    );
  }

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
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          echoCancel: true,
          noiseSuppress: true,
        ),
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
        if (_recordingSeconds >= 15) _stopRecording();
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

      if (_recordingSeconds < 10 && path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('⚠️ التسجيل قصير جداً (يرجى التسجيل لـ 10 ثوانٍ على الأقل)'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint('[VoiceClone] Stop error: $e');
    }
  }

  Future<void> _playLocalRecording() async {
    if (_recordedFilePath == null) return;
    try {
      setState(() => _isPlayingLocal = true);
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingLocal = false);
      });
    } catch (e) {
      debugPrint('[VoiceClone] Play error: $e');
      if (mounted) setState(() => _isPlayingLocal = false);
    }
  }

  /// الترتيب الذري الصحيح:
  /// 1. تحقق من الرصيد (>= 20)
  /// 2. أنشئ الصوت عبر ElevenLabs
  /// 3. عند النجاح: اخصم الرصيد + حدّث Supabase (atomic)
  /// 4. إن فشلت الخطوة 2 → لا خصم، لا تحديث
  /// 5. إن فشلت الخطوة 3 → rollback (حذف الصوت من ElevenLabs)
  Future<void> _uploadAndClone() async {
    if (_recordedFilePath == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تسجيل الدخول'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // الخطوة 1: تحقق من الرصيد قبل أي شيء
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('credits')
          .eq('user_id', userId)
          .maybeSingle();
      final currentCredits = (profile?['credits'] as int?) ?? 0;
      if (currentCredits < voiceCreationCost) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'رصيدك ($currentCredits ⭐) غير كافٍ. تحتاج $voiceCreationCost ⭐ لاستنساخ الصوت.'),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('[VoiceClone] credits pre-check failed: $e');
      // نكمل، عملية الخصم ستفشل إن كان الرصيد غير كافٍ
    }

    String? voiceId;
    try {
      // الخطوة 2: أنشئ الصوت (لا خصم بعد)
      final file = File(_recordedFilePath!);
      final bytes = await file.readAsBytes();
      voiceId = await VoiceCloneService.cloneVoice(
        audioBytes: bytes,
        voiceName: 'voice_$userId',
      );
    } catch (e) {
      // فشل الإنشاء → لا خصم، أظهر رسالة
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل استنساخ الصوت: ${_friendlyError(e)}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5)),
        );
      }
      return;
    }

    // الخطوة 3: اخصم الرصيد
    try {
      await SupabaseService.deductCredits(voiceCreationCost, 'إنشاء نسخة صوتية');
    } catch (e) {
      // فشل الخصم → rollback: احذف الصوت من ElevenLabs
      debugPrint('[VoiceClone] deduct failed, rolling back: $e');
      try {
        await VoiceCloneService.deleteVoice(voiceId);
      } catch (rollbackError) {
        debugPrint('[VoiceClone] rollback failed: $rollbackError');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تعذّر خصم الرصيد: ${_friendlyError(e)}'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    // الخطوة 4: حدّث Supabase — مصدر الحقيقة
    try {
      await Supabase.instance.client.from('profiles').update({
        'voice_clone_enabled': true,
        'cloned_voice_id': voiceId,
      }).eq('user_id', userId);
    } catch (e) {
      // عمود cloned_voice_id قد لا يكون موجوداً (migration غير مُطبَّقة)
      // نحاول بدونه كـ fallback
      debugPrint('[VoiceClone] full update failed, trying minimal: $e');
      try {
        await Supabase.instance.client.from('profiles').update({
          'voice_clone_enabled': true,
        }).eq('user_id', userId);
      } catch (e2) {
        debugPrint('[VoiceClone] minimal update also failed: $e2');
      }
    }

    // الخطوة 5: cache محلي
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cloned_voice_id', voiceId);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _savedVoiceId = voiceId;
        _isLoading = false;
        _hasRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ تم استنساخ صوتك بنجاح وخصم 20 ⭐ من رصيدك!'),
            backgroundColor: Colors.green),
      );
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Insufficient credits')) return 'رصيدك غير كافٍ';
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'تعذّر الاتصال بالإنترنت';
    }
    if (msg.length > 80) return '${msg.substring(0, 80)}...';
    return msg;
  }

  Future<void> _previewVoice() async {
    if (_savedVoiceId == null || _isPreviewing) return;
    setState(() => _isPreviewing = true);
    try {
      await ElevenLabsDirectService.speak(
        text: 'مرحباً، أنا صوتك المستنسخ، سأقوم برواية أجمل القصص لطفلك.',
        voiceId: _savedVoiceId!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('عذراً، فشل التشغيل: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  Future<void> _deleteVoice() async {
    if (_savedVoiceId == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      // احذف من ElevenLabs
      try {
        await VoiceCloneService.deleteVoice(_savedVoiceId!);
      } catch (e) {
        debugPrint('[VoiceClone] ElevenLabs delete failed (continuing): $e');
      }

      // حدّث Supabase — مصدر الحقيقة
      try {
        await Supabase.instance.client.from('profiles').update({
          'voice_clone_enabled': false,
          'cloned_voice_id': null,
        }).eq('user_id', userId);
      } catch (e) {
        // fallback بدون عمود cloned_voice_id
        await Supabase.instance.client.from('profiles').update({
          'voice_clone_enabled': false,
        }).eq('user_id', userId);
      }

      // امسح cache المحلي
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cloned_voice_id');

      if (mounted) {
        setState(() {
          _savedVoiceId = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حذف البصمة الصوتية بنجاح'),
              backgroundColor: Colors.orange),
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
        title: const Text('بصمة الصوت السحرية',
            style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 1,
        centerTitle: true,
        actions: const [CreditsBadge()],
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
            const SizedBox(height: 20),
            _buildPricingInfo(),
            const SizedBox(height: 24),
            if (_savedVoiceId != null && !_isLoading)
              _buildSuccessState()
            else if (_isLoading)
              _buildLoadingState()
            else if (_isRecording)
              _buildRecordingState()
            else if (_hasRecording)
              _buildReadyToUploadState()
            else
              _buildInitialState(),
          ],
        ),
      ),
    );
  }

  /// بطاقة التكلفة — واضحة دائماً قبل وبعد الإنشاء
  Widget _buildPricingInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2333),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _pricingRow(
            label: 'إنشاء الصوت المستنسخ (مرة واحدة)',
            value: '-$voiceCreationCost',
            isDeduction: true,
          ),
          const SizedBox(height: 6),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 8),
          const SizedBox(height: 6),
          _pricingRow(
            label: 'استخدام الصوت في كل قصة',
            value: '-$voiceUsagePerStory',
            isDeduction: true,
          ),
        ],
      ),
    );
  }

  Widget _pricingRow({
    required String label,
    required String value,
    required bool isDeduction,
  }) {
    final color = isDeduction ? const Color(0xFFFF5252) : const Color(0xFF4CAF50);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 3),
        Icon(Icons.stars, color: color, size: 16),
      ],
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
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _showVoiceConsent,
          icon: const Icon(Icons.play_arrow),
          label: const Text('بدء التسجيل الآن',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        const Text('🔴 جاري الاستماع لنبرة صوتك...',
            style: TextStyle(
                color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text(_formatSeconds(_recordingSeconds),
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
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
        const Text('✅ تم التقاط العينة الصوتية!',
            style: TextStyle(
                color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _isPlayingLocal ? null : _playLocalRecording,
          icon: Icon(_isPlayingLocal ? Icons.volume_up : Icons.play_circle_fill),
          label: Text(_isPlayingLocal ? 'جاري التشغيل...' : 'استمع لتسجيلك أولاً'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: _uploadAndClone,
          icon: const Icon(Icons.cloud_upload),
          label: Text('استنساخ الصوت الآن  •  -$voiceCreationCost ⭐',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.deepBlack,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () => setState(() => _hasRecording = false),
          child: const Text('إعادة التسجيل', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: const Color(0xFF1C2333),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5))),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: Colors.greenAccent, size: 60),
          const SizedBox(height: 16),
          const Text('صوتك المستنسخ جاهز!',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isPreviewing ? null : _previewVoice,
            icon: _isPreviewing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.deepBlack))
                : const Icon(Icons.volume_up),
            label: const Text('اسمع كيف يبدو صوتك'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.deepBlack,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: _deleteVoice,
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            label: const Text('حذف البصمة وتسجيل جديد',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      children: [
        CircularProgressIndicator(color: AppColors.secondary),
        SizedBox(height: 20),
        Text('حكيم يقوم بتحليل بصمتك ورفعها للسحاب...',
            style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
