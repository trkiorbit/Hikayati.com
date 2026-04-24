import 'package:flutter/material.dart';
import 'package:hikayati/core/theme/app_colors.dart';
import 'package:hikayati/core/widgets/credits_badge.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
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
            _heading('سياسة خصوصية تطبيق حكواتي'),
            _body('آخر تحديث: أبريل 2026'),
            const SizedBox(height: 8),
            _body(
              'نحن في حكواتي نلتزم بحماية خصوصيتك وخصوصية أطفالك. '
              'توضح هذه السياسة كيفية جمع بياناتك واستخدامها وحمايتها عند استخدامك لتطبيقنا.',
            ),

            const Divider(height: 32),

            _section('1. ما الذي نجمعه'),
            _bullet('البريد الإلكتروني وكلمة المرور عند إنشاء الحساب.'),
            _bullet('صور الطفل التي تُرفع عند إنشاء الأفاتار (بموافقة ولي الأمر).'),
            _bullet('التسجيلات الصوتية عند استخدام ميزة استنساخ الصوت (بموافقة المالك).'),
            _bullet('القصص المولّدة والصور والصوتيات الناتجة عن استخدام التطبيق.'),
            _bullet('بيانات الاستخدام الأساسية (عدد القصص، الرصيد، تفضيلات اللغة).'),

            _section('2. كيف نستخدم بياناتك'),
            _bullet('إنشاء شخصية بصرية (أفاتار) مخصصة لطفلك داخل التطبيق.'),
            _bullet('توليد قصص وصوتيات مخصصة باستخدام تقنيات الذكاء الاصطناعي.'),
            _bullet('حفظ القصص في مكتبتك الخاصة لإعادة مشاهدتها.'),
            _bullet('تحسين تجربة المستخدم وجودة الخدمة.'),
            _body('لا نبيع بياناتك الشخصية لأي طرف ثالث ولا نستخدمها لأغراض إعلانية.'),

            _section('3. أين تُخزن البيانات'),
            _body(
              'تُخزن بياناتك بشكل آمن على خوادم Supabase المشفّرة. '
              'تُعالج الصور والنصوص عبر خدمات ذكاء اصطناعي متخصصة '
              '(Pollinations، ElevenLabs) مع تطبيق أقصى معايير فلترة المحتوى.',
            ),

            _section('4. مدة الاحتفاظ بالبيانات'),
            _bullet('تُحفظ بيانات الحساب والقصص طالما الحساب مفعّل.'),
            _bullet('صور الأفاتار المصدرية تُحفظ لاسترجاع الشخصية لاحقًا.'),
            _bullet('التسجيلات الصوتية الخام تُرفع لخدمة الاستنساخ ولا تُحفظ محليًا بعد المعالجة.'),

            _section('5. حذف البيانات'),
            _body(
              'يمكنك طلب حذف حسابك وجميع بياناتك المرتبطة به في أي وقت '
              'من خلال صفحة الحساب الشخصي داخل التطبيق أو بالتواصل معنا مباشرة. '
              'يتم تنفيذ طلبات الحذف خلال 48 ساعة عمل.',
            ),

            _section('6. حماية الأطفال'),
            _body(
              'تطبيق حكواتي مصمم ليُستخدم بواسطة الوالدين أو أولياء الأمر نيابة عن أطفالهم. '
              'لا نجمع بيانات مباشرة من الأطفال بدون موافقة ولي الأمر. '
              'جميع ميزات رفع الصور والصوت تتطلب موافقة صريحة قبل المتابعة.',
            ),

            _section('7. التواصل معنا'),
            _body('لأي استفسار أو طلب يتعلق بالخصوصية، يرجى التواصل عبر:'),
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
