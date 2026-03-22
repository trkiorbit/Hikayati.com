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
  String? _savedVoiceId;
  bool _useAvatar = false;
  bool _useClonedVoice = false; // الصوت المستنسخ أيقونة مستقلة
  String _selectedStyle = '3d-model';
  String _selectedVoice = 'alloy'; // خيار الراوي الافتراضي

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // تحميل الأفاتار المحفوظ
    final avatarJson = prefs.getString('saved_avatar');
    if (avatarJson != null && mounted) {
      setState(() => _savedAvatar = jsonDecode(avatarJson));
    }

    // تحميل الصوت المستنسخ
    final voiceId = prefs.getString('cloned_voice_id');
    if (mounted) setState(() => _savedVoiceId = voiceId);
  }

  void _generateStory() {
    final heroName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'البطل';
    final heroAge = _ageController.text.trim().isNotEmpty
        ? _ageController.text.trim()
        : '7';
    final storyTheme = _themeController.text.trim().isNotEmpty
        ? _themeController.text.trim()
        : 'مغامرة خيالية ومشوقة';

    final requestData = {
      'heroName':
          _useAvatar ? (_savedAvatar?['name'] ?? heroName) : heroName,
      'heroAge':
          _useAvatar ? (_savedAvatar?['age'] ?? heroAge) : heroAge,
      'heroVisualDescription':
          _useAvatar ? (_savedAvatar?['promptSnippet'] ?? '') : '',
      'useAvatar': _useAvatar,
      'avatarData': _useAvatar ? _savedAvatar : null,
      'storyStyle': storyTheme,
      'imageStyle': _selectedStyle,
    };

    // التحديد النهائي للصوت
    final voiceChoice =
        _useClonedVoice && _savedVoiceId != null ? 'cloned' : _selectedVoice;

    if (mounted) {
      context.push(
        '/intro-cinematic',
        extra: {'requestData': requestData, 'voice': voiceChoice},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = _savedAvatar != null;
    final hasClonedVoice = _savedVoiceId != null;

    // حساب التكلفة الجديدة: الأساسي 20
    int totalCost = 20;
    if (_useAvatar) totalCost += 10;
    if (_useClonedVoice && hasClonedVoice) totalCost += 10;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          'صمّم قصتك',
          style: TextStyle(
              color: AppColors.secondary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: AppColors.secondary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1) اسم البطل والعمر ──
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(_nameController, 'اسم بطل القصة',
                      Icons.person_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                      _ageController, 'العمر', Icons.cake_outlined,
                      isNumber: true),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 2) بطل الأفاتار (واضح — يعرض البطل الحقيقي) ──
            _buildAvatarSection(hasAvatar),
            const SizedBox(height: 20),

            // ── 3) مربع الراوي + أيقونة الصوت المستنسخ في نفس الصف ──
            _buildVoiceSection(hasClonedVoice),
            const SizedBox(height: 20),

            // ── 4) موضوع القصة ──
            _buildTextField(
                _themeController,
                'موضوع القصة (مثال: الشجاعة، الفضاء، الحيوانات)',
                Icons.auto_stories_outlined),
            const SizedBox(height: 20),

            // ── 5) النمط البصري ──
            _buildDropdown(
              label: 'النمط البصري',
              icon: Icons.palette_outlined,
              value: _selectedStyle,
              items: const {
                '3d-model': 'رسوم متحركة 3D (بيكسار)',
                'anime': 'أنمي ياباني',
                'water-color': 'ألوان مائية (كلاسيكي)',
              },
              onChanged: (v) => setState(() => _selectedStyle = v!),
            ),
            const SizedBox(height: 32),

            // ── 6) زر التوليد ──
            ElevatedButton.icon(
              onPressed: _generateStory,
              icon: const Icon(Icons.auto_awesome, size: 24),
              label: Text(
                'اصنع السحر!  •  $totalCost 💎',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── قسم الأفاتار ──
  Widget _buildAvatarSection(bool hasAvatar) {
    return GestureDetector(
      onTap: hasAvatar
          ? () => setState(() => _useAvatar = !_useAvatar)
          : () => context.push('/avatar-lab'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _useAvatar
              ? const Color(0xFF2D3748) // لون صلب بدلاً من شفافية
              : const Color(0xFF1C2333),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _useAvatar
                ? AppColors.secondary
                : const Color(0xFF4A5568),
            width: _useAvatar ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // أيقونة / صورة الأفاتار
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasAvatar ? AppColors.secondary : const Color(0xFF4A5568),
              ),
              child: Icon(
                hasAvatar ? Icons.face : Icons.add_a_photo,
                color: hasAvatar ? AppColors.deepBlack : Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            // معلومات الأفاتار
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAvatar
                        ? 'بطل القصة: ${_savedAvatar!['name'] ?? 'بطلي'}'
                        : 'اضغط لصناعة بطلك',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // أبيض صريح
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAvatar
                        ? (_useAvatar
                            ? '✅ مفعّل — سيظهر البطل في الصور'
                            : 'اضغط للتفعيل')
                        : 'لم يتم إنشاء بطل بعد',
                    style: TextStyle(
                      fontSize: 12,
                      color: _useAvatar
                          ? Colors.greenAccent
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            // Toggle
            if (hasAvatar)
              Switch(
                value: _useAvatar,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _useAvatar = v),
              ),
          ],
        ),
      ),
    );
  }

  // ── قسم الصوت: راوي + أيقونة الصوت المستنسخ ──
  Widget _buildVoiceSection(bool hasClonedVoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // قائمة الراوي — تُقفل عند تفعيل الصوت المستنسخ
        Expanded(
          child: IgnorePointer(
            ignoring: _useClonedVoice,
            child: Opacity(
              opacity: _useClonedVoice ? 0.4 : 1.0,
              child: _buildDropdown(
                label: 'صوت الراوي',
                icon: Icons.record_voice_over_outlined,
                value: _selectedVoice,
                items: const {
                  'alloy': 'راوي (متوازن)',
                  'nova': 'راوية (لطيفة)',
                  'onyx': 'راوي (عميق)',
                },
                onChanged: (v) => setState(() => _selectedVoice = v!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // أيقونة الصوت المستنسخ المستقلة
        GestureDetector(
          onTap: () {
            if (!hasClonedVoice) {
              context.push('/voice-clone');
            } else {
              setState(() => _useClonedVoice = !_useClonedVoice);
            }
          },
          child: Tooltip(
            message: hasClonedVoice
                ? (_useClonedVoice
                    ? 'صوتك مفعّل — اضغط للإلغاء'
                    : 'اضغط لاستخدام صوتك المستنسخ')
                : 'اضغط لإعداد صوتك أولاً',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _useClonedVoice
                    ? AppColors.secondary
                    : (hasClonedVoice
                        ? const Color(0xFF1C2333)
                        : Colors.grey[850]),
                border: Border.all(
                  color: _useClonedVoice
                      ? AppColors.primary
                      : (hasClonedVoice
                          ? AppColors.secondary
                          : Colors.grey.shade700),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.mic,
                color: _useClonedVoice
                    ? AppColors.primary
                    : (hasClonedVoice
                        ? AppColors.secondary
                        : Colors.grey[600]),
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── حقل إدخال موحّد بنمط داكن ──
  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
        filled: true,
        fillColor: const Color(0xFF1C2333),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
    );
  }

  // ── قائمة منسدلة موحّدة بنمط داكن ──
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1C2333),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
        filled: true,
        fillColor: const Color(0xFF1C2333),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value,
                  style: const TextStyle(color: Colors.white))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
