import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Public Library Audio Export Service — Developer-only
/// ═══════════════════════════════════════════════════════════════════
///
/// خدمة تصدير صوتيات قصص المكتبة العامة من النص الجاهز.
/// تعمل **فقط** عندما يُمرّر:
///   --dart-define=PUBLIC_LIBRARY_AUDIO_EXPORT=true
///
/// لا تُستدعى من تدفق المستخدم العادي.
/// لا تخصم كريدت.
/// لا ترفع لـ Supabase تلقائياً.
/// ═══════════════════════════════════════════════════════════════════

enum SceneAudioStatus { pending, generating, saved, failed, skipped }

class SceneAudioResult {
  final int sceneNumber;
  final String text;
  SceneAudioStatus status;
  String? localPath;
  String? errorMessage;

  SceneAudioResult({
    required this.sceneNumber,
    required this.text,
    this.status = SceneAudioStatus.pending,
    this.localPath,
    this.errorMessage,
  });

  String get fileName => 'scene_${sceneNumber.toString().padLeft(2, '0')}.mp3';

  Map<String, dynamic> toManifestEntry() => {
        'scene': sceneNumber,
        'text': text,
        'audio_file': fileName,
        'local_path': localPath ?? '',
        'status': status.name,
        if (errorMessage != null) 'error': errorMessage,
      };
}

class PublicLibraryAudioExportService {
  /// تفعيل الوضع — يُفعَّل فقط بـ dart-define
  static const bool isExportModeEnabled =
      bool.fromEnvironment('PUBLIC_LIBRARY_AUDIO_EXPORT', defaultValue: false);

  /// الصوت الافتراضي للراوي العربي الدافئ للأطفال
  /// (متوافق مع TTS Pollinations المُستخدم سابقاً للقصة العادية)
  static const String defaultVoice = 'fable';

  /// سبب التسجيل في ai_usage_log (إن وُجد الجدول)
  static const String logReason = 'public_library_audio_export';

  // ─────────────────────────────────────────────────────────────────
  // مسار الإخراج (Windows: مسار ثابت / Android+iOS: documents directory)
  // ─────────────────────────────────────────────────────────────────
  static Future<String> getOutputDirectory(String slug) async {
    if (Platform.isWindows) {
      return 'D:\\Hikayati.com\\content_studio\\public_library\\05_audio\\$slug';
    }
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/public_library_exports/$slug/audio';
  }

  static String _join(String dir, String file) {
    if (Platform.isWindows) return '$dir\\$file';
    return '$dir/$file';
  }

  // ─────────────────────────────────────────────────────────────────
  // تحميل bytes من Pollinations TTS
  // ─────────────────────────────────────────────────────────────────
  static Future<Uint8List?> _downloadTts(String text,
      {String voice = defaultVoice}) async {
    if (text.trim().isEmpty) return null;
    try {
      final apiKey = dotenv.env['POLLINATIONS_AUDIO_API_KEY'] ?? '';
      final encoded = Uri.encodeComponent(text);
      final url = 'https://gen.pollinations.ai/audio/$encoded'
          '?voice=$voice'
          '&model=elevenlabs'
          '${apiKey.isNotEmpty ? "&key=$apiKey" : ""}';

      debugPrint('[AudioExport] downloading scene (voice=$voice, len=${text.length})');

      final res = await http
          .get(Uri.parse(url), headers: {
            'User-Agent': 'Mozilla/5.0 Hikayati AudioExport',
          })
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 200 && res.bodyBytes.length > 500) {
        return res.bodyBytes;
      }
      debugPrint('[AudioExport] failed: status=${res.statusCode} size=${res.bodyBytes.length}');
      return null;
    } catch (e) {
      debugPrint('[AudioExport] download error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // توليد صوت لمشهد واحد + الحفظ — يُحدّث result.status مباشرة
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> generateScene({
    required String slug,
    required SceneAudioResult result,
    bool overwrite = false,
  }) async {
    final dir = await getOutputDirectory(slug);
    try {
      await Directory(dir).create(recursive: true);
    } catch (e) {
      result.status = SceneAudioStatus.failed;
      result.errorMessage = 'فشل إنشاء المجلد: $e';
      return false;
    }

    final fullPath = _join(dir, result.fileName);
    final file = File(fullPath);

    // تخطّي إذا الملف موجود ولا overwrite
    if (!overwrite && await file.exists()) {
      result.status = SceneAudioStatus.skipped;
      result.localPath = fullPath;
      debugPrint('[AudioExport] scene ${result.sceneNumber} exists → skipped');
      return true;
    }

    result.status = SceneAudioStatus.generating;

    final bytes = await _downloadTts(result.text);
    if (bytes == null) {
      result.status = SceneAudioStatus.failed;
      result.errorMessage = 'فشل تحميل الصوت من Pollinations';
      return false;
    }

    try {
      await file.writeAsBytes(bytes);
      result.localPath = fullPath;
      result.status = SceneAudioStatus.saved;
      debugPrint('[AudioExport] ✅ scene ${result.sceneNumber} saved → $fullPath');
      return true;
    } catch (e) {
      result.status = SceneAudioStatus.failed;
      result.errorMessage = 'فشل حفظ الملف: $e';
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // كتابة manifest JSON
  // ─────────────────────────────────────────────────────────────────
  static Future<String> writeManifest({
    required String slug,
    required String title,
    required List<SceneAudioResult> scenes,
  }) async {
    final dir = await getOutputDirectory(slug);
    await Directory(dir).create(recursive: true);

    final manifestPath = _join(dir, 'audio_manifest.json');

    final manifest = {
      'slug': slug,
      'title': title,
      'generated_at': DateTime.now().toIso8601String(),
      'voice': defaultVoice,
      'tts_provider': 'pollinations.elevenlabs',
      'scenes': scenes.map((s) => s.toManifestEntry()).toList(),
    };

    final encoder = const JsonEncoder.withIndent('  ');
    await File(manifestPath).writeAsString(encoder.convert(manifest));
    debugPrint('[AudioExport] ✅ manifest written → $manifestPath');

    return manifestPath;
  }

  // ─────────────────────────────────────────────────────────────────
  // تسجيل الاستخدام في ai_usage_log (آمن — لا يكسر إذا الجدول غير موجود)
  // ─────────────────────────────────────────────────────────────────
  static Future<void> logUsage({
    required String slug,
    required int scenesGenerated,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('ai_usage_log').insert({
        'user_id': userId,
        'reason': logReason,
        'metadata': {
          'slug': slug,
          'scenes_generated': scenesGenerated,
        },
      });
      debugPrint('[AudioExport] usage logged: reason=$logReason');
    } catch (e) {
      // الجدول قد لا يكون موجوداً — لا تكسر التدفق
      debugPrint('[AudioExport] log skipped (table may not exist): $e');
    }
  }
}
