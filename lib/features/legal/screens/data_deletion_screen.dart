import 'package:flutter/material.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';

class DataDeletionScreen extends StatelessWidget {
  const DataDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('سياسة حذف البيانات'),
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
            _heading('سياسة حذف بيانات المستخدم'),
            _body('آخر تحديث: أبريل 2026'),

            const Divider(height: 32),

            _section('1. كيفية طلب حذف البيانات'),
            _body(
              'يمكنك طلب حذف حسابك وجميع بياناتك المرتبطة به بإحدى الطرق التالية:',
            ),
            _bullet('من داخل التطبيق: صفحة "حسابي" ثم "طلب حذف البيانات".'),
            _bullet('عبر البريد الإلكتروني: إرسال طلب إلى support@hikayati.app مع ذكر البريد المسجّل.'),

            _section('2. ما الذي يُحذف'),
            _bullet('بيانات الحساب الشخصي (البريد الإلكتروني، كلمة المرور).'),
            _bullet('جميع القصص المحفوظة في مكتبتك الخاصة.'),
            _bullet('بيانات الأفاتار المحفوظة والصور المرفوعة.'),
            _bullet('بيانات الصوت المستنسخ.'),
            _bullet('سجل المشتريات وبيانات الرصيد.'),

            _section('3. ما قد يُحتفظ به'),
            _body(
              'قد نحتفظ ببيانات محدودة للأسباب التالية فقط:',
            ),
            _bullet('سجلات المعاملات المالية: للامتثال للمتطلبات المحاسبية والنظامية (تُحفظ بشكل مجهول الهوية).'),
            _bullet('بيانات الاستخدام المجمّعة: إحصائيات عامة لا تحدد هوية المستخدم.'),

            _section('4. مدة التنفيذ'),
            _body(
              'يتم تنفيذ طلبات الحذف خلال 48 ساعة عمل من تاريخ استلام الطلب. '
              'ستتلقى إشعارًا بالبريد الإلكتروني عند اكتمال عملية الحذف.',
            ),

            _section('5. ملاحظة مهمة'),
            _body(
              'عملية حذف البيانات نهائية ولا يمكن التراجع عنها. '
              'ستفقد جميع القصص والشخصيات والجواهر المتبقية في حسابك. '
              'ننصح بتصدير أو حفظ ما تحتاجه قبل تقديم طلب الحذف.',
            ),

            _section('6. التواصل'),
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
