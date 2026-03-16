## كود Flutter لدمج أصول التصميم في تطبيق "حكواتي"

لتحويل تطبيقك من التصميم البرمجي الأساسي إلى التصميم السينمائي السحري الذي قمنا بإنشائه، ستحتاج إلى دمج الصور التي تم توليدها (الخلفية والأيقونات) في كود Flutter الخاص بك. إليك الخطوات والكود اللازم لذلك:

### 1. تنظيم أصول التصميم (Assets)

أولاً، تأكد من أن لديك مجلداً داخل مشروع Flutter الخاص بك لتخزين الصور. عادةً ما يكون هذا المجلد باسم `assets/images/`. قم بوضع الصور التي تم توليدها فيه:

*   `hakawati_bg_stars.png` (الخلفية)
*   `icon_profile.png`
*   `icon_hero.png`
*   `icon_voice.png`
*   `icon_public_lib.png`
*   `icon_private_lib.png`

بعد ذلك، يجب عليك تعريف هذه الأصول في ملف `pubspec.yaml` الخاص بمشروعك. افتح الملف وأضف الأسطر التالية تحت قسم `flutter`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

**ملاحظة**: تأكد من أن المسافة البادئة (Indentation) صحيحة في ملف `pubspec.yaml`.

### 2. دمج الخلفية السحرية

لتعيين صورة `hakawati_bg_stars.png` كخلفية للشاشة الرئيسية، يمكنك استخدام `DecorationImage` داخل `BoxDecoration` لـ `Container` أو `Scaffold`.

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/hakawati_bg_stars.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // هنا ستضع باقي عناصر واجهة المستخدم مثل الشعار، زر ابدأ القصة، والقائمة السفلية
            // تأكد من أن هذه العناصر لها خلفيات شفافة أو ألوان تتناسب مع الخلفية الجديدة
          ],
        ),
      ),
    );
  }
}
```

### 3. استخدام الأيقونات الفنية في القائمة السفلية (Bottom Navigation Bar)

لدمج الأيقونات المخصصة في شريط التنقل السفلي، يمكنك استخدام `Image.asset` بدلاً من `Icon`.

```dart
import 'package:flutter/material.dart';

class MyBottomNavigationBar extends StatefulWidget {
  @override
  _MyBottomNavigationBarState createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.transparent, // اجعل الخلفية شفافة لتظهر الخلفية الرئيسية
      elevation: 0, // إزالة الظل إذا كنت لا تريده
      type: BottomNavigationBarType.fixed, // لضمان ظهور جميع الأيقونات والنصوص
      selectedItemColor: Colors.amber, // لون العنصر المختار
      unselectedItemColor: Colors.white70, // لون العناصر غير المختارة
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/icon_private_lib.png', width: 30, height: 30), // أقصى اليسار
          label: 'المكتبة الخاصة',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/icon_public_lib.png', width: 30, height: 30),
          label: 'المكتبة العامة',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/icon_voice.png', width: 30, height: 30),
          label: 'استنسخ صوتك',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/icon_hero.png', width: 30, height: 30),
          label: 'اصنع بطلك',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/icon_profile.png', width: 30, height: 30), // أقصى اليمين
          label: 'الحساب الشخصي',
        ),
      ].reversed.toList(), // لعكس الترتيب ليتناسب مع RTL
    );
  }
}
```

**ملاحظات هامة للقائمة السفلية:**
*   استخدمت `reversed.toList()` لعكس ترتيب العناصر في القائمة ليتناسب مع اتجاه RTL، حيث أن `BottomNavigationBar` يرتب العناصر من اليسار لليمين افتراضياً.
*   قد تحتاج إلى ضبط `width` و `height` للأيقونات لتناسب تصميمك.
*   يمكنك ضبط `selectedItemColor` و `unselectedItemColor` ليتناسب مع الألوان الذهبية والبرتقالية في تصميمك.

### 4. زر "ابدأ القصة"

بالنسبة لزر "ابدأ القصة"، يمكنك استخدام `ElevatedButton` أو `TextButton` مع تخصيص `TextStyle` للخط العربي. إذا كنت تستخدم خطاً عربياً مخصصاً، تأكد من إضافته إلى مشروعك وتضمينه في `pubspec.yaml`.

```dart
import 'package:flutter/material.dart';

// إذا كان لديك خط مخصص، قم بتعريفه هنا أو في ملف الثيم الخاص بك
// TextStyle customArabicFont = TextStyle(fontFamily: 'YourArabicFont', fontSize: 24, color: Colors.white);

class StartStoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // قم بتنفيذ الإجراء عند الضغط على الزر
        print('ابدأ القصة!');
      },
      style: ElevatedButton.styleFrom(
        primary: Colors.orange, // لون الزر
        onPrimary: Colors.white, // لون النص
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // شكل الزر دائري
        ),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        elevation: 10, // لإضافة تأثير التوهج
        shadowColor: Colors.amber.withOpacity(0.5), // لون الظل
      ),
      child: Text(
        'ابدأ القصة',
        style: TextStyle(
          fontSize: 28, // حجم الخط
          fontWeight: FontWeight.bold,
          color: Colors.white, // لون النص
          // fontFamily: 'YourArabicFont', // استخدم هذا إذا كان لديك خط عربي مخصص
        ),
      ),
    );
  }
}
```

**ملاحظة حول الخطوط العربية**: إذا كنت ترغب في استخدام خط عربي معين غير الخطوط الافتراضية للنظام، ستحتاج إلى:
1.  وضع ملف الخط (مثل `.ttf`) في مجلد `assets/fonts/`.
2.  تعريفه في `pubspec.yaml`:
    ```yaml
    flutter:
      fonts:
        - family: YourArabicFont
          fonts:
            - asset: assets/fonts/YourArabicFont-Regular.ttf
    ```
3.  استخدامه في `TextStyle` كما هو موضح في الكود.

بهذه الأكواد، يمكنك البدء في دمج أصول التصميم الجديدة في تطبيقك والحصول على المظهر السحري الذي نطمح إليه.
