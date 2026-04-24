# TEST CHECKLIST — حكواتي
**آخر تحديث:** 2026-04-23
**الغرض:** اختبارات قبول لكل Phase قبل إنشاء نقطة الاستعادة

---

## Phase 1 — App Launch Core Lock

### اختبارات Git
- [ ] `git status` nothing to commit
- [ ] `git log --oneline main` يظهر commit `41acf97`
- [ ] `git branch --contains 41acf97` يظهر `main`
- [ ] HEAD ليست detached

### 4 مسارات اختبار التطبيق

#### المسار 1 — إنشاء قصة عادية
- [ ] المستخدم مسجّل الدخول
- [ ] رصيد ظاهر صحيح في AppBar
- [ ] صفحة إنشاء القصة تعرض: القصة = -10 ⭐
- [ ] لا "مضمن" أو "مجاني"
- [ ] ضغط "اصنع السحر" يبدأ التوليد
- [ ] بعد النجاح: يُخصم 10 ⭐ من الرصيد
- [ ] الرصيد في AppBar يتحدث فوراً
- [ ] القصة تظهر في المكتبة الخاصة

#### المسار 2 — إنشاء قصة مع أفاتار + صوت مستنسخ
- [ ] تفعيل الأفاتار → الإجمالي يصبح -20 ⭐
- [ ] تفعيل الصوت المستنسخ → الإجمالي يصبح -40 ⭐
- [ ] الزر يعرض: "اصنع السحر!  -40 ⭐"
- [ ] بعد النجاح: خصم 40 ⭐ فقط (ليس مرتين)
- [ ] **ملاحظة:** إذا تم تعطيل cloned voice في batch-008 — يُتخطى هذا المسار

#### المسار 3 — فتح قصة من المكتبة الخاصة
- [ ] الضغط على قصة محفوظة
- [ ] تفتح مباشرة بدون توليد
- [ ] **صفر خصم** من الرصيد
- [ ] الرصيد لا يتغير

#### المسار 4 — فتح قصة من المكتبة العامة (جديدة)
- [ ] الضغط على قصة عامة غير مفتوحة مسبقاً
- [ ] يظهر تأكيد الخصم
- [ ] بعد الموافقة: خصم 10 ⭐
- [ ] القصة تُحفظ في مكتبته الخاصة
- [ ] إعادة فتحها = صفر خصم

### اختبارات الدخول (بعد batch-002 ✅)
- [ ] التطبيق يفتح → المستخدم المسجّل يدخل مباشرة للرئيسية
- [ ] تسجيل خروج → إعادة فتح → شاشة الدخول
- [x] **signup جديد → profile يُنشأ فوراً (eager)** — مُنجز في batch-002
  - `AuthUseCases.signUpEmail()` يستدعي `SupabaseService.ensureProfileExists(userId)`
  - `ensureProfileExists` يتعامل مع duplicate (لا crash)
- [x] **رصيد المستخدم الجديد = 20 ⭐** — مُنجز في batch-002b
  - `supabase_service.dart:60` → `'credits': 20`
  - المستخدم الموجود لا يتأثر (skip إذا existing != null)
  - يتوقع: signup جديد → رصيد 20 ⭐ يظهر في AppBar فور الدخول
- [x] **Google Sign-In: مُعطّل رسمياً** — مُنجز في batch-002
  - UI: لا يحتوي Google button (لا يوجد أصلاً)
  - Logic: `signInWithGoogle()` يرمي `[DISABLED_FOR_FIRST_LAUNCH]` exception
  - Comment `TODO(phase-6)` موجود للإعادة لاحقاً

**Verification النهائية:**
- [ ] `flutter analyze`: 0 errors, 0 warnings (من تغييراتنا)
- [ ] `flutter build apk --debug`: success

**عند اكتمال كل ما سبق:** إنشاء `rp-01-launch-core-lock`.

---

## Phase 2 — Internal Commerce Readiness

### batch-004 (Redeem Card)
- [ ] زر "لديك كرت شحن؟" في StoreScreen
- [ ] شاشة redeem تفتح
- [ ] حقل إدخال يقبل 12 خانة (XXXX-XXXX-XXXX)
- [ ] Validation يمنع كود قصير/طويل
- [ ] زر "تفعيل" يعمل (placeholder SnackBar في Phase 2)

### batch-005 (Orders Screen)
- [ ] زر "طلباتي" في ProfileScreen
- [ ] شاشة orders تفتح
- [ ] حالة فارغة تظهر "لا توجد طلبات بعد"

### batch-006 (Product IDs)
- [ ] ملف `product_ids.dart` موجود
- [ ] الـ Constants متاحة للاستخدام
- [ ] `flutter analyze` 0 errors

### batch-007 (External Store Link)
- [ ] زر "منتجات حكواتي" في Profile
- [ ] زر "منتجات حكواتي" في Drawer
- [ ] الضغط يفتح https://hikayati.com في المتصفح
- [ ] لا ذكر لكلمة "كريدت" في النص

### batch-008 (Cloned Voice Disable)
- [ ] Create Story: بطاقة cloned voice إما مخفية أو معطّلة
- [ ] رسالة واضحة إذا معطّلة ("قيد الصيانة")
- [ ] الصوت العادي (Pollinations) يعمل

**Verification:**
- [ ] `flutter analyze`: 0 errors
- [ ] `flutter build apk --debug`: success
- [ ] Manual test كل شاشة جديدة

**عند الاكتمال:** `rp-02-internal-commerce-readiness`.

---

## Phase 3 — External Store Build on Hostinger

- [ ] hikayati.com يفتح ويعرض الصفحة الرئيسية
- [ ] 4 صفحات منتجات تعمل:
  - [ ] /store/tshirts
  - [ ] /store/booklets
  - [ ] /store/magazines
  - [ ] /store/credit-cards
- [ ] صفحة منتج مفرد تعرض التفاصيل
- [ ] سلة localStorage تعمل (إضافة/حذف/تحديث كمية)
- [ ] صفحة checkout skeleton جاهزة
- [ ] الهوية البصرية 100% مطابقة للتطبيق
- [ ] RTL + Arabic perfect
- [ ] Mobile responsive
- [ ] Lighthouse Performance 85+
- [ ] Lighthouse Accessibility 90+

**عند الاكتمال:** `rp-03-hostinger-store-build`.

---

## Phase 4 — Orders + Invoices + Redeem Automation

### Supabase
- [ ] جدول `orders` موجود مع RLS
- [ ] جدول `invoices` موجود مع RLS
- [ ] جدول `credit_cards` موجود مع RLS
- [ ] indexes على user_id + status + code

### Edge Functions
- [ ] `payment-webhook` منشور
- [ ] `generate-invoice` منشور
- [ ] `redeem-card` منشور
- [ ] `send-email` منشور
- [ ] `notify-printer` منشور

### اختبارات تكامل
- [ ] إدراج order يدوي → generate-invoice → PDF في Storage
- [ ] استدعاء redeem-card بكود صالح → الرصيد يزيد في `profiles.credits`
- [ ] استدعاء redeem-card بكود مستخدم → error واضح
- [ ] استدعاء redeem-card بكود غير موجود → error واضح
- [ ] Flutter redeem screen يتصل فعلياً بالـ Edge Function

### Email
- [ ] قالب order-confirmation يُرسل في dev
- [ ] قالب credit-card-delivered يُرسل مع الكود
- [ ] قالب invoice-email يُرسل مع PDF attachment

**عند الاكتمال:** `rp-04-orders-invoices-redeem`.

---

## Phase 5 — Marketing + Legal Lock

### محتوى
- [ ] 5 قصص دعائية في المكتبة العامة (كاملة مع صور)
- [ ] صور منتجات:
  - [ ] 5 mockup تيشيرتات
  - [ ] 3 mockup كتيبات
  - [ ] 1 mockup مجلة
  - [ ] 4 بطاقات كروت كريدت
- [ ] فيديو دعائي 30 ثانية (Hero على hikayati.com)

### SEO
- [ ] meta title لكل صفحة hikayati.com
- [ ] meta description لكل صفحة
- [ ] Open Graph tags
- [ ] Twitter Cards
- [ ] robots.txt + sitemap.xml

### Legal على hikayati.com
- [ ] privacy.html
- [ ] terms.html
- [ ] refund.html
- [ ] shipping.html
- [ ] children-policy.html (COPPA)
- [ ] data-deletion.html

### Lighthouse SEO
- [ ] 90+ على كل صفحة

**عند الاكتمال:** `rp-05-marketing-legal-lock`.

---

## Phase 6 — Paid Activations After Salary

- [ ] Apple Developer Program مفعّل
- [ ] App Store Connect app listing جاهز
- [ ] 4 IAP products منشأة في ASC
- [ ] Google Play Console مفعّل
- [ ] 4 Play Billing products منشأة
- [ ] Moyasar/Tap حساب live
- [ ] API keys في Edge Functions
- [ ] ElevenLabs billing حلّ + اختبار voice cloning
- [ ] Resend/Brevo domain verified
- [ ] Print partner account active

**Sandbox Tests:**
- [ ] شراء IAP Apple Sandbox → رصيد يزيد
- [ ] شراء Google Play Sandbox → رصيد يزيد
- [ ] شراء Moyasar Sandbox → webhook يصل → order يُنشأ
- [ ] إرسال بريد اختبار Resend → يصل
- [ ] طلب طباعة تجريبي → print partner يستقبل

**عند الاكتمال:** `rp-06-paid-activations`.

---

## Phase 7 — Final Launch Ops

### App Store
- [ ] Metadata مكتملة
- [ ] Screenshots رُفعت (6.7" iPhone + 12.9" iPad)
- [ ] Build مرفوع عبر Xcode/Transporter
- [ ] Data Privacy form مكتمل
- [ ] Age rating 4+
- [ ] Category: Education/Kids
- [ ] Submitted for review

### Google Play
- [ ] App listing مكتمل
- [ ] AAB مرفوع
- [ ] Data Safety form مكتمل
- [ ] Content rating
- [ ] Closed Testing → Internal → Production

### hikayati.com
- [ ] Webhooks active
- [ ] Payment gateway live
- [ ] أول 10 طلبات test ناجحة

### Monitoring
- [ ] Supabase logs مراقبة
- [ ] Error tracking مفعّل (Sentry اختياري)

**Launch Day:**
- [ ] التطبيق available على App Store
- [ ] التطبيق available على Google Play
- [ ] hikayati.com يستقبل طلبات حقيقية
- [ ] أول طلب real-money ناجح

**عند الاكتمال:** `rp-07-final-launch-ops` — 🚀 **LIVE**.

---

**نهاية قائمة الاختبارات**
