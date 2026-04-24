# PROJECT STATUS — حكواتي
**آخر تحديث:** 2026-04-25
**المرحلة الحالية:** Phase 1 ✅ | قصة ليلى ✅ صور + نص + ربط محلي | ⏳ تنتظر توليد الصوت

---

## 🎯 الحالة الحقيقية الآن (Snapshot)

### ما هو مُكتمل 100%
- ✅ Code كامل التطبيق (Auth، Credits، Libraries، Cinema، Avatar، Voice، Store UI)
- ✅ Content Studio خارجي بـ 7 قوالب + 8 مجلدات
- ✅ قصة ليلى والذئب — Story Bible + Character Bibles + Final Script (6 مشاهد عربية)
- ✅ 7 Image Prompts جاهزة (layla_reference + 6 scenes) — مُثبّتة على المرجعية
- ✅ صورة ليلى المرجعية معتمدة: `content_studio/public_library/04_images/layla_wolf/layla_reference.png`
- ✅ 6 صور مشاهد منتجة وموجودة: `assets/public_library/layla_wolf/images/scene_01-06.jpeg`
- ✅ `SmartImage` widget — يدعم asset + network تلقائياً
- ✅ قصة ليلى مُدمجة محلياً في `library_service.dart` بـ UUID `11111111-1111-1111-1111-111111111111`
- ✅ Cinema تعرض الصور المحلية بشكل صحيح
- ✅ Dev-only Audio Export Service + Panel جاهزة (مخفية للمستخدم العادي)
- ✅ `pubspec.yaml` يسجّل assets المكتبة العامة

### ما ينتظر التنفيذ البشري الآن
- ⏳ **توليد صوت ليلى المُصدَّر** — يحتاج تشغيل التطبيق بـ:
  ```
  flutter run --dart-define=PUBLIC_LIBRARY_AUDIO_EXPORT=true
  ```
  ثم فتح ليلى → زر التحميل في AppBar → توليد
  المخرج: 6 ملفات mp3 + `audio_manifest.json` في
  `content_studio/public_library/05_audio/layla_wolf/`

- ⏳ **ربط الصوت بالقصة** — بعد التوليد، تحديث `_laylaWolfStaticStory.scenes_json[].audio_url` لتُشير لمسار `assets/public_library/layla_wolf/audio/scene_N.mp3` (نقل الملفات لـ assets + تسجيلها في pubspec)

- ⏳ **اختبار end-to-end** بحساب جديد (20 ⭐ → فتح ليلى → خصم 10 → تجربة كاملة)

- ⏳ **نقل ليلى لـ Supabase `public_stories`** (اختياري — قد نُبقيها محلية للإطلاق)

### ما هو مؤجل (دفع/تفعيل خارجي)
- ⏳ Apple Developer + Google Play (بعد الراتب)
- ⏳ IAP / Moyasar live
- ⏳ ElevenLabs billing
- ⏳ المتجر الخارجي Hostinger
- ⏳ 4 قصص أخرى للمكتبة العامة (سباق الغابة + مصباح الأمنيات + البذرة + مرآة الغابة)

---

---

## 🔄 قرار جديد 2026-04-24 — Content Pipeline Pivot

**لم يعد إنتاج قصص المكتبة العامة يتم من داخل التطبيق.**

بعد اختبار قصة "ليلى والذئب" من التطبيق وفشل معايير الجودة (5 مشاهد بدل 6، شخصية غير ثابتة، تشوّه أيدي، نص ضعيف):
- ✅ تم إنشاء **Content Studio خارجي**: `content_studio/public_library/`
- ✅ 7 قوالب احترافية (Story Bible, Character Bible, Scene Sheet, Image Prompt, Import JSON, QC Checklist, README)
- ✅ 8 مجلدات للتنظيم (00_catalog → 07_qc_reports)
- ⚠️ `publicLibraryProduction` flag يبقى كأداة **اختبار/تطوير فقط** — ليس مصدر إنتاج الإطلاق

**المرجع الكامل:** `content_studio/public_library/README_PUBLIC_LIBRARY_CONTENT_PIPELINE.md`
**Restore Point:** `before_external_public_library_content_studio` (✅ GitHub)

---

## النظام المرحلي المعتمد (7 Phases)

| Phase | الاسم | الحالة | Restore Point |
|---|---|---|---|
| 1 | App Launch Core Lock | 🟡 قيد التنفيذ | `rp-01-launch-core-lock` |
| 2 | Internal Commerce Readiness | ⏳ تنتظر Phase 1 | `rp-02-internal-commerce-readiness` |
| 3 | External Store Build on Hostinger | ⏳ تنتظر Phase 2 | `rp-03-hostinger-store-build` |
| 4 | Orders + Invoices + Redeem Automation | ⏳ يمكن التوازي مع 3 | `rp-04-orders-invoices-redeem` |
| 5 | Marketing + Legal Lock | ⏳ تنتظر 3+4 | `rp-05-marketing-legal-lock` |
| 6 | Paid Activations After Salary | ⏳ بعد الراتب | `rp-06-paid-activations` |
| 7 | Final Launch Ops | ⏳ بعد Phase 6 | `rp-07-final-launch-ops` |

---

## المرجع الرئيسي

- **الخطة النهائية:** `خطة_المشروع/خطة_الإطلاق_السريع_النهائية.md`
- **خطة التنفيذ:** `خطة_المشروع/خطة_تنفيذ_كلود_المرحلية.md`
- **نقاط الاستعادة:** `خطة_المشروع/نقاط_الاستعادة_المعتمدة.md`

---

## القرارات المقفلة (لا تُناقش مرة أخرى)

- التطبيق Flutter — كما هو
- Backend Supabase — كما هو
- المتجر الخارجي: **Hostinger Premium + HTML/CSS/JS/PHP + Supabase**
- **لا نستخدم:** سلة / Next.js server / أي SaaS خارجي
- الدومين: hikayati.com (مملوك)
- الإطلاق السريع يشمل: التطبيق + الكريدت + المكتبة + الكتيب + المجلة + كروت الكريدت + الطلبات + الفواتير + البريد + الأتمتة + الصفحات القانونية
- الصياغة في التطبيق: "منتجات حكواتي" — بدون ذكر كريدت في الربط الخارجي

---

## الـ Dفعات القديمة (7 Batches) — ملغاة لصالح 7 Phases الجديدة

| Batch قديم | Phase المقابلة |
|---|---|
| 1-5 (أفاتار/صوت/رصيد/مكتبات/هوية) | Phase 1 (مُغلقة بالفعل تقنياً) |
| 6 (متجر داخلي) | Phase 2 + Phase 6 |
| 7 (إطلاق) | Phase 7 |

---

## الحالة التقنية الحالية

### ما هو جاهز 100%
- Auth + Session persistence + refresh + valid check
- Credit realtime display
- Anti-double deduction
- Private library (no deduction)
- Public library + unlock
- Avatar system (vision + 4 options + prompt_snippet)
- Standard voice (Pollinations)
- Cinema (audio_url only)
- Visual identity + ⭐ + red/green/orange
- Dynamic pricing (10/10/20 ⭐)
- 4 legal pages in app
- Consent dialogs

### ما هو ناقص (سيُبنى في Phases 2-4)
- Redeem card screen (Phase 2)
- Orders screen (Phase 2)
- External store hikayati.com (Phase 3)
- Supabase tables: orders, invoices, credit_cards (Phase 4)
- Edge Functions: webhook, redeem, invoice, email (Phase 4)
- Email templates (Phase 4)
- 5 dem stories + product images (Phase 5)
- Legal pages on hikayati.com (Phase 5)

### ما هو مؤجل (فقط بسبب دفع/تفعيل خارجي)
- Apple Developer Program ($99/سنة)
- Google Play Console ($25)
- IAP live activation
- ElevenLabs billing (يوم الاثنين)
- Moyasar/Tap live
- Print partner account
- Resend/Brevo API key

---

## Audit Findings — 2026-04-23

### Git State
- **HEAD**: `41acf97` — detached from `627e6cc`
- **main (local + origin)**: `ec490d3` (قديم — commits آخر جلستين غير موجودة عليه)
- **Tags**:
  - `before_store` → `41acf97` ✅ على GitHub
  - `before_payment_credit_currency_lock` → `38f8bc4` ✅ محلي
- **Commits آخر جلستين غير موجودة على أي branch** — محفوظة فقط كأهداف tags
- **Phase 1 Batch 001 سيحل هذا** (fast-forward merge)

### Login Flow Root Cause
- **ليس bug** — سلوك UX صحيح
- Supabase SDK يحفظ الجلسة تلقائياً في `shared_preferences` (50%)
- `main.dart:19-28` يُجدّد الجلسة عند boot (30%)
- `app_router.dart:37-59` يتحقق من `expiresAt` ويُوجّه (20%)
- لا يوجد splash screen — الـ router redirect هو الـ gate

### Blockers قبل الإطلاق
1. Git: دمج commits إلى main (Phase 1 batch-001)
2. IAP: مؤجل بالدفع (Phase 6)
3. ElevenLabs: فاتورة معلّقة (حل الاثنين)
4. Google Sign-In: `webClientId = null` — قرار: تعطيل رسمي (Phase 1 batch-002)

---

## Batches المنجزة — Phase 1

| Batch | الحالة | النتيجة |
|---|---|---|
| `batch-001-phase1-git-consolidation` | ✅ مُغلقة (2026-04-24) | main تحرّك إلى `1d23c95`، HEAD ليست detached، 5 branches محذوفة |
| `batch-002-phase1-auth-decisions` | ✅ مُغلقة (2026-04-24) | Eager profile + Google Sign-In disabled |
| `batch-002b-initial-credits-adjustment` | ✅ مُغلقة (2026-04-24) | رصيد البداية: 100 → 20 ⭐ |
| `batch-003c-avatar-credit-clarity` | ✅ مُغلقة (2026-04-24) | شارات الكرت واضحة + ألوان صحيحة |
| `batch-003d-public-library-premium-mode` | ✅ مُغلقة (2026-04-24) | Config + 6 scenes + imageEnhancer + قيود تلقائية |
| `batch-004-public-library-content-verification` | ⚠️ Code done, content pending | Audit PASS، SQL draft جاهز، 0 قصص منتجة |

## Restore Points الحالية

| Tag | Commit | الحالة |
|---|---|---|
| `before_store` | `41acf97` | ✅ GitHub |
| `before_payment_credit_currency_lock` | `38f8bc4` | محلي |
| `before_public_library_premium_generation` | `1d23c95` | محلي |
| `before_public_library_content_verification` | `a371539` | ✅ GitHub |

## الخطوة التالية

**ليست الدفع.** يحتاج أولاً:

1. **إنتاج 5 قصص المكتبة العامة يدوياً** (راجع `PUBLIC_LIBRARY_CLOSURE_REPORT.md` قسم 11)
2. **تنفيذ ALTER TABLE migration** في Supabase:
   `supabase/migrations/draft_add_public_stories_content_columns.sql`
3. **نقل القصص** إلى `public_stories` عبر SQL
4. **اختبار end-to-end** بحساب مستخدم جديد
5. **ثم** نبدأ Phase 2 — Payment Readiness

**التقرير الكامل:** `PUBLIC_LIBRARY_CLOSURE_REPORT.md`
