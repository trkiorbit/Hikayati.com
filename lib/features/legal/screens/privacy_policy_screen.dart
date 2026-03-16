import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('سياسة خصوصية حكايتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('1. بيانات الأطفال:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('نحن لا نقوم بحفظ أي صور أو بيانات شخصية للأطفال بشكل دائم. يتم استخدام البيانات المدخلة في وقت التوليد فقط، ثم تُحذف للحفاظ على الأمان المطلق.'),
            SizedBox(height: 16),
            Text('2. استنساخ الصوت:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('يتطلب استنساخ الصوت موافقة صريحة من ولي الأمر، ولا يتم استخدام هذه الخاصية للأطفال القصر بتاتاً.'),
            SizedBox(height: 16),
            Text('3. الذكاء الاصطناعي:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('نستخدم خدمات (Pollinations, ElevenLabs, Gemini) بأقصى معايير فلترة المحتوى لضمان بيئة آمنة تماماً للأطفال.'),
            // More policy details would go here
          ],
        ),
      ),
    );
  }
}
