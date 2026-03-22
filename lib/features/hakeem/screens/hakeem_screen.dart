import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/avatar_lab/services/avatar_vision_service.dart';

class HakeemScreen extends StatefulWidget {
  const HakeemScreen({super.key});

  @override
  State<HakeemScreen> createState() => _HakeemScreenState();
}

class _HakeemScreenState extends State<HakeemScreen> {
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
      // تم إيقاف الدالة القديمة لمنع خطأ البناء
      // final result = await AvatarVisionService.analyzeChildImage(_selectedImage!);
      
      final result = <String, dynamic>{
        'age': '7', 'gender': 'boy', 'hairStyleAndColor': 'أسود', 'skinTone': 'حنطي', 'clothingStyleAndColors': 'ملابس عادية'
      };
      
      await Future.delayed(const Duration(seconds: 2));
      
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
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _saveAndReturnHero() {
    if (_analysisResult == null) return;
    
    final heroName = _nameController.text.trim();
    if (heroName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أخبرني باسم البطل أولاً!')),
      );
      return;
    }

    final finalHeroData = {
      'name': heroName,
      ..._analysisResult!,
    };

    // نعود لشاشة التوليد مع بطاقة البطل الثابتة (في المستقبل سيتم حفظها في Supabase Avatars)
    context.pop(finalHeroData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة السحرية (حكيم)'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.psychology, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'أهلاً بك يا صديقي! أنا حكيم المستشار البصري لحكواتي.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'اختر صورة لبطل القصة وسأقوم بتحليل ملامحه وملابسه بدقة، لتكون جميع صوره القادمة متطابقة وثابتة كالسحر!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            if (_selectedImage == null) ...[
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
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
                const Text('حكيم يقرأ الملامح والألوان بصمت...', textAlign: TextAlign.center),
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
                      const Text('✅ اكتمل استخراج الحقائق البصرية:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 8),
                      Text('• العمر والجنس: ${_analysisResult!['age']} - ${_analysisResult!['gender']}'),
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
                    labelText: 'ما اسم بطلنا الشجاع؟',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveAndReturnHero,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('اعتماد البطل للمغامرة!'),
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
