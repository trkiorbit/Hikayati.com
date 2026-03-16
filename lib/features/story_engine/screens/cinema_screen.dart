import 'package:flutter/material.dart';

class CinemaScreen extends StatelessWidget {
  final Map<String, dynamic> storyData;

  const CinemaScreen({super.key, this.storyData = const {}});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // خلفية سينمائية سوداء
      appBar: AppBar(
        title: const Text('السينما'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'طبقة العرض (السينما)\nسيتم عرض القصة هنا بناءً على البيانات المستقبلة.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
