import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/features/library/services/library_service.dart';

enum CreditBadgeType { deduction, addition, balance }

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
  bool _useClonedVoice = false;
  String _selectedStyle = '3d-model';
  String _selectedVoice = 'echo';

  final _libraryService = LibraryService();

  // التكلفة الفعلية (تطابق generate_story_use_case.dart)
  static const int _baseStoryCost = 10;
  static const int _avatarUsageCost = 10;
  static const int _clonedVoiceUsageCost = 20;

  int get _totalCost {
    int total = _baseStoryCost;
    if (_useAvatar) total += _avatarUsageCost;
    if (_useClonedVoice) total += _clonedVoiceUsageCost;
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('avatar_profile_summary')
            .eq('user_id', userId)
            .single();
        if (response['avatar_profile_summary'] != null && mounted) {
          setState(() => _savedAvatar = response['avatar_profile_summary']);
        }
      }
    } catch (e) {
      debugPrint('[StoryCreation] لم يتم العثور على بطل محفوظ: $e');
    }

    final voiceId = prefs.getString('cloned_voice_id');
    if (mounted) setState(() => _savedVoiceId = voiceId);
  }

  void _generateStory() async {
    final ageText = _ageController.text.trim();
    if (ageText.isNotEmpty) {
      final age = int.tryParse(ageText);
      if (age == null || age < 3 || age > 12) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('التطبيق مخصص للأطفال من 3 إلى 12 سنة'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final count = await _libraryService.getStoryCount();
    if (count >= 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مكتبتك ممتلئة. احذف قصة واحدة على الأقل أولاً.'),
          backgroundColor: Colors.orange,
        ),
      );
      context.push('/private-library');
      return;
    }

    final heroName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'البطل';
    final heroAge = ageText.isNotEmpty ? ageText : '7';
    final storyTheme = _themeController.text.trim().isNotEmpty
        ? _themeController.text.trim()
        : 'مغامرة خيالية ومشوقة';

    final requestData = {
      'heroName': _useAvatar ? (_savedAvatar?['name'] ?? heroName) : heroName,
      'heroAge': _useAvatar ? (_savedAvatar?['age'] ?? heroAge) : heroAge,
      'heroVisualDescription':
          _useAvatar ? (_savedAvatar?['promptSnippet'] ?? '') : '',
      'useAvatar': _useAvatar,
      'avatarData': _useAvatar ? _savedAvatar : null,
      'storyStyle': storyTheme,
      'imageStyle': _selectedStyle,
    };

    final voiceChoice =
        _useClonedVoice && _savedVoiceId != null ? 'cloned' : _selectedVoice;

    if (mounted) {
      context.push('/intro-cinematic', extra: {
        'requestData': requestData,
        'voice': voiceChoice,
        'saveToLibrary': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = _savedAvatar != null;
    final hasClonedVoice = _savedVoiceId != null;

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('صمّم قصتك',
            style: TextStyle(
                color: AppColors.vibrantOrange, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNight,
        foregroundColor: AppColors.vibrantOrange,
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
                  child: _buildTextField(
                      _nameController, 'اسم بطل القصة', Icons.person_outline),
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
            const SizedBox(height: 16),

            // ── 2) بطل الأفاتار ──
            _buildFeatureCard(
              icon: hasAvatar ? Icons.face : Icons.add_a_photo,
              title: hasAvatar ? 'البطل السحري جاهز!' : 'اصنع بطلك أولاً',
              subtitle: hasAvatar
                  ? (_useAvatar
                      ? 'مفعّل — سيظهر البطل في صور القصة'
                      : 'اضغط لتفعيل البطل في القصة')
                  : 'لم يتم إنشاء بطل بعد',
              isActive: _useAvatar,
              isAvailable: hasAvatar,
              onTap: hasAvatar
                  ? () => setState(() => _useAvatar = !_useAvatar)
                  : () => context.push('/avatar-lab'),
              onToggle: hasAvatar
                  ? (v) => setState(() => _useAvatar = v)
                  : null,
            ),
            const SizedBox(height: 12),

            // ── 3) الصوت المستنسخ ──
            _buildFeatureCard(
              icon: hasClonedVoice ? Icons.record_voice_over : Icons.mic_none,
              title: hasClonedVoice
                  ? 'صوتك المستنسخ جاهز!'
                  : 'استنسخ صوتك أولاً',
              subtitle: hasClonedVoice
                  ? (_useClonedVoice
                      ? 'مفعّل — القصة ستُروى بصوتك'
                      : 'اضغط لتفعيل صوتك في القصة')
                  : 'لم يتم إنشاء صوت مستنسخ بعد',
              isActive: _useClonedVoice,
              isAvailable: hasClonedVoice,
              onTap: hasClonedVoice
                  ? () => setState(() => _useClonedVoice = !_useClonedVoice)
                  : () => context.push('/voice-clone'),
              onToggle: hasClonedVoice
                  ? (v) => setState(() => _useClonedVoice = v)
                  : null,
            ),

            // ── صوت الراوي (يظهر فقط إذا الصوت المستنسخ غير مفعّل) ──
            if (!_useClonedVoice) ...[
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'صوت الراوي',
                icon: Icons.record_voice_over_outlined,
                value: _selectedVoice,
                items: const {
                  'echo': 'رجالي قصصي',
                  'fable': 'نسائي',
                  'onyx': 'رجالي عميق',
                },
                onChanged: (v) => setState(() => _selectedVoice = v!),
              ),
            ],
            const SizedBox(height: 16),

            // ── 4) موضوع القصة ──
            _buildTextField(
                _themeController,
                'موضوع القصة (مثال: الشجاعة، الفضاء، الحيوانات)',
                Icons.auto_stories_outlined),
            const SizedBox(height: 16),

            // ── 5) النمط البصري ──
            _buildDropdown(
              label: 'النمط البصري',
              icon: Icons.palette_outlined,
              value: _selectedStyle,
              items: const {
                '3d-model': 'رسوم متحركة 3D (بيكسار)',
                'anime': 'أنمي ياباني',
                'digital-art': 'فن رقمي',
                'pixel-art': 'بيكسل آرت',
              },
              onChanged: (v) => setState(() => _selectedStyle = v!),
            ),
            const SizedBox(height: 24),

            // ── 6) ملخص التكلفة ──
            _buildPricingBreakdown(),
            const SizedBox(height: 16),

            // ── 7) زر التوليد ──
            ElevatedButton(
              onPressed: _generateStory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.vibrantOrange,
                foregroundColor: AppColors.deepNight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 24),
                  const SizedBox(width: 10),
                  const Text('اصنع السحر!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.deepNight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('-$_totalCost',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 3),
                        const Icon(Icons.stars, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── بطاقة ميزة موحّدة (أفاتار / صوت) ──
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isAvailable,
    required VoidCallback onTap,
    ValueChanged<bool>? onToggle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.vibrantOrange.withValues(alpha: 0.08)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.vibrantOrange
                : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAvailable
                    ? (isActive
                        ? AppColors.vibrantOrange
                        : AppColors.vibrantOrange.withValues(alpha: 0.15))
                    : Colors.white.withValues(alpha: 0.06),
              ),
              child: Icon(icon,
                  color: isAvailable
                      ? (isActive ? AppColors.deepNight : AppColors.vibrantOrange)
                      : Colors.grey,
                  size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.glassWhite)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? Colors.greenAccent
                              : Colors.grey[400])),
                ],
              ),
            ),
            if (onToggle != null)
              Switch(
                value: isActive,
                activeColor: AppColors.vibrantOrange,
                onChanged: onToggle,
              )
            else
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // ── ملخص التكلفة ──
  Widget _buildPricingBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.vibrantOrange.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _pricingRow(Icons.auto_stories, 'القصة الأساسية', _baseStoryCost),
          if (_useAvatar)
            _pricingRow(Icons.face, 'الأفاتار', _avatarUsageCost),
          if (_useClonedVoice)
            _pricingRow(
                Icons.record_voice_over, 'الصوت المستنسخ', _clonedVoiceUsageCost),
          Divider(color: AppColors.vibrantOrange.withValues(alpha: 0.25), height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي',
                  style: TextStyle(
                      color: AppColors.glassWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              _creditBadge(-_totalCost, type: CreditBadgeType.deduction, large: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pricingRow(IconData icon, String label, int cost) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ),
          _creditBadge(-cost, type: CreditBadgeType.deduction),
        ],
      ),
    );
  }

  /// شارة الكريدت الموحّدة — نفس النجمة الذهبية في كل التطبيق
  /// Red للخصم، Green للإضافة، Orange للرصيد الحالي
  Widget _creditBadge(int amount,
      {required CreditBadgeType type, bool large = false}) {
    final fontSize = large ? 16.0 : 13.0;
    final iconSize = large ? 18.0 : 14.0;

    final Color color;
    switch (type) {
      case CreditBadgeType.deduction:
        color = const Color(0xFFFF5252);
        break;
      case CreditBadgeType.addition:
        color = const Color(0xFF4CAF50);
        break;
      case CreditBadgeType.balance:
        color = AppColors.vibrantOrange;
        break;
    }

    final sign = amount > 0 ? '+' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$sign$amount',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: fontSize)),
        const SizedBox(width: 3),
        Icon(Icons.stars, color: color, size: iconSize),
      ],
    );
  }

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
        prefixIcon: Icon(icon, color: AppColors.vibrantOrange, size: 20),
        filled: true,
        fillColor: AppColors.cardSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vibrantOrange, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.cardSurface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppColors.vibrantOrange, size: 20),
        filled: true,
        fillColor: AppColors.cardSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vibrantOrange, width: 2),
        ),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(
              value: e.key,
              child:
                  Text(e.value, style: const TextStyle(color: Colors.white))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
