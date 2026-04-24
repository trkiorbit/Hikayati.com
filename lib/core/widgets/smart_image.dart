import 'package:flutter/material.dart';

/// Widget يختار بين Image.asset و Image.network تلقائياً حسب المسار:
/// - إذا path يبدأ بـ "assets/" → Image.asset
/// - غير ذلك (http://, https://, data:) → Image.network
///
/// يحافظ على نفس واجهة Image تقريباً ويوفّر errorBuilder + loadingBuilder موحّدين.
class SmartImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? loadingPlaceholder;
  final WidgetBuilder? errorPlaceholder;

  const SmartImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingPlaceholder,
    this.errorPlaceholder,
  });

  /// التحقق من كون المسار asset محلي
  static bool isAsset(String? p) {
    if (p == null || p.isEmpty) return false;
    return p.startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    final p = path;

    if (p == null || p.isEmpty) {
      return _buildError(context);
    }

    if (isAsset(p)) {
      return Image.asset(
        p,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildError(context),
      );
    }

    return Image.network(
      p,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (_, child, prog) {
        if (prog == null) return child;
        return loadingPlaceholder?.call(context) ?? _defaultLoading();
      },
      errorBuilder: (_, __, ___) => _buildError(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return errorPlaceholder?.call(context) ?? _defaultError();
  }

  Widget _defaultLoading() {
    return Container(
      color: const Color(0xFF252540),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      color: const Color(0xFF252540),
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white30, size: 48),
      ),
    );
  }
}
