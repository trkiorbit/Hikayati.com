# STORY ENGINE — FINAL

## الهدف
تحديد كيف تُبنى القصة فعليًا في المشروع الحالي، وكيف يرتبط النص والصورة والصوت والأفاتار داخل بنية حديثة قابلة للتوسعة.

---

## المبدأ الأساسي

المشروع الحالي لا يعمل بمنطق v5.

في v5:
- الأفاتار كان يدخل فقط كصورة مرجعية للصور
- النص كان منفصلًا عن الأفاتار
- خدمة واحدة كانت مسؤولة عن كل شيء

في المشروع الحالي:
- القصة تُبنى بهوية موحدة
- الأفاتار ليس مجرد صورة، بل هوية بصرية
- الخدمات مفصولة
- يمكن تغيير المزودات بدون إعادة كتابة المشروع كله

---

## القانون الذهبي

القصة = حدث + بطل + مشاهد + هوية + صور + صوت + حفظ

---

## المكونات الرئيسية

### 1) Story Engine
مسؤوليته:
- توليد القصة الأساسية
- تقسيم القصة إلى مشاهد
- وصف ما يحدث في كل مشهد
- إخراج scene_description لكل مشهد

Story Engine يحدد:
- الحدث
- البيئة
- التسلسل
- الجو العام

❌ Story Engine لا يحدد هوية الطفل النهائية عند وجود أفاتار

---

### 2) Hakeem
حكيم ليس مراقبًا.

دوره:
- تحسين الفكرة
- تحسين وصف البطل
- مساعدة في بناء الهوية النصية
- دعم الوصف عندما يكون الأفاتار مفعّلًا
- المساهمة في إنتاج avatar_identity النصي الحديث

حكيم:
- داخل التطبيق = مساعد ذكي
- خارج التطبيق = محرك تسويق وجذب

---

### 3) Avatar System
الأفاتار في المشروع الحالي ليس مثل v5.

الأفاتار الحديث ينتج:
- face_description
- body_traits
- skin
- hair
- age
- current_clothes

هذا يشكل:
avatar_identity

---

### 4) Prompt Builder
هذه طبقة إلزامية.

مسؤوليته:
- دمج scene_description
- مع avatar_identity
- مع current_clothes
- مع style

ثم إنتاج prompt نهائي للصور

---

### 5) Content Monitor
طبقة مستقلة.

يفحص:
- النص
- الصورة
- المخرجات

قبل:
- العرض
- أو إرسال التوليد

حكيم ليس Content Monitor

---

### 6) Image Service
مسؤوليته:
- استقبال prompt النهائي فقط
- إرسال الطلب لمزود الصور
- إعادة image_url أو image asset

Image Service لا يبني المنطق
بل ينفذ فقط

---

### 7) Audio System
ينقسم إلى قسمين:

#### أ) الصوت العادي
- يستخدم المزود الصوتي الأساسي الأرخص
- يُستخدم لقراءة القصص العادية

#### ب) الصوت المستنسخ
- يستخدم ElevenLabs فقط
- يُستخدم لإنشاء الصوت المستنسخ
- ويُستخدم أيضًا لقراءة القصة بالصوت المستنسخ فقط

❌ ممنوع استخدام ElevenLabs للصوت العادي
❌ ممنوع جعل كل أصوات القصص تمر عبر ElevenLabs

---

### 8) Voice Clone Service
مسؤوليته:
- رفع العينة
- إنشاء voice_id
- حفظ voice_id للمستخدم
- تشغيل النص باستخدام voice_id المستنسخ

---

### 9) Save Layer
مسؤوليته:
- حفظ القصة
- حفظ المشاهد
- حفظ روابط الصور والصوت
- ربط القصة بالمستخدم
- تمكين إعادة فتح القصة لاحقًا بدون خصم

---

## تدفق القصة النهائي

### بدون أفاتار

User Input
→ Story Engine
→ scenes + scene_description
→ Content Monitor
→ Image Service
→ Audio Service
→ Save Layer
→ Cinema
→ Private Library

---

### مع أفاتار

User Input
→ Story Engine
→ scenes + scene_description
→ Hakeem / Avatar Identity Enrichment
→ Prompt Builder
→ Content Monitor
→ Image Service
→ Audio Service أو Voice Clone Service
→ Save Layer
→ Cinema
→ Private Library

---

## كيف يدخل الأفاتار؟

الأفاتار الحديث لا يدخل فقط كرابط صورة مثل v5.

بل يدخل كالتالي:
- avatar_identity
- current_clothes
- style
- same character rules

ويتم حقنه في كل prompt صورة

---

## كيف نثبت الشخصية؟

يتم تثبيت الشخصية عبر:
1. avatar_identity ثابت
2. current_clothes واضح
3. style ثابت لكل قصة
4. prompt structure ثابت
5. تعليمات مثل:
   Same character across all scenes

---

## كيف يختلف هذا عن v5؟

### v5
- avatar_url فقط
- النص منفصل عن الهوية
- خدمة واحدة تقوم بكل شيء
- لا يوجد حفظ ناضج
- لا يوجد Prompt Builder حقيقي

### المشروع الحالي
- avatar_identity
- فصل النص عن الصور عن الصوت
- Prompt Builder
- Content Monitor
- حفظ حقيقي
- قابلية تغيير المزودات

---

## ما الذي نأخذه من v5 فقط؟
- فكرة reference image للصور
- seed/style consistency
- بعض UX flows
- ElevenLabs voice clone logic فقط

---

## ما الذي لا نأخذه من v5؟
- الخدمة الموحدة
- ربط كل شيء في ملف واحد
- منطق الصوت العام عبر ElevenLabs
- عدم الحفظ
- فصل غير ناضج للهوية

---

## القرار التنفيذي

المشروع الحالي يجب أن يعتمد على:
- Story Engine مستقل
- Prompt Builder مستقل
- Image Service مستقل
- Audio Service مستقل
- Voice Clone Service مستقل
- Save Layer مستقل

---

## ممنوعات
- ممنوع إعادة بناء المشروع على منطق v5
- ممنوع اختصار الأفاتار إلى avatar_url فقط
- ممنوع دمج النص والصور والصوت في خدمة واحدة
- ممنوع تمرير الصوت العادي إلى ElevenLabs
- ممنوع تجاهل Content Monitor

---

## النتيجة المطلوبة
منتج يستطيع:
- توليد قصة
- استخدام أفاتار حقيقي
- الحفاظ على هوية البطل
- استخدام صوت عادي أو مستنسخ
- حفظ القصة
- فتحها لاحقًا بدون خصم
