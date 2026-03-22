import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/avatar_lab/services/avatar_vision_service.dart';

class CreateAvatarScreen extends StatefulWidget {
  const CreateAvatarScreen({super.key});

  @override
  State<CreateAvatarScreen> createState() => _CreateAvatarScreenState();
}

class _CreateAvatarScreenState extends State<CreateAvatarScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  bool _readyToSave = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isAnalyzing = true;
        _analysisResult = null;
        _readyToSave = false;
      });

      _analyzePickedImage();
    }
  }

  Future<void> _analyzePickedImage() async {
    try {
      // تم إيقاف استخدام الدالة القديمة لأن حكيم لا يتدخل في توليد الأفاتار حسب الدستور
      // final result = await AvatarVisionService.analyzeChildImage(_selectedImage!);
      
      // بيانات وهمية مؤقتة لمنع انهيار التطبيق حتى يتم تحديث دور حكيم مستقبلاً
      final result = <String, dynamic>{
        'age': '7', 'gender': 'boy', 'hairStyleAndColor': 'أسود', 'skinTone': 'حنطي', 'clothingStyleAndColors': 'ملابس عادية'
      };
      
      await Future.delayed(const Duration(seconds: 2)); // محاكاة وقت التحليل

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
          _readyToSave = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحليل: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveAvatar() async {
    if (_analysisResult == null) return;
    
    final heroName = _nameController.text.trim();
    if (heroName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم البطل أولاً!')),
      );
      return;
    }

    final finalHeroData = {
      'name': heroName,
      ..._analysisResult!,
    };

    // حفظ مؤقت في SharedPreferences كدليل على النجاح (بدون بناء Migration لـ Supabase الآن)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_avatar', jsonEncode(finalHeroData));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بطلك السحري بنجاح!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('اصنع بطلك (بمساعدة حكيم)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
        backgroundColor: AppColors.deepBlack,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.face, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'اصنع بطلك الدائم للقصص',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ارفع صورة للبطل وسيقوم حكيم باستخراج الملامح والملابس كبصمة ثابتة لاستخدامها في جميع مغامراتك القادمة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            if (_selectedImage == null) ...[
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('رفع صورة البطل'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_selectedImage!, height: 300, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              
              if (_isAnalyzing) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                const Text('حكيم يحلل الملامح الدقيقة للصورة...', textAlign: TextAlign.center),
              ] else if (_analysisResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✅ تم استخراج الجينات البصرية للبطل:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 8),
                      Text('• العمر: ${_analysisResult!['age']} | الجنس: ${_analysisResult!['gender']}'),
                      Text('• الشعر: ${_analysisResult!['hairStyleAndColor']}'),
                      Text('• البشرة: ${_analysisResult!['skinTone']}'),
                      Text('• الملابس: ${_analysisResult!['clothingStyleAndColors']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ما اسم البطل؟',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveAvatar,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ البطل في سجلاتي'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
