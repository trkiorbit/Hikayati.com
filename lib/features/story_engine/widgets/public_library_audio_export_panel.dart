import 'package:flutter/material.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/story_engine/services/public_library_audio_export_service.dart';

/// لوحة تصدير صوت المكتبة العامة — تظهر في bottom sheet
/// تُستخدم فقط في وضع المطوّر (PUBLIC_LIBRARY_AUDIO_EXPORT=true)
class PublicLibraryAudioExportPanel extends StatefulWidget {
  final String slug;
  final String title;
  final List<dynamic> scenes;

  const PublicLibraryAudioExportPanel({
    super.key,
    required this.slug,
    required this.title,
    required this.scenes,
  });

  @override
  State<PublicLibraryAudioExportPanel> createState() =>
      _PublicLibraryAudioExportPanelState();
}

class _PublicLibraryAudioExportPanelState
    extends State<PublicLibraryAudioExportPanel> {
  late List<SceneAudioResult> _results;
  bool _isRunning = false;
  String? _manifestPath;

  @override
  void initState() {
    super.initState();
    _results = [];
    for (int i = 0; i < widget.scenes.length; i++) {
      final scene = widget.scenes[i];
      String text = '';
      if (scene is Map) {
        text = scene['text']?.toString() ?? '';
      }
      _results.add(SceneAudioResult(
        sceneNumber: i + 1,
        text: text,
      ));
    }
  }

  Future<void> _generateAll({bool overwrite = false}) async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _manifestPath = null;
      // reset all to pending if overwrite
      if (overwrite) {
        for (final r in _results) {
          r.status = SceneAudioStatus.pending;
          r.localPath = null;
          r.errorMessage = null;
        }
      }
    });

    int savedCount = 0;
    for (final result in _results) {
      // تحديث UI قبل التوليد
      setState(() => result.status = SceneAudioStatus.generating);

      final ok = await PublicLibraryAudioExportService.generateScene(
        slug: widget.slug,
        result: result,
        overwrite: overwrite,
      );

      // تحديث UI بعد التوليد (status أصبح saved/failed/skipped)
      if (mounted) setState(() {});

      if (ok) savedCount++;
    }

    // كتابة manifest
    final manifestPath = await PublicLibraryAudioExportService.writeManifest(
      slug: widget.slug,
      title: widget.title,
      scenes: _results,
    );

    // تسجيل usage (آمن)
    await PublicLibraryAudioExportService.logUsage(
      slug: widget.slug,
      scenesGenerated: savedCount,
    );

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _manifestPath = manifestPath;
    });

    final allOk = _results.every((r) =>
        r.status == SceneAudioStatus.saved ||
        r.status == SceneAudioStatus.skipped);

    final firstFailed =
        _results.firstWhere((r) => r.status == SceneAudioStatus.failed,
            orElse: () => SceneAudioResult(sceneNumber: 0, text: ''));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: allOk ? Colors.green[700] : Colors.red[700],
        duration: const Duration(seconds: 6),
        content: Text(
          allOk
              ? '✅ تم تصدير ${_results.length} مشاهد\nManifest: $manifestPath'
              : '❌ فشل المشهد ${firstFailed.sceneNumber}: ${firstFailed.errorMessage ?? "غير معروف"}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Color _statusColor(SceneAudioStatus s) {
    switch (s) {
      case SceneAudioStatus.pending:
        return Colors.grey;
      case SceneAudioStatus.generating:
        return Colors.amber;
      case SceneAudioStatus.saved:
        return Colors.greenAccent;
      case SceneAudioStatus.skipped:
        return Colors.blueAccent;
      case SceneAudioStatus.failed:
        return Colors.redAccent;
    }
  }

  String _statusLabel(SceneAudioStatus s) {
    switch (s) {
      case SceneAudioStatus.pending:
        return 'pending';
      case SceneAudioStatus.generating:
        return 'generating';
      case SceneAudioStatus.saved:
        return 'saved ✅';
      case SceneAudioStatus.skipped:
        return 'skipped (موجود)';
      case SceneAudioStatus.failed:
        return 'failed ❌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedCount = _results
        .where((r) =>
            r.status == SceneAudioStatus.saved ||
            r.status == SceneAudioStatus.skipped)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF15101F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.developer_mode,
                  color: AppColors.vibrantOrange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Public Library Audio Export — Dev Only',
                style: TextStyle(
                  color: AppColors.vibrantOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Text(
            'Story: ${widget.title}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            'Slug: ${widget.slug}    •    Scenes: ${_results.length}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Voice: ${PublicLibraryAudioExportService.defaultVoice}    •    No credit deduction.',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // قائمة المشاهد
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final r = _results[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1530),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${r.sceneNumber}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.fileName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (r.errorMessage != null)
                              Text(
                                r.errorMessage!,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // status indicator
                      if (r.status == SceneAudioStatus.generating)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.amber,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(r.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _statusLabel(r.status),
                            style: TextStyle(
                              color: _statusColor(r.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Manifest path
          if (_manifestPath != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manifest: $savedCount/${_results.length} ✅',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    _manifestPath!,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isRunning ? null : () => _generateAll(overwrite: false),
                  icon: _isRunning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download, size: 16),
                  label: Text(
                    _isRunning ? 'يولّد...' : 'توليد صوت المكتبة العامة',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantOrange,
                    foregroundColor: AppColors.deepNight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'إعادة التوليد (overwrite)',
                onPressed:
                    _isRunning ? null : () => _generateAll(overwrite: true),
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: لا يخصم كريدت. لا يرفع لـ Supabase تلقائياً. الملفات تُحفظ محلياً فقط.',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
