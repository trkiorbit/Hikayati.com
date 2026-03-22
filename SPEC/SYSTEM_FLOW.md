# SYSTEM FLOW

## الهدف
توضيح التدفق التشغيلي الحقيقي للتطبيق من الدخول حتى حفظ القصة

---

## 1) تسجيل الدخول
Login
→ تحميل الحساب
→ تحميل الرصيد
→ تحميل الأفاتارات
→ تحميل القصص الخاصة

---

## 2) الصفحة الرئيسية
Home
→ مكتبتي
→ اصنع بطلك
→ اصنع قصة
→ الصوت
→ المتجر

---

## 3) إنشاء أفاتار
رفع صورة
→ Vision Analyzer
→ استخراج الملامح والملابس
→ مراجعة
→ حفظ الأفاتار
→ خصم كريدت الإنشاء

---

## 4) إنشاء قصة

### بدون أفاتار
Story Wizard
→ GenerateStoryUseCase
→ Story Engine
→ image_prompt
→ Image Service
→ Cinema
→ Save Story
→ Private Library

### مع أفاتار
Story Wizard
→ GenerateStoryUseCase
→ Story Engine
→ Prompt Builder
→ Image Service
→ Cinema
→ Save Story
→ Private Library

---

## 5) الصوت

### صوت عادي
Story Text
→ Cheap Voice Provider
→ Audio Output

### صوت مستنسخ
Story Text
→ ElevenLabs
→ Audio Output

---

## 6) المكتبة الخاصة
فتح قصة محفوظة
→ لا خصم
→ لا إعادة توليد
→ فتح مباشر

---

## 7) المكتبة العامة
عرض القصص
→ اختيار قصة
→ تأكيد خصم
→ فتح دائم بعد الشراء

---

## القواعد
- السينما عرض فقط
- لا يوجد زر بلا وظيفة
- أي أصل تم إنشاؤه يجب أن يعاد استخدامه
- أي قصة محفوظة يجب أن تفتح بدون خصم جديد
