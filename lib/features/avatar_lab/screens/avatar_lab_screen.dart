import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikayati/features/avatar_lab/services/avatar_vision_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/network/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarLabScreen extends StatefulWidget {
  const AvatarLabScreen({super.key});

  @override
  State<AvatarLabScreen> createState() => _AvatarLabScreenState();
}

class _AvatarLabScreenState extends State<AvatarLabScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Map<String, dynamic>> _generatedOptions = [];
  Map<String, dynamic>? _analyzedData;
  Map<String, dynamic>? _currentAvatar;
  final TextEditingController _clothesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentAvatar();
  }

  Future<void> _fetchCurrentAvatar() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      // Destroy local cache forcefully on init check
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('saved_avatar')) {
        await prefs.remove('saved_avatar');
      }

      final response = await Supabase.instance.client.from('profiles').select('avatar_profile_summary').eq('user_id', userId).single();
      if (response['avatar_profile_summary'] != null && mounted) {
        setState(() => _currentAvatar = response['avatar_profile_summary']);
      }
    } catch (e) {
      debugPrint('[AvatarLab] No existing avatar found: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _generatedOptions = []; // تصفير الخيارات السابقة
        _analyzedData = null; // تصفير البيانات المحللة السابقة
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() => _isLoading = true);

    try {
      // 1. رفع الصورة إلى Supabase للحصول على رابط ثابت (يمنع خطأ 502)
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final String fileName = '$userId/source_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      try {
        await Supabase.instance.client.storage.from('avatars').upload(fileName, _selectedImage!);
      } catch (storageError) {
        throw Exception('فشل رفع الصورة. تأكد من إعداد Supabase Storage. ($storageError)');
      }
      final String uploadedImageUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

      // 2. إرسال الرابط للتحليل فقط واستخراج الوصف لمراجعته
      final analyzedData = await AvatarVisionService.analyzeImage(uploadedImageUrl);

      setState(() {
        _analyzedData = analyzedData;
      });
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _proceedToGenerate() async {
    if (_analyzedData == null) return;
    setState(() => _isLoading = true);
    try {
      final options = await AvatarVisionService.generateOptionsFromData(_analyzedData!);
      setState(() {
        _generatedOptions = options;
      });
      if (options.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل توليد الصور، يرجى المحاولة مرة أخرى.')));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvatar(Map<String, dynamic> avatarData) async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('يجب تسجيل الدخول أولاً');

      // الصورة الأصلية مرفوعة مسبقاً، نأخذ رابطها المرجعي
      final String sourceImageUrl = avatarData['reference_image_url'] ?? '';

      // 1. خصم 20 كريدت (تكلفة إنشاء الأفاتار لأول مرة)
      await SupabaseService.deductCredits(20, 'إنشاء بطل جديد');

      // 2. تحديث البيانات بالرابط
      final dataToSave = Map<String, dynamic>.from(avatarData);
      dataToSave['reference_image_url'] = sourceImageUrl;

      await Supabase.instance.client.from('profiles').update({
        'avatar_profile_summary': dataToSave,
      }).eq('user_id', userId);

      if (mounted) {
        setState(() {
          _currentAvatar = dataToSave;
          _generatedOptions = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ البطل وخصم 20 جوهرة!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // حذف بيانات البطل فعلياً من قاعدة البيانات
      await Supabase.instance.client.from('profiles').update({
        'avatar_profile_summary': null,
      }).eq('user_id', userId);

      // تدمير الكاش المحلي لضمان النظافة
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_avatar');

      if (mounted) {
        setState(() {
          _currentAvatar = null;
          _generatedOptions = [];
          _selectedImage = null;
        _analyzedData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف البطل السابق. يمكنك الآن صنع بطل جديد!')),
        );
      }
    } catch (e) {
      debugPrint('[AvatarLab] Error deleting avatar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeClothes() async {
    if (_clothesController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('يجب تسجيل الدخول أولاً');

      // خصم 5 كريدت
      await SupabaseService.deductCredits(5, 'تغيير ملابس البطل');

      final updatedAvatar = Map<String, dynamic>.from(_currentAvatar!);
      updatedAvatar['current_clothes'] = _clothesController.text.trim();

      await Supabase.instance.client.from('profiles').update({
        'avatar_profile_summary': updatedAvatar,
      }).eq('user_id', userId);

      if (mounted) {
        setState(() {
          _currentAvatar = updatedAvatar;
          _clothesController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تغيير الملابس وخصم 5 جواهر!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التغيير: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('الكاميرا'),
            onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('المعرض'),
            onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
          ),
        ],
      ),
    );
  }

  Widget _buildPromptBox(String title, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.blueAccent),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ!')));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اصنع بطلك')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_currentAvatar != null) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 10),
              const Text('لديك بطل محفوظ بالفعل!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_currentAvatar!['preview_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_currentAvatar!['preview_url'], height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              Text('الملابس الحالية: ${_currentAvatar!['current_clothes'] ?? 'غير محدد'}', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: _clothesController,
                decoration: const InputDecoration(
                  labelText: 'ماذا تريد أن يرتدي بطلك الآن؟',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _changeClothes,
                icon: const Icon(Icons.checkroom),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تغيير الملابس (خصم 5 جواهر)'),
              ),
              const Divider(height: 40),
              TextButton(
                onPressed: _isLoading ? null : _deleteAvatar,
                child: const Text('حذف البطل والبدء من جديد', style: TextStyle(color: Colors.redAccent)),
              ),
        ] else if (_analyzedData != null && _generatedOptions.isEmpty) ...[
          const Text('مراجعة الوصف البصري للبطل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('سيتم إرسال هذا الوصف لمولد الصور. يمكنك نسخه للرجوع إليه.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          _buildPromptBox('الوصف باللغة الإنجليزية (الفعلي)', _analyzedData!['english_prompt'] ?? ''),
          const SizedBox(height: 15),
          _buildPromptBox('الترجمة العربية', _analyzedData!['arabic_prompt'] ?? ''),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _proceedToGenerate,
            icon: const Icon(Icons.check),
            label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('موافق، ابدأ التوليد 🚀'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() { _analyzedData = null; _selectedImage = null; }),
            child: const Text('إلغاء واختيار صورة أخرى', style: TextStyle(color: Colors.redAccent)),
          ),
            ] else if (_generatedOptions.isEmpty) ...[
              // منطقة رفع الصورة
              GestureDetector(
                onTap: () => _showImageSourceDialog(),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.white),
                            SizedBox(height: 10),
                            Text('اضغط لرفع صورة طفلك', style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedImage != null)
                ElevatedButton(
              onPressed: _isLoading ? null : _analyzeImage,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.purple,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تحليل الصورة واستخراج الوصف 🔍'),
                ),
            ] else ...[
              // عرض الخيارات
              const Text(
                'اختر بطلك المفضل:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _generatedOptions.length,
                itemBuilder: (context, index) {
                  final option = _generatedOptions[index];
                  return Card(
                        color: Colors.grey[900],
                        child: InkWell(
                          onTap: () => _saveAvatar(option),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      option['preview_url'] ?? '',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, color: Colors.red, size: 40),
                                            SizedBox(height: 4),
                                            Text('فشل التحميل', style: TextStyle(color: Colors.white, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('اختيار هذا البطل', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}