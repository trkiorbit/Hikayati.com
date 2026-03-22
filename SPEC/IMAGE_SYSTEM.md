# IMAGE SYSTEM — FINAL

## الهدف
ضمان ثبات شخصية الطفل في جميع الصور

---

## القانون
الصورة = المشهد + الهوية + الملابس + الستايل

---

## المكونات

### 1) Story Engine
- يولد:
  - scene_description فقط
- يحدد:
  - الحدث
  - البيئة
  - تسلسل المشاهد

❌ لا يحدد هوية الطفل النهائية عند وجود أفاتار

---

### 2) Avatar System
يولد:
- face_description
- body_traits
- skin
- hair
- age
- current_clothes

هذا = هوية ثابتة للبطل

---

### 3) Clothing Layer
- الملابس الحالية
- الإكسسوارات
- الحالة البصرية الحالية

يمكن تعديلها لاحقًا حسب منطق الكريدت

---

### 4) Style System
- Pixar
- Anime
- Realistic

ثابت لكل قصة

---

## Prompt Builder (إجباري)

### المدخلات:
- scene_description
- avatar_identity (اختياري)
- current_clothes
- style

### الناتج:
scene_description

Main character:
[face_description + traits]

Wearing:
[current_clothes]

Style:
[selected_style]

Same character across all scenes.

---

## المسارات

### بدون أفاتار
Story Engine
→ image_prompt
→ Content Monitor
→ Image API

### مع أفاتار
Story Engine
→ Prompt Builder
→ Content Monitor
→ Image API

---

## تثبيت الشخصية
1. نفس الوصف في كل مشهد
2. نفس style
3. نفس model
4. نفس بنية الـ prompt
5. إضافة:
Same character across all scenes

---

## مصدر الوصف

### بدون أفاتار
→ Story Engine يصف المشهد والشخصية داخل المشهد

### مع أفاتار
→ Avatar System يزوّد هوية البطل
→ Prompt Builder يدمج الهوية مع وصف المشهد

---

## ممنوع
- إرسال صورة الطفل وحدها والاعتماد عليها
- تغيير style بين المشاهد
- حذف الهوية من prompt
- إرسال prompt ناقص

---

## النتيجة المطلوبة
نفس الطفل في كل الصور بأعلى ثبات ممكن
