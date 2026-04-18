/// === GenerateStoryUseCase ===
/// Application Layer — Use Case
///
/// يمثّل هذا الكلاس الحد الفاصل بين شاشات Flutter وخدمات الذكاء الاصطناعي.
/// LAW 1 (من HIKAYATI_AGENT_MASTER_SPEC.md):
///   "UI does not generate stories. Screens collect input, trigger actions, show loading states."

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/features/story_engine/services/unified_engine.dart';
import 'package:hikayati/features/library/services/library_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// استثناء خاص عندما يتجاوز المستخدم حد 10 قصص
class StoryLimitException implements Exception {
  final int currentCount;
  final List<dynamic> existingStories;
  const StoryLimitException({
    required this.currentCount,
    required this.existingStories,
  });

  @override
  String toString() => 'StoryLimitException: $currentCount قصص محفوظة';
}

class GenerateStoryUseCase {
  final LibraryService _libraryService = LibraryService();

  static const int maxStories = 10;

  /// قفل ثابت يمنع استدعاء execute أكثر من مرة في نفس الوقت
  static bool _isGenerating = false;

  /// معرّفات القصص التي خُصم رصيدها — يمنع الخصم المزدوج في نفس الجلسة
  static final Set<String> _deductedStoryIds = {};

  /// تحويل اختيار الصوت من UI إلى voice ID محدد لـ OpenAI TTS
  /// UI values: echo (رجالي قصصي), fable (نسائي), onyx (رجالي عميق)
  static String _resolveOpenAiVoice(String? voice) {
    switch (voice) {
      case 'echo':
        return 'echo';     // رجالي قصصي (الافتراضي)
      case 'fable':
        return 'fable';    // نسائي
      case 'onyx':
        return 'onyx';     // رجالي عميق
      default:
        debugPrint('[VoiceMap] ⚠️ صوت غير معروف: $voice → fallback to echo');
        return 'echo';
    }
  }

  Future<Uint8List?> _fetchAudioWithRetry(String url, Map<String, String> headers, [String? body]) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        http.Response res;
        if (body != null) {
          res = await http.post(Uri.parse(url), headers: headers, body: body).timeout(const Duration(seconds: 30));
        } else {
          final safeHeaders = {...headers};
          if (!safeHeaders.containsKey('User-Agent')) {
            safeHeaders['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
          }
          res = await http.get(Uri.parse(url), headers: safeHeaders).timeout(const Duration(seconds: 30));
        }
        if (res.statusCode == 200) return res.bodyBytes;
        debugPrint('[AudioRetry] Attempt $attempt failed: ${res.statusCode}');
        
        if (attempt < 3) await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        debugPrint('[AudioRetry] Attempt $attempt error: $e');
        
        if (attempt < 3) await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> requestData,
    {String? voice, bool saveToLibrary = true}
  ) async {
    debugPrint('[UseCase] GenerateStoryUseCase.execute() — بدء التوليد');

    // ====== منع التوليد المزدوج (Race Condition) ======
    if (_isGenerating) {
      debugPrint('[UseCase] ⚠️ طلب مكرر مرفوض — التوليد جارٍ بالفعل');
      throw Exception('جارٍ التوليد بالفعل. يرجى الانتظار حتى تكتمل القصة الحالية.');
    }
    _isGenerating = true;

    // التكلفة الأساسية للقصة هي 10 كريدت حسب طلب المستخدم
    int totalCost = 10;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('يجب تسجيل الدخول أولاً.');

    // ====== التحقق من حد القصص (10 قصص) ======
    if (saveToLibrary) {
      final storyCount = await _libraryService.getStoryCount();
      if (storyCount >= maxStories) {
        final existingStories = await _libraryService.getPrivateStories();
        debugPrint('[UseCase] ⛔ تجاوز الحد: $storyCount قصص محفوظة');
        throw StoryLimitException(
          currentCount: storyCount,
          existingStories: existingStories,
        );
      }
    }

    // جلب الرصيد المباشر من قاعدة البيانات
    final profileRes = await Supabase.instance.client
        .from('profiles')
        .select('credits')
        .eq('user_id', userId)
        .single();
    final currentCredits = profileRes['credits'] as int? ?? 0;

    if (currentCredits < totalCost) {
      throw Exception(
          'الرصيد الفعلي غير كافٍ. تمتلك $currentCredits وتحتاج إلى $totalCost جواهر.');
    }

    // جلب الأفاتار إذا طُلب
    if (requestData['useAvatar'] == true) {
      debugPrint('[AvatarFetch] start');
      try {
        final avatarProfileRes = await Supabase.instance.client
            .from('profiles')
            .select('avatar_profile_summary')
            .eq('user_id', userId)
            .single();
        final avatarData = avatarProfileRes['avatar_profile_summary'];

        if (avatarData != null) {
          debugPrint('[AvatarFetch] found avatar_profile_summary');
          final face = avatarData['face_description'] ?? 'cute child';
          final clothes = avatarData['current_clothes'] ?? 'colorful clothes';
          // يستخدم prompt_snippet المحفوظ مباشرةً إذا كان موجوداً، وإلا يبنيه
          final promptSnippet = avatarData['prompt_snippet'] as String?;
          requestData['heroVisualDescription'] = promptSnippet ??
              '3D Pixar child, $face, wearing $clothes, clean white background';
          requestData['avatarData'] = avatarData;
          if (avatarData['name'] != null) requestData['heroName'] = avatarData['name'];
          if (avatarData['age'] != null) requestData['heroAge'] = avatarData['age'].toString();
        } else {
          debugPrint('[AvatarFetch] null -> disable avatar');
          requestData['useAvatar'] = false;
        }
      } catch (e) {
        debugPrint('[AvatarFetch] error -> disable avatar');
        requestData['useAvatar'] = false;
      }
    }

    debugPrint('[UseCase] heroName: ${requestData['heroName']}');
    debugPrint('[UseCase] storyStyle: ${requestData['storyStyle']}');
    debugPrint('[UseCase] useAvatar: ${requestData['useAvatar']}');
    debugPrint('[UseCase] Total Cost Paid: $totalCost credits');
    
    final bool useClonedVoice = (voice == 'cloned');
    debugPrint('[VoiceMap] selected_ui_voice_label=$voice');
    debugPrint('[VoiceMap] resolved_internal_voice=${_resolveOpenAiVoice(voice)}');
    debugPrint('[VoiceMap] useClonedVoice=$useClonedVoice');
    if (!useClonedVoice) debugPrint('[VoiceProvider] normal_story_provider=pollinations');

    try {
      final storyData = await UnifiedEngine.generateStory(requestData, saveToLibrary: saveToLibrary);


      final scenes = List<Map<String, dynamic>>.from(storyData['scenes'] ?? []);
      final storyId = storyData['id'];

      if (saveToLibrary && storyId != null && scenes.isNotEmpty) {
        debugPrint('[UseCase] بدء توليد الصوت...');
        final isCloned = voice == 'cloned';
        final elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
        final prefs = await SharedPreferences.getInstance();
        final clonedVoiceId = prefs.getString('cloned_voice_id');

        // توليد الصوت لكل مشهد بالتسلسل (بدون Pool)
        for (int i = 0; i < scenes.length; i++) {
          final scene = scenes[i];
          final text = scene['text'] ?? '';
          if (text.isEmpty) continue;

          Uint8List? audioBytes;

          if (isCloned && elevenLabsKey.isNotEmpty && clonedVoiceId != null && clonedVoiceId.isNotEmpty) {
            final url = 'https://api.elevenlabs.io/v1/text-to-speech/$clonedVoiceId';
            final headers = {'xi-api-key': elevenLabsKey, 'Content-Type': 'application/json'};
            final body = jsonEncode({
              "text": text,
              "model_id": "eleven_multilingual_v2",
              "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
            });
            audioBytes = await _fetchAudioWithRetry(url, headers, body);
          } else {
            // الصوت العادي: Pollinations TTS أولاً (قرار معتمد 2026-04-15)
            final resolvedVoice = _resolveOpenAiVoice(voice);
            final encodedText = Uri.encodeComponent(text);
            final audioKey = dotenv.env['POLLINATIONS_AUDIO_API_KEY'] ?? '';
            final pollinationsUrl = 'https://gen.pollinations.ai/audio/$encodedText'
                '?voice=$resolvedVoice&model=elevenlabs';

            final Map<String, String> headers = {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            };
            if (audioKey.isNotEmpty) {
              headers['Authorization'] = 'Bearer $audioKey';
            }

            debugPrint('[AudioProvider] Using Pollinations TTS — voice=$resolvedVoice, hasKey=${audioKey.isNotEmpty}');
            if (i > 0) await Future.delayed(const Duration(milliseconds: 800));
            audioBytes = await _fetchAudioWithRetry(pollinationsUrl, headers);

            if (audioBytes == null || audioBytes.length <= 500) {
              // آخر مسار نجاة: Google TTS إذا فشل Pollinations
              debugPrint('[AudioProvider] Pollinations failed → Google TTS Fallback');
              final cleanText = text.replaceAll('\n', ' ').trim();
              final fallbackUrl = 'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=ar&q=${Uri.encodeQueryComponent(cleanText)}';
              if (i > 0) await Future.delayed(const Duration(seconds: 2));
              audioBytes = await _fetchAudioWithRetry(fallbackUrl, {});
            }
          }

          // التحقق من أن النتيجة هي ملف MP3 فعلاً (وليس نص مثل رسائل الخطأ)
          if (audioBytes != null && audioBytes.length > 500) {
            try {
              // رفع الصوت إلى Supabase Storage
              final fileName = '$userId/${storyId}_scene_$i.mp3';
              await Supabase.instance.client.storage
                  .from('story_audio')
                  .uploadBinary(
                    fileName, 
                    audioBytes,
                    fileOptions: const FileOptions(contentType: 'audio/mpeg'),
                  );
              final audioUrl = Supabase.instance.client.storage
                  .from('story_audio')
                  .getPublicUrl(fileName);
              scenes[i]['audio_url'] = audioUrl;
              debugPrint('[UseCase] ✅ صوت المشهد $i محفوظ: $audioUrl');
            } catch (storageError) {
              debugPrint('[UseCase] ⚠️ خطأ رفع صوت المشهد $i: $storageError');
              scenes[i]['audio_url'] = null;
            }
          } else {
            scenes[i]['audio_url'] = null;
          }
        }

        // حفظ voice_type وروابط الصوت في قاعدة البيانات
        try {
          await Supabase.instance.client
              .from('stories')
              .update({
                'scenes_json': scenes,
                'voice_type': voice ?? 'nova',
              })
              .eq('id', storyId);
          debugPrint('[UseCase] ✅ تم حفظ روابط الصوت ونوع الصوت في قاعدة البيانات');
        } catch (dbErr) {
          debugPrint('[UseCase] ⚠️ خطأ تحديث مسارات الصوت: $dbErr');
        }

        storyData['scenes'] = scenes;
      }

      // ====== الخصم النهائي بعد نجاح النص + الصور + الصوت ======
      final deductStoryId = storyId?.toString() ?? '';

      // حماية الخصم المزدوج: إذا خُصمت هذه القصة مسبقاً في نفس الجلسة → تجاوز
      if (deductStoryId.isNotEmpty && _deductedStoryIds.contains(deductStoryId)) {
        debugPrint('[CREDIT] ⚠️ الخصم تم مسبقاً للقصة ($deductStoryId) — تجاوز');
      } else {
        try {
          // قراءة الرصيد الحالي من Supabase قبل الخصم
          final beforeRes = await Supabase.instance.client
              .from('profiles')
              .select('credits')
              .eq('user_id', userId)
              .single();
          final beforeCredits = beforeRes['credits'] as int? ?? 0;

          debugPrint('[CREDIT] before=$beforeCredits');
          debugPrint('[CREDIT] deducted=$totalCost');

          await Supabase.instance.client.rpc('deduct_credits', params: {
            'p_user_id': userId,
            'p_amount': totalCost,
            'p_reason': 'توليد قصة سينمائية',
          });

          // قراءة الرصيد الجديد من Supabase بعد الخصم للتأكيد
          final afterRes = await Supabase.instance.client
              .from('profiles')
              .select('credits')
              .eq('user_id', userId)
              .single();
          final afterCredits = afterRes['credits'] as int? ?? 0;

          debugPrint('[CREDIT] after=$afterCredits');
          debugPrint('[CREDIT] story_id=$deductStoryId');

          // تسجيل القصة لمنع أي خصم مزدوج لاحق
          if (deductStoryId.isNotEmpty) _deductedStoryIds.add(deductStoryId);

        } catch (deductErr) {
          if (saveToLibrary && storyId != null) {
            await Supabase.instance.client.from('stories').delete().eq('id', storyId);
            debugPrint('[UseCase] ❌ فشل الخصم، تم حذف القصة $storyId للتراجع.');
          }
          throw Exception('فشلت عملية الخصم، تم التراجع وحذف القصة: $deductErr');
        }
      }

      debugPrint('[UseCase] اكتمل التوليد — عدد المشاهد: ${scenes.length}');
      return storyData;
    } catch (e, stack) {
      debugPrint('[UseCase] خطأ في التوليد: $e\n$stack');
      rethrow;
    } finally {
      _isGenerating = false;
    }
  }
}
