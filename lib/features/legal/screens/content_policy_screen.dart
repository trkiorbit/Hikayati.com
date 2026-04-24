import 'package:flutter/material.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';

class ContentPolicyScreen extends StatelessWidget {
  const ContentPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('سياسة المحتوى والملكية'),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.glassWhite,
        centerTitle: true,
        actions: const [CreditsBadge()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('سياسة المحتوى والملكية الفكرية'),
            _body('آخر تحديث: أبريل 2026'),

            const Divider(height: 32),

            _section('1. ملكية الصور والصوت'),
            _body(
              'عند رفع صورة أو تسجيل صوتي داخل التطبيق، فإنك تقر وتضمن أنك:',
            ),
            _bullet('تملك حقوق الصورة أو الصوت المرفوع، أو لديك إذن صريح من المالك.'),
            _bullet('ولي أمر الطفل الظاهر في الصورة أو صاحب الإذن القانوني لاستخدامها.'),
            _bullet('تتحمل المسؤولية الكاملة عن أي محتوى تقوم برفعه إلى التطبيق.'),

            _section('2. المحتوى المولّد'),
            _body(
              'القصص والصور والصوتيات التي يولّدها التطبيق باستخدام الذكاء الاصطناعي '
              'متاحة لك للاستخدام الشخصي ضمن نطاق الخدمة. يشمل ذلك:',
            ),
            _bullet('مشاهدة القصص وإعادة تشغيلها داخل التطبيق.'),
            _bullet('الاحتفاظ بها في مكتبتك الخاصة.'),
            _bullet('طباعتها كمنتج مادي عبر متجر حكواتي (عند توفر الخدمة).'),
            _body(
              'لا يحق استخدام المحتوى المولّد لأغراض تجارية خارج نطاق التطبيق '
              'بدون إذن كتابي مسبق من فريق حكواتي.',
            ),

            _section('3. المحتوى المحظور'),
            _body('يُمنع منعًا باتًا استخدام التطبيق لأي من الأغراض التالية:'),
            _bullet('إنشاء محتوى مسيء أو عنيف أو غير لائق.'),
            _bullet('رفع صور أو أصوات بدون حق أو إذن.'),
            _bullet('استخدام التطبيق لإنتاج مواد تنتهك حقوق الملكية الفكرية للغير.'),
            _bullet('أي استخدام ينتهك القوانين المحلية أو الدولية.'),

            _section('4. فلترة المحتوى'),
            _body(
              'يستخدم التطبيق أنظمة فلترة متعددة لضمان سلامة المحتوى المولّد. '
              'تشمل الفلترة مراجعة النصوص والصور قبل عرضها. '
              'في حال رصد أي محتوى مخالف، يحق لنا تعليق الحساب دون إشعار مسبق.',
            ),

            _section('5. الإبلاغ عن محتوى مخالف'),
            _body('إذا لاحظت أي محتوى غير مناسب داخل التطبيق، يرجى إبلاغنا فورًا عبر:'),
            _body('البريد الإلكتروني: support@hikayati.app'),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) => Text(text,
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.glassWhite));

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.vibrantOrange)),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 15, color: AppColors.glassWhite.withValues(alpha: 0.85), height: 1.7)),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4, right: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(Icons.circle, size: 6, color: AppColors.vibrantOrange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 15, color: AppColors.glassWhite.withValues(alpha: 0.85), height: 1.6)),
            ),
          ],
        ),
      );
}
