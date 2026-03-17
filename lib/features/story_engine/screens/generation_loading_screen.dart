import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/story_engine/services/unified_engine.dart';

class GenerationLoadingScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final String voice;

  const GenerationLoadingScreen({
    super.key,
    required this.requestData,
    required this.voice,
  });

  @override
  State<GenerationLoadingScreen> createState() =>
      _GenerationLoadingScreenState();
}

class _GenerationLoadingScreenState extends State<GenerationLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  Future<void> _startGeneration() async {
    try {
      // 1. استدعاء المحرك لتوليد القصة
      final storyData = await UnifiedEngine.generateStory(widget.requestData);

      // 2. التحقق من نجاح العملية قبل الانتقال
      if (storyData['scenes'] != null &&
          storyData['scenes'].isNotEmpty &&
          storyData['scenes'][0]['text'].toString().contains('عذرًا')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(storyData['scenes'][0]['text'])),
          );
          context.pop(); // العودة إلى شاشة الإنشاء
        }
        return;
      }

      // 3. الانتقال إلى شاشة المقدمة السينمائية مع بيانات القصة الجاهزة
      if (mounted) {
        context.pushReplacement(
          '/intro-cinematic',
          extra: {'storyData': storyData, 'voice': widget.voice},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}')),
        );
        context.pop(); // العودة
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            const Text(
              'جاري نسج أحداث القصة...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'نجهز لك بطلنا "${widget.requestData['heroName']}"',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
