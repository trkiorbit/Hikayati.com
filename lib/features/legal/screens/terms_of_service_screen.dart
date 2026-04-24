import 'package:flutter/material.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('الشروط والأحكام'),
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
            _heading('شروط وأحكام استخدام تطبيق حكواتي'),
            _body('آخر تحديث: أبريل 2026'),
            const SizedBox(height: 8),
            _body(
              'باستخدامك لتطبيق حكواتي فإنك توافق على الشروط التالية. '
              'يرجى قراءتها بعناية قبل استخدام التطبيق.',
            ),

            const Divider(height: 32),

            _section('1. الاستخدام بإشراف ولي الأمر'),
            _body(
              'تطبيق حكواتي مصمم لإنشاء قصص مخصصة للأطفال ويُستخدم بواسطة الوالدين '
              'أو أولياء الأمر. يتحمل ولي الأمر المسؤولية الكاملة عن استخدام التطبيق '
              'والمحتوى المُدخل فيه (صور، تسجيلات صوتية).',
            ),

            _section('2. المحتوى المُدخل'),
            _bullet('يلتزم المستخدم بعدم رفع صور أو أصوات بدون حق أو إذن مسبق.'),
            _bullet('يُمنع استخدام التطبيق لإنتاج محتوى مخالف للآداب العامة أو يضر بالأطفال.'),
            _bullet('يحق لنا تعليق أو حذف أي حساب يثبت إساءة استخدامه.'),

            _section('3. نظام الجواهر (الرصيد)'),
            _bullet('تُستخدم الجواهر لتشغيل ميزات التطبيق (إنشاء قصة، أفاتار، استنساخ صوت).'),
            _bullet('الجواهر المستهلكة غير قابلة للاسترداد بعد تنفيذ العملية بنجاح.'),
            _bullet('يتم شراء الجواهر عبر المتاجر الرسمية (Apple App Store / Google Play) '
                'وتُطبق سياسات الاسترداد الخاصة بكل متجر.'),

            _section('4. الملكية الفكرية'),
            _body(
              'المحتوى المولّد (القصص والصور والصوتيات) متاح للاستخدام الشخصي '
              'ضمن نطاق التطبيق. لا يحق استخدامه تجاريًا بدون إذن كتابي مسبق.',
            ),

            _section('5. حدود المسؤولية'),
            _body(
              'نسعى لتقديم أفضل تجربة ممكنة، لكننا لا نضمن خلو الخدمة من الأعطال '
              'أو الانقطاعات. لا نتحمل المسؤولية عن أي خسائر ناتجة عن انقطاع مؤقت '
              'في الخدمة أو خلل تقني.',
            ),

            _section('6. منع إساءة الاستخدام'),
            _bullet('يُمنع محاولة التحايل على نظام الرصيد أو استغلال الثغرات.'),
            _bullet('يُمنع استخدام التطبيق لأي غرض غير قانوني.'),
            _bullet('يُمنع نقل الحساب أو بيعه لطرف آخر.'),

            _section('7. تحديث الشروط'),
            _body(
              'نحتفظ بحق تحديث هذه الشروط في أي وقت. سنقوم بإشعارك بالتغييرات '
              'الجوهرية عبر التطبيق. استمرارك في استخدام التطبيق بعد التحديث '
              'يعتبر موافقة ضمنية على الشروط المحدّثة.',
            ),

            _section('8. التواصل'),
            _body('لأي استفسار حول هذه الشروط، يرجى التواصل عبر:'),
            _body('البريد الإلكتروني: support@hikayati.app'),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) => Text(text,
      style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.glassWhite));

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.vibrantOrange)),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 15,
                color: AppColors.glassWhite.withValues(alpha: 0.85),
                height: 1.7)),
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
                      fontSize: 15,
                      color: AppColors.glassWhite.withValues(alpha: 0.85),
                      height: 1.6)),
            ),
          ],
        ),
      );
}
