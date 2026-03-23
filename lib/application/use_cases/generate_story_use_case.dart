/// === GenerateStoryUseCase ===
/// Application Layer — Use Case
///
/// يمثّل هذا الكلاس الحد الفاصل بين شاشات Flutter وخدمات الذكاء الاصطناعي.
/// LAW 1 (من HIKAYATI_AGENT_MASTER_SPEC.md):
///   "UI does not generate stories. Screens collect input, trigger actions, show loading states."

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/features/story_engine/services/unified_engine.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:hikayati/features/library/services/library_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// استثناء خاص عندما يتجاوز المستخدم حد 5 قصص
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

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> requestData,
    {String? voice, bool saveToLibrary = true}
  ) async {
    debugPrint('[UseCase] GenerateStoryUseCase.execute() — بدء التوليد');

    // حساب التكلفة: الأساسي 20
    int totalCost = 20;
    if (requestData['useAvatar'] == true) totalCost += 10;
    if (voice == 'cloned') totalCost += 10;

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

    // خصم الكريدت
    try {
      await SupabaseService.deductCredits(totalCost, 'توليد قصة سينمائية');
    } catch (e) {
      throw Exception('فشلت عملية الخصم الداخلي: $e');
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
          final face = avatarData['face_description'] ?? 'وجه طفل';
          final clothes = avatarData['current_clothes'] ?? 'ملابس عادية';
          requestData['heroVisualDescription'] = 'الملامح: $face, يرتدي: $clothes';
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

    try {
      final storyData = await UnifiedEngine.generateStory(requestData, saveToLibrary: saveToLibrary);

      // --- حفظ الصوت في Supabase Storage ---
      final storyId = storyData['id'];
      final scenes = List<Map<String, dynamic>>.from(storyData['scenes'] ?? []);

      if (saveToLibrary && storyId != null && scenes.isNotEmpty) {
        debugPrint('[UseCase] بدء توليد الصوت وحفظه في story_audio bucket...');
        final isCloned = voice == 'cloned';
        final elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
        final prefs = await SharedPreferences.getInstance();
        final clonedVoiceId = prefs.getString('cloned_voice_id');

        for (int i = 0; i < scenes.length; i++) {
          final text = scenes[i]['text'] ?? '';
          if (text.isEmpty) continue;

          Uint8List? audioBytes;

          if (isCloned && elevenLabsKey.isNotEmpty && clonedVoiceId != null) {
            final url = Uri.parse(
                'https://api.elevenlabs.io/v1/text-to-speech/$clonedVoiceId');
            final res = await http.post(
              url,
              headers: {
                'xi-api-key': elevenLabsKey,
                'Content-Type': 'application/json'
              },
              body: jsonEncode({
                "text": text,
                "model_id": "eleven_multilingual_v2",
                "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
              }),
            );
            if (res.statusCode == 200) audioBytes = res.bodyBytes;
          } else {
            // التأكد من تثبيت الصوت النسائي أو الرجالي عبر الـ API
            // nova = صوت نسائي ممتاز مدعوم، onyx = رجالي
            String selectedVoiceParam = 'nova'; 
            if (voice == 'male' || voice == 'onyx') {
              selectedVoiceParam = 'onyx';
            } else if (voice == 'female' || voice == 'nova') {
              selectedVoiceParam = 'nova';
            }

            final url = Uri.parse(
                'https://text.pollinations.ai/tts/${Uri.encodeComponent(text)}?voice=$selectedVoiceParam');
            final res = await http.get(url);
            if (res.statusCode == 200) audioBytes = res.bodyBytes;
          }

          if (audioBytes != null) {
            try {
              final fileName = '$userId/${storyId}_scene_$i.mp3';
              await Supabase.instance.client.storage
                  .from('story_audio')
                  .uploadBinary(
                    fileName,
                    audioBytes,
                    fileOptions: const FileOptions(
                        contentType: 'audio/mpeg', upsert: true),
                  );
              scenes[i]['audio_url'] = Supabase.instance.client.storage
                  .from('story_audio')
                  .getPublicUrl(fileName);
              debugPrint('[UseCase] ✅ صوت المشهد $i محفوظ: ${scenes[i]['audio_url']}');
            } catch (storageError) {
              debugPrint('[UseCase] ⚠️ خطأ رفع صوت المشهد $i: $storageError');
            }
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
        debugPrint('[UseCase] ✅ تم الحفظ المالي للصوت بنجاح!');
      }

      debugPrint('[UseCase] اكتمل التوليد — عدد المشاهد: ${scenes.length}');
      return storyData;
    } catch (e, stack) {
      debugPrint('[UseCase] خطأ في التوليد: $e\n$stack');
      rethrow;
    }
  }
}
