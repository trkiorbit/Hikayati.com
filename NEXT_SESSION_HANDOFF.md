# Handoff للجلسة التالية — حكواتي
**آخر تحديث:** 2026-04-25
**الغرض:** ملف موحّد يجمع كل ما يحتاجه نموذج جديد لمتابعة العمل بدون لخبطة

---

## 🎯 نقطة الاستئناف الفعلية

**أنت في:** نهاية جلسة Audio Export Service لقصة ليلى
**الخطوة المنتظرة:** تروك يُشغّل التطبيق بـ dart-define ويُولّد الصوت
**ما لا يجب لمسه:** Auth, Credits, Avatar, Story Generation, Store, Payment, Hostinger

---

## 📂 المراجع الموحّدة (اقرأها بالترتيب)

| # | الملف | الغرض |
|:---:|---|---|
| 1 | `PROJECT_STATUS.md` | الحالة الحالية + ما تم وما تبقى |
| 2 | `خطة_المشروع/خطة_الإطلاق_السريع_النهائية.md` | الخطة الموحّدة (7 Phases) |
| 3 | `خطة_المشروع/سجل_التعديلات.md` | تاريخ كل تغيير |
| 4 | `خطة_المشروع/جاهزية_الإطلاق.md` | جاهزية كل ميزة |
| 5 | `خطة_المشروع/قرارات_المتجر_النهائية.md` v2 | Hostinger + PHP + Supabase (لا سلة، لا Next.js) |
| 6 | `content_studio/public_library/README_PUBLIC_LIBRARY_CONTENT_PIPELINE.md` | إنتاج قصص المكتبة خارج التطبيق |
| 7 | `content_studio/public_library/00_catalog/public_stories_catalog.json` | تتبع حالة كل قصة |
| 8 | `PUBLIC_LIBRARY_CLOSURE_REPORT.md` | تقرير المكتبة العامة |
| 9 | `NEXT_SESSION_HANDOFF.md` | هذا الملف |

---

## ✅ ما هو مُنجَز (لا تُعد العمل عليه)

### Code
- Auth + Session + eager profile creation
- Credits 20 ⭐ initial + realtime + anti-double deduction
- Private library (no deduction on reopen)
- Public library + unlock (10 ⭐)
- Avatar system (locked)
- Standard voice (Pollinations)
- Cinema (audio_url only)
- Visual identity (Cairo + Tajawal + ⭐ + red/green/orange)
- Dynamic pricing breakdown
- 4 legal pages
- Consent dialogs
- Profile + Store screens
- `SmartImage` widget (asset + network)
- `PublicLibraryAudioExportService` + Panel (dev-only)

### Content
- Content Studio: 7 templates + 8 dirs
- Layla Wolf package: Story Bible + 2 Character Bibles + Final Script + Scene Sheet + Image Prompts + Import JSON + QC Draft
- Layla reference image approved (`04_images/layla_wolf/layla_reference.png`)
- 6 scene images in `assets/public_library/layla_wolf/images/scene_01-06.jpeg`
- Layla integrated as static local story (UUID `11111111-1111-1111-1111-111111111111`)

### Git
- main @ `8003ffa` (مدفوع لـ GitHub)
- Tags: `before_store`, `before_payment_credit_currency_lock`, `before_public_library_premium_generation`, `before_public_library_content_verification`, `before_external_public_library_content_studio`

---

## 🚧 الخطوة التالية المنتظرة (تنفيذ بشري)

### A) توليد صوت ليلى المُصدَّر

**الأمر:**
```bash
cd D:\Hikayati.com
flutter run --dart-define=PUBLIC_LIBRARY_AUDIO_EXPORT=true
```

**في التطبيق:**
1. سجّل دخول بحساب فيه رصيد كافٍ (10 ⭐ على الأقل لو حساب جديد، أو حساب اشترى ليلى)
2. افتح المكتبة العامة → "ليلى والذئب الذكي"
3. اشترِ القصة (10 ⭐) أو افتحها لو سبق
4. في شاشة Cinema → زر تنزيل برتقالي ⭐ في AppBar (يمين)
5. اضغط → Bottom Sheet
6. اضغط "توليد صوت المكتبة العامة"
7. انتظر اكتمال الـ 6 مشاهد
8. سجّل manifest path من SnackBar الأخضر

**المخرج المتوقع:**
```
D:\Hikayati.com\content_studio\public_library\05_audio\layla_wolf\
├── scene_01.mp3
├── scene_02.mp3
├── scene_03.mp3
├── scene_04.mp3
├── scene_05.mp3
├── scene_06.mp3
└── audio_manifest.json
```

### B) ربط الصوت بالقصة (بعد التوليد الناجح)

1. انقل الصوتيات الستة إلى:
   ```
   assets/public_library/layla_wolf/audio/scene_01-06.mp3
   ```
2. أضف للـ pubspec.yaml:
   ```yaml
   - assets/public_library/layla_wolf/audio/
   ```
3. حدّث `lib/features/library/services/library_service.dart` → `_laylaWolfStaticStory.scenes_json[N].audio_url` لتشير لـ `assets/public_library/layla_wolf/audio/scene_NN.mp3`
4. حدّث `voice_type` من `echo` إلى `fable`
5. تحقق من `cinema_screen.dart` يستخدم `SmartImage` للأصول، و audio يحتاج `AssetSource` بدل `UrlSource` عند المسارات `assets/`
6. اختبر مسار end-to-end

### C) اختبار end-to-end (بحساب جديد)

1. signup جديد → تأكد رصيد 20 ⭐
2. افتح المكتبة العامة → ليلى تظهر
3. اضغط → AlertDialog 10 ⭐ → موافقة
4. خصم 10 → رصيد 10 ⭐
5. Cinema يفتح → 6 مشاهد + 6 صور + 6 صوتيات
6. النصوص تُسرَد بصوت fable الدافئ
7. خروج + إعادة فتح → صفر خصم

---

## 📋 برومبت المحادثة الجديدة (انسخه واستخدمه)

```markdown
أنت Senior Flutter/Supabase Engineer + Content Pipeline Continuer لمشروع Hikayati.

المسار: D:\Hikayati.com

اقرأ أولاً وبالترتيب:
1. NEXT_SESSION_HANDOFF.md (نقطة الاستئناف الفعلية)
2. PROJECT_STATUS.md (الحالة الحالية)
3. خطة_المشروع/سجل_التعديلات.md (آخر التعديلات)
4. خطة_المشروع/خطة_الإطلاق_السريع_النهائية.md (7 Phases)
5. content_studio/public_library/00_catalog/public_stories_catalog.json (حالة القصص)

القرارات المقفلة (لا تُناقش):
- Flutter + Supabase (لا تغيير معماري)
- المتجر الخارجي: Hostinger + HTML/PHP + Supabase (لا سلة، لا Next.js)
- StoryGenerationMode.userDefault هو الإفتراضي الدائم — publicLibraryProduction للتطوير فقط
- إنتاج محتوى المكتبة العامة عبر Content Studio خارج التطبيق
- ليلى مُدمجة محلياً بـ UUID 11111111-1111-1111-1111-111111111111
- رصيد البداية 20 ⭐
- Google Sign-In معطّل للإطلاق الأول

ممنوع:
- لا تلمس Auth / Credits / Avatar / Story Generation / Store
- لا تفتح الدفع / Hostinger / IAP الآن
- لا تستخدم Dummy Data
- لا تغيّر StoryGenerationMode.currentMode
- لا تكسر المستخدم العادي

الحالة الآن:
- Code جاهز 100%
- صور ليلى مرفوعة في assets ومرتبطة
- Audio Export Service جاهز (dev-only بـ --dart-define=PUBLIC_LIBRARY_AUDIO_EXPORT=true)
- ينتظر: توليد الصوت + ربطه + اختبار

المهمة الجديدة:
[اكتب هنا ما تريد تنفيذه]

قبل أي تعديل:
1. أنشئ نقطة استعادة Git
2. اقرأ الملفات المرجعية
3. اعرض خطتك للموافقة قبل التنفيذ

بعد التنفيذ:
1. flutter analyze (0 errors)
2. flutter build apk --debug (success)
3. حدّث سجل_التعديلات.md + PROJECT_STATUS.md + NEXT_SESSION_HANDOFF.md
4. تقرير واضح بما تم
```

---

## 🔐 قواعد المعمارية الثابتة (للنموذج الجديد)

1. **الواجهة عرض فقط** — لا AI calls من الشاشات
2. **السينما عرض فقط** — تقرأ `audio_url` المحفوظ، لا تُولّد
3. **كل التوليد عبر Use Cases** — `generate_story_use_case` هو الوسيط
4. **الأفاتار بالاستخراج فقط** — لا إدخال يدوي للعمر/الجنس/اللون
5. **خصم الرصيد بعد النجاح فقط**
6. **مصدر الحقيقة Supabase** — لا fallback مُرمَّز
7. **`StoryGenerationMode.currentMode = userDefault` دائماً** في main branch

---

## ⚠️ تنبيهات حرجة

### Public Library Schema
`supabase_schema.sql` لا يحتوي `scenes_json` ولا `voice_type` في `public_stories`.
SQL migration draft جاهز في:
`supabase/migrations/draft_add_public_stories_content_columns.sql`

**لا ينفّذ** إلا عند الحاجة الفعلية لنقل قصص لـ Supabase. حالياً ليلى محلية ولا تحتاج هذا.

### Cinema + Audio Assets
عند ربط الصوت المحلي للقصة، احذر:
- `cinema_screen.dart` يستخدم `_audioPlayer.play(UrlSource(url))` للروابط
- للـ assets يحتاج `AssetSource(path)` بدل `UrlSource`
- يحتاج فحص: إذا `audio_url.startsWith('assets/')` → `AssetSource` وإلا `UrlSource`

### audioplayers + Windows
البناء على Windows فشل سابقاً بسبب NuGet (`audioplayers_windows`).
استخدم Android للاختبار، أو Chrome web للتجربة المحدودة.

---

## 🎯 ترتيب الأولويات

1. **توليد صوت ليلى** (التنفيذ البشري) → ربط الصوت → اختبار end-to-end
2. **إنتاج 4 قصص باقية** للمكتبة العامة (سباق الغابة + مصباح الأمنيات + البذرة + مرآة الغابة) عبر Content Studio
3. **بعد 5 قصص جاهزة** → نقل لـ Supabase `public_stories` (يحتاج ALTER TABLE أولاً)
4. **بعد الإطلاق المغلق** → IAP + Apple Developer + Google Play (Phase 6)
5. **Phase 7** → الإطلاق الرسمي + متجر Hostinger

---

**Restore Points:**
- محلي + GitHub: `before_external_public_library_content_studio` @ `8003ffa`

**الـ Push التالي يجب أن يكون:** بعد توليد الصوت + ربطه + اختبار ناجح، بـ tag جديد:
`audio_layla_wolf_complete`
