import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/core/theme/app_colors.dart';

class StoryCreationScreen extends StatefulWidget {
  const StoryCreationScreen({super.key});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _themeController = TextEditingController();

  Map<String, dynamic>? _savedAvatar;
  bool _useAvatar = false;
  String _selectedStyle = '3d-model';
  String _selectedVoice = 'alloy';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatar();
  }

  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarJson = prefs.getString('saved_avatar');
    if (avatarJson != null) {
      if (mounted) setState(() => _savedAvatar = jsonDecode(avatarJson));
    }
  }

  void _generateStory() async {
    final heroName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'البطل';
    final heroAge = _ageController.text.trim().isNotEmpty ? _ageController.text.trim() : '7';
    final storyTheme = _themeController.text.trim().isNotEmpty ? _themeController.text.trim() : 'مغامرة خيالية ومشوقة';

    setState(() => _isLoading = true);

    try {
      final requestData = {
        'heroName': _useAvatar ? (_savedAvatar!['name'] ?? heroName) : heroName,
        'heroAge': _useAvatar ? (_savedAvatar!['age'] ?? heroAge) : heroAge,
        'heroVisualDescription': _useAvatar ? (_savedAvatar!['promptSnippet'] ?? '') : '',
        'useAvatar': _useAvatar,
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
            // حقول الإدخال اليدوية المستردة
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم بطل القصة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'العمر',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // خيار تفعيل الأفاتار
            Container(
              decoration: BoxDecoration(
                color: _useAvatar ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _useAvatar ? AppColors.primary : Colors.grey),
              ),
              child: SwitchListTile(
                title: const Text('تفعيل النمط البصري: أفاتار', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_savedAvatar != null 
                  ? 'بطل الأفاتار الحالي: ${_savedAvatar!['name']}' 
                  : 'يتطلب صنع بطل مسبقاً من الشاشة الرئيسية'),
                value: _useAvatar,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  if (val && _savedAvatar == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اصنع بطلك أولاً من الشاشة الرئيسية!')),
                    );
                    return;
                  }
                  setState(() => _useAvatar = val);
                },
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
