import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شروط الاستخدام')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('شروط استخدام التطبيق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('يجب استخدام التطبيق تحت إشراف الوالدين.'),
            Text('يُمنع استخدام محرك القصص لإنتاج محتوى مخالف للآداب العامة وسياسة حماية الطفل.'),
            Text('الرصيد المشترى (الجواهر) غير قابل للاسترداد وتُطبق سياسات المتجر (Apple/Google).'),
          ],
        ),
      ),
    );
  }
}
