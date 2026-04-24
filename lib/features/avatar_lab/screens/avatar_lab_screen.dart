import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikayati/features/avatar_lab/services/avatar_vision_service.dart';
import 'package:hikayati/application/use_cases/save_avatar_use_case.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';

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
  bool _isSavingCostume = false;

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

  Future<void> _showAvatarConsent() async {
    if (_selectedImage == null) return;
    bool accepted = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('موافقة إنشاء الأفاتار',
              style: TextStyle(color: AppColors.vibrantOrange, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قبل المتابعة، يرجى الإقرار بالتالي:',
                  style: TextStyle(color: AppColors.glassWhite, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _consentBullet('أنا ولي أمر الطفل أو لدي الإذن اللازم لاستخدام هذه الصورة.'),
                _consentBullet('ستُستخدم الصورة لإنشاء شخصية بصرية (أفاتار) داخل التطبيق فقط.'),
                _consentBullet('قد تُحفظ البيانات الناتجة لتحسين التجربة واسترجاع الشخصية لاحقًا.'),
                _consentBullet('يمكنني طلب حذف الأفاتار وبياناته في أي وقت من صفحة الحساب.'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: accepted,
                      activeColor: AppColors.vibrantOrange,
                      onChanged: (v) => setDialogState(() => accepted = v ?? false),
                    ),
                    Expanded(
                      child: Text('أوافق على الشروط أعلاه',
                          style: TextStyle(color: AppColors.glassWhite)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: accepted ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.vibrantOrange),
              child: const Text('متابعة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (result == true) _analyzeImage();
  }

  Widget _consentBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle_outline, size: 16, color: AppColors.vibrantOrange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.glassWhite, fontSize: 14, height: 1.5)),
          ),
        ],
      ),
    );
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
      await SaveAvatarUseCase().execute(avatarData);
      if (mounted) {
        setState(() {
          _currentAvatar = avatarData;
          _generatedOptions = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ البطل وخصم 20 ⭐ من رصيدك!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل الحفظ: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ));
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

  String _currentCostumeAr() {
    final en = _currentAvatar?['current_clothes'] ?? '';
    for (final c in SaveAvatarUseCase.costumes) {
      if (c['en'] == en) return c['ar']!;
    }
    return en.isNotEmpty ? en : 'غير محدد';
  }

  Future<void> _selectCostume(String costumeEn) async {
    if (_currentAvatar == null) return;
    setState(() => _isSavingCostume = true);
    try {
      final updated = await SaveAvatarUseCase().selectCostume(_currentAvatar!, costumeEn);
      if (mounted) {
        setState(() => _currentAvatar = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير الزي بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التغيير: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingCostume = false);
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

  /// بطاقة التكلفة — واضحة دائماً قبل وبعد الإنشاء
  Widget _buildPricingInfo() {
    const int creationCost = 20;
    const int usagePerStory = 10;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.vibrantOrange.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _pricingRow(
            label: 'إنشاء البطل (مرة واحدة)',
            value: '-$creationCost',
            isDeduction: true,
          ),
          const SizedBox(height: 6),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 8),
          const SizedBox(height: 6),
          _pricingRow(
            label: 'استخدام البطل في كل قصة',
            value: '-$usagePerStory',
            isDeduction: true,
          ),
        ],
      ),
    );
  }

  Widget _pricingRow({
    required String label,
    required String value,
    required bool isDeduction,
  }) {
    final color =
        isDeduction ? const Color(0xFFFF5252) : const Color(0xFF4CAF50);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: AppColors.glassWhite.withValues(alpha: 0.85),
                  fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 3),
        Icon(Icons.stars, color: color, size: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اصنع بطلك'),
        actions: const [CreditsBadge()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPricingInfo(),
            if (_currentAvatar != null) ...[
              Icon(Icons.check_circle, color: AppColors.success, size: 60),
              const SizedBox(height: 10),
              Text('لديك بطل محفوظ بالفعل!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.glassWhite)),
              const SizedBox(height: 20),
              if (_currentAvatar!['preview_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_currentAvatar!['preview_url'], height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              Text('الزي الحالي: ${_currentCostumeAr()}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.glassWhite)),
              const SizedBox(height: 16),
              Text('اختر زيًا لبطلك:', style: TextStyle(color: AppColors.vibrantOrange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SaveAvatarUseCase.costumes.map((c) {
                  final isSelected = _currentAvatar!['current_clothes'] == c['en'];
                  return ChoiceChip(
                    label: Text(c['ar']!, style: TextStyle(color: isSelected ? AppColors.deepNight : AppColors.glassWhite)),
                    selected: isSelected,
                    selectedColor: AppColors.vibrantOrange,
                    backgroundColor: AppColors.cardSurface,
                    onSelected: _isSavingCostume ? null : (selected) {
                      if (selected && !isSelected) _selectCostume(c['en']!);
                    },
                  );
                }).toList(),
              ),
              if (_isSavingCostume) ...[
                const SizedBox(height: 8),
                CircularProgressIndicator(color: AppColors.vibrantOrange),
              ],
              const Divider(height: 40),
              TextButton(
                onPressed: _isLoading ? null : _deleteAvatar,
                child: Text('حذف البطل والبدء من جديد', style: TextStyle(color: AppColors.error)),
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
            icon: Icon(Icons.check, color: AppColors.glassWhite),
            label: _isLoading ? CircularProgressIndicator(color: AppColors.glassWhite) : const Text('موافق، ابدأ التوليد 🚀', style: TextStyle(color: AppColors.glassWhite)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.primaryDeepPurple,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() { _analyzedData = null; _selectedImage = null; }),
            child: Text('إلغاء واختيار صورة أخرى', style: TextStyle(color: AppColors.error)),
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
              onPressed: _isLoading ? null : _showAvatarConsent,
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