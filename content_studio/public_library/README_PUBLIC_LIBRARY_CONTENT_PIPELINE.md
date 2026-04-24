# Public Library Content Pipeline
**الإصدار:** 1.0
**التاريخ:** 2026-04-24
**القرار:** إنتاج محتوى المكتبة العامة **خارج التطبيق** عبر Content Studio

---

## 🚨 قرار المشروع

تم اختبار إنتاج قصص المكتبة العامة من **داخل التطبيق** (Flutter + AI pipeline) ثم **رفضه** للأسباب التالية:

| المشكلة | التفاصيل |
|---|---|
| ❌ عدد مشاهد خاطئ | خرجت القصة بـ 5 مشاهد بدلاً من 6 (publicLibraryProduction لم يكن مُفعّلاً) |
| ❌ شخصية غير ثابتة | ليلى ظهرت بأعمار مختلفة بين المشاهد |
| ❌ ملامح/أطراف غير مقبولة | تشوّه في اليدين والقدمين في بعض الصور |
| ❌ نص ضعيف | عربية سطحية غير مناسبة للإطلاق |
| ❌ جودة غير كافية | المُولِّد الحالي (Pollinations flux) لا يضمن premium quality |

**الخلاصة:** pipeline داخل التطبيق مناسب **للمستخدم النهائي** لكنه غير كافٍ لإنتاج **محتوى الواجهة الافتتاحية**.

---

## ⚠️ حالة `publicLibraryProduction`

Flag في `lib/core/config/story_generation_mode.dart`:

```dart
enum StoryGenerationMode { userDefault, publicLibraryProduction }
```

**الحالة الجديدة:**
- ✅ يبقى الـ flag موجوداً في الكود
- ✅ أداة **اختبار وتطوير** فقط
- ❌ **لم يعد** مسار إنتاج قصص المكتبة العامة الافتتاحية
- ❌ **لا** يُستخدم لإنتاج محتوى الإطلاق

**مصدر الحقيقة لمحتوى المكتبة العامة:** مجلد `content_studio/public_library/` + إدخال يدوي إلى Supabase.

---

## 📂 بنية Content Studio

```
content_studio/public_library/
├── README_PUBLIC_LIBRARY_CONTENT_PIPELINE.md  ← هذا الملف
├── STORY_BIBLE_TEMPLATE.md                    ← قالب Story Bible
├── CHARACTER_BIBLE_TEMPLATE.md                ← قالب بصمة الشخصية
├── SCENE_SHEET_TEMPLATE.md                    ← قالب جدول المشاهد
├── IMAGE_PROMPT_TEMPLATE.md                   ← قالب prompt الصور
├── PUBLIC_STORY_IMPORT_TEMPLATE.json          ← قالب JSON للاستيراد
├── QC_CHECKLIST.md                            ← قائمة فحص الجودة
│
├── 00_catalog/              ← سجل عام لكل القصص (ملف واحد يتتبع الحالة)
├── 01_scripts/              ← نصوص القصص (Story Bible لكل قصة)
├── 02_visual_bibles/        ← بصمات الشخصيات (Character Bible لكل قصة)
├── 03_scene_prompts/        ← جداول المشاهد (Scene Sheet لكل قصة)
├── 04_images/               ← الصور المُنتَجة (محلياً قبل الرفع)
│   ├── <story-slug>/
│   │   ├── cover.jpg
│   │   ├── scene_1.jpg
│   │   ├── scene_2.jpg
│   │   └── ...
├── 05_audio/                ← الصوتيات (TTS) محلياً قبل الرفع
│   ├── <story-slug>/
│   │   ├── scene_1.mp3
│   │   └── ...
├── 06_import_ready/         ← JSON النهائي جاهز للاستيراد لـ Supabase
│   └── <story-slug>.json
└── 07_qc_reports/           ← تقارير QC لكل قصة
    └── <story-slug>_qc.md
```

---

## 🔄 تدفق الإنتاج (7 مراحل)

### المرحلة 1 — Story Bible
**المخرج:** `01_scripts/<story>_bible.md`
**الخطوات:**
1. انسخ `STORY_BIBLE_TEMPLATE.md`
2. أعد التسمية إلى `<story-slug>_bible.md`
3. املأ: title, category, age, moral_goal, tone, character, summary, acceptance_criteria
4. **قفل الوثيقة** قبل الانتقال

**قاعدة:** لا سكربت، لا صور، لا صوت قبل قفل Bible.

---

### المرحلة 2 — Character Bible
**المخرج:** `02_visual_bibles/<story>_character.md`
**الخطوات:**
1. انسخ `CHARACTER_BIBLE_TEMPLATE.md`
2. املأ: age, face, hair, eyes, clothes, body_type, personality
3. اكتب `must_remain_consistent` كجدول واضح
4. اكتب `negative_prompt` جاهز للنسخ
5. **أرفق صورة reference** للشخصية إذا أمكن (يمكن توليدها من Midjourney ثم استخدامها كمرجع)

**قاعدة:** نفس Character Bible يُحقن حرفياً في كل image prompt.

---

### المرحلة 3 — Scene Sheet
**المخرج:** `03_scene_prompts/<story>_scene_sheet.md`
**الخطوات:**
1. انسخ `SCENE_SHEET_TEMPLATE.md`
2. املأ الجدول: 6 صفوف
3. لكل مشهد: arabic_text, visual_description, emotion, camera_angle
4. اكتب image_prompt كامل لكل مشهد (من IMAGE_PROMPT_TEMPLATE)
5. **راجع كل prompt** قبل التوليد

**قاعدة:** 6 مشاهد بالضبط. لا 5 ولا 7.

---

### المرحلة 4 — Image Production
**المخرج:** `04_images/<story-slug>/scene_N.jpg`
**Generators الموصى بها:**
- **Midjourney v6+** (الأفضل للاتساق)
- **Google Imagen 3**
- **Ideogram v2**

**الخطوات:**
1. افتح الـ generator
2. الصق image_prompt من Scene Sheet
3. ولّد 4 خيارات
4. اختر الأفضل
5. **إذا لم يكن ممتازاً** → أعد التوليد بتعديل الـ prompt
6. احفظ بالاسم: `scene_1.jpg`, `scene_2.jpg`, ...
7. ولّد أيضاً `cover.jpg` (اختيارياً: المشهد الأول أو تركيبة مخصصة)

**القاعدة:** لا تقبل صورة "حسنة". اطلب صورة "ممتازة" تُناسب غلاف كتاب أطفال في مكتبة.

---

### المرحلة 5 — Audio Production
**المخرج:** `05_audio/<story-slug>/scene_N.mp3`
**الأدوات:**
- **ElevenLabs** (أفضل صوت عربي لكن الفاتورة معلّقة)
- **Pollinations TTS** (مجاني، جودة متوسطة)
- **Google Cloud TTS Arabic** (بديل ممتاز)
- **Azure TTS Arabic** (خيار آخر)

**الخطوات:**
1. أنتج صوت واحد لكل مشهد
2. احفظ بصيغة mp3 عالية الجودة
3. **استمع للكامل** قبل القبول
4. أعد إنتاج أي مشهد يحتوي أخطاء نطق

---

### المرحلة 6 — Upload & JSON Prep
**المخرج:** `06_import_ready/<story-slug>.json`
**الخطوات:**
1. **ارفع الصور** إلى Supabase Storage في bucket مخصص:
   - مجلد: `public-library-scenes/<story-slug>/`
   - مجلد: `public-library-covers/`
2. **ارفع الصوتيات** إلى:
   - مجلد: `public-library-audio/<story-slug>/`
3. احصل على public URLs
4. انسخ `PUBLIC_STORY_IMPORT_TEMPLATE.json`
5. املأ كل الحقول + الروابط العامة
6. احفظ بالاسم: `<story-slug>.json`

---

### المرحلة 7 — QC + Import
**المخرج:** `07_qc_reports/<story-slug>_qc.md` + row في `public_stories`
**الخطوات:**
1. انسخ `QC_CHECKLIST.md`
2. نفّذ **كل** البنود بدقة
3. **إذا فشل أي بند** → عُد للمرحلة المسؤولة وأعد الإنتاج
4. عند اكتمال ✅ على كل البنود:
   - نفّذ ALTER TABLE (مرة واحدة للقصة الأولى فقط):
     ```sql
     ALTER TABLE public.public_stories
       ADD COLUMN IF NOT EXISTS scenes_json JSONB,
       ADD COLUMN IF NOT EXISTS voice_type VARCHAR(20) DEFAULT 'echo';
     ```
   - نفّذ INSERT من `_import_sql_template` في JSON
5. تحقق في Supabase:
   ```sql
   SELECT id, title, category FROM public.public_stories ORDER BY created_at DESC LIMIT 5;
   ```
6. اختبر من التطبيق بحساب مستخدم جديد

---

## 📋 القائمة الافتتاحية (8 قصص)

ننتج قصصاً واحدة تلو الأخرى. لا نبدأ قصة قبل اكتمال QC السابقة.

| # | العنوان | الحالة | Story Bible | Character | Scenes | Images | Audio | QC | Imported |
|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | ليلى والذئب الذكي | ⏳ | — | — | — | — | — | — | — |
| 2 | سباق الغابة الكبير | ⏳ | — | — | — | — | — | — | — |
| 3 | مصباح الأمنيات | ⏳ | — | — | — | — | — | — | — |
| 4 | الحذاء الزجاجي المفقود | ⏳ | — | — | — | — | — | — | — |
| 5 | باب الكهف السحري | ⏳ | — | — | — | — | — | — | — |
| 6 | البذرة التي وصلت للغيوم | ⏳ | — | — | — | — | — | — | — |
| 7 | سرّ البركة الذهبية | ⏳ | — | — | — | — | — | — | — |
| 8 | مرآة الغابة القديمة | ⏳ | — | — | — | — | — | — | — |

**الهدف للإطلاق:** 5 قصص مكتملة بجودة ممتازة (ليس 8).

---

## 🛡️ قواعد حماية المستخدم العادي

**مهم جداً:**
- ✅ `StoryGenerationMode.currentMode = userDefault` في main branch دائماً
- ✅ المستخدم العادي **لا يتأثر** بأي شيء في Content Studio
- ✅ Content Studio خارج Flutter build — مجرد ملفات توثيق وخطط
- ✅ الإنتاج يتم يدوياً من المطور، ليس عبر التطبيق

**ما يتأثر بـ Content Studio:**
- فقط: `public_stories` في Supabase (يُحدَّث بـ INSERT)
- التطبيق يقرأ منه كقراءة عادية

---

## 🔗 الربط مع وثائق المشروع

| المستند | الموقع |
|---|---|
| الخطة الموحدة | `خطة_المشروع/خطة_الإطلاق_السريع_النهائية.md` |
| سجل التعديلات | `خطة_المشروع/سجل_التعديلات.md` |
| Closure Report | `PUBLIC_LIBRARY_CLOSURE_REPORT.md` |
| Supabase migration draft | `supabase/migrations/draft_add_public_stories_content_columns.sql` |
| Restore point | `before_external_public_library_content_studio` (Git tag) |

---

## ✅ معايير النجاح النهائي

- 5 قصص في `public_stories` كلها ✅ QC
- كل قصة 6 مشاهد، صور ممتازة، صوت واضح
- اختبار end-to-end بحساب مستخدم جديد ناجح
- `currentMode = userDefault` في التطبيق
- المستخدم الجديد يفتح المكتبة العامة ويجد محتوى جذاب

**ثم — وبعد ذلك فقط — ننتقل إلى مرحلة الدفع.**
