import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/theme/app_colors.dart';

class StoryCreationScreen extends StatefulWidget {
  const StoryCreationScreen({super.key});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  final _themeController = TextEditingController();

  Map<String, dynamic>? _selectedHero; // يمثل البطل المختار

  String _selectedStyle = '3d-model';
  String _selectedVoice = 'alloy';
  bool _isLoading = false;

  void _generateStory() async {
    // التأكد من اختيار بطل أولاً
    if (_selectedHero == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار بطلك أولاً أو طلب حكيم لصنع بطل جديد.')),
      );
      return;
    }

    final heroName = _selectedHero!['name'] ?? 'بطل حكواتي';
    final heroAge = _selectedHero!['age'] ?? '7';
    final storyTheme = _themeController.text.trim().isNotEmpty ? _themeController.text.trim() : 'مغامرة خيالية ومشوقة';

    setState(() => _isLoading = true);

    try {
      // 1. تجميع بيانات الطلب للمحرك مع الوصف البصري المستخرج من حكيم
      final requestData = {
        'heroName': heroName,
        'heroAge': heroAge,
        'heroVisualDescription': _selectedHero!['promptSnippet'] ?? '', // البصمة البصرية الثابتة
        'storyStyle': storyTheme,
        'imageStyle': _selectedStyle,
      };

      // الانتقال مباشرة إلى شاشة المقدمة (التوليد يحدث بداخلها في الخلفية)
      if (mounted) {
        context.push(
          '/intro-cinematic',
          extra: {'requestData': requestData, 'voice': _selectedVoice},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بطاقة بطل القصة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم اختيار البطل (تمهيد لحكيم والأفاتار)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedHero == null ? 'لم تختر بطلك بعد!' : 'البطل: ${_selectedHero!['name']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedHero == null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final heroData = await context.push('/hakeem');
                        if (heroData != null && heroData is Map<String, dynamic>) {
                          setState(() => _selectedHero = heroData);
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('اطلب من "حكيم" تجهيز بطل جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.secondary,
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final heroData = await context.push('/hakeem');
                        if (heroData != null && heroData is Map<String, dynamic>) {
                          setState(() => _selectedHero = heroData);
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('تغيير البطل'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _themeController,
              decoration: const InputDecoration(
                labelText: 'موضوع القصة (مثال: الشجاعة، الفضاء، الحيوانات)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedStyle,
              decoration: const InputDecoration(
                labelText: 'النمط البصري',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: '3d-model',
                  child: Text('رسوم متحركة 3D (Pixar)'),
                ),
                DropdownMenuItem(value: 'anime', child: Text('أنمي ياباني')),
                DropdownMenuItem(
                  value: 'water-color',
                  child: Text('ألوان مائية (كلاسيكي)'),
                ),
              ],
              onChanged: (val) => setState(() => _selectedStyle = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedVoice,
              decoration: const InputDecoration(
                labelText: 'صوت الراوي',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'alloy', child: Text('راوي (متوازن)')),
                DropdownMenuItem(value: 'nova', child: Text('راوية (لطيفة)')),
                DropdownMenuItem(value: 'onyx', child: Text('راوي (عميق)')),
                DropdownMenuItem(
                  value: 'cloned',
                  child: Text('صوت مستنسخ (يتطلب إعداد الأهل)'),
                ),
              ],
              onChanged: (val) {
                if (val == 'cloned') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'النسخ الصوتي يتطلب إعداد مسبق من حساب الوالدين.',
                      ),
                    ),
                  );
                }
                setState(() => _selectedVoice = val!);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _generateStory,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('اصنع السحر! (يخصم 10 جواهر)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
