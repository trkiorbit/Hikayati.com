import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/story_engine/services/story_generation_service.dart';

class StoryCreationScreen extends StatefulWidget {
  const StoryCreationScreen({super.key});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _themeController = TextEditingController();
  final _avatarController = TextEditingController();
  
  String _selectedStyle = '3d-model';
  String _selectedVoice = 'alloy';
  bool _isLoading = false;

  void _generateStory() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty || _themeController.text.isEmpty || _avatarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول لبدء السحر!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Navigate to cinema screen first to show the loading animation
      context.push('/cinema', extra: {
        'childName': _nameController.text,
        'age': int.parse(_ageController.text),
        'theme': _themeController.text,
        'avatarDescription': _avatarController.text,
        'style': _selectedStyle,
        'voice': _selectedVoice,
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم البطل/البطلة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'العمر', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _themeController,
              decoration: const InputDecoration(labelText: 'موضوع القصة (مثال: الشجاعة، الفضاء، الحيوانات)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
             TextField(
              controller: _avatarController,
              decoration: const InputDecoration(
                labelText: 'وصف شكل البطل (لضمان تطابق الصور)', 
                hintText: 'مثال: فتى بشعر أسود قصير، يرتدي نظارات وقميص أحمر',
                border: OutlineInputBorder()
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedStyle,
              decoration: const InputDecoration(labelText: 'النمط البصري', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: '3d-model', child: Text('رسوم متحركة 3D (Pixar)')),
                DropdownMenuItem(value: 'anime', child: Text('أنمي ياباني')),
                DropdownMenuItem(value: 'water-color', child: Text('ألوان مائية (كلاسيكي)')),
              ],
              onChanged: (val) => setState(() => _selectedStyle = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedVoice,
              decoration: const InputDecoration(labelText: 'صوت الراوي', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'alloy', child: Text('راوي (متوازن)')),
                DropdownMenuItem(value: 'nova', child: Text('راوية (لطيفة)')),
                DropdownMenuItem(value: 'onyx', child: Text('راوي (عميق)')),
                DropdownMenuItem(value: 'cloned', child: Text('صوت مستنسخ (يتطلب إعداد الأهل)')),
              ],
              onChanged: (val) {
                if (val == 'cloned') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('النسخ الصوتي يتطلب إعداد مسبق من حساب الوالدين.')),
                    );
                }
                setState(() => _selectedVoice = val!);
              },
            ),
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
              : ElevatedButton.icon(
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
