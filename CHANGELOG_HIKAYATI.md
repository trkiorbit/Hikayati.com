# سجل التغييرات - Hikayati Project

## [Batch: Fix Avatar Creation + Private Library Integrity] - 2026-03-21

### 🚀 ميزات جديدة (Added)
- **PromptBuilderService:** 
  - إنشاء خدمة مستقلة وموحدة لهندسة وصف الصور.
  - دمج (وصف المشهد + هوية الأفاتار + الملابس الحالية + الستايل) في Prompt واحد.
  - إضافة قاعدة "Same character across all scenes" لضمان ثبات الشخصية.

- **Avatar Generation System (New Logic):**
  - استبدال نظام تحليل الصور (Vision AI) بنظام "توليد الخيارات".
  - الدالة الجديدة `generateAvatarOptions` تنتج 4 خيارات فورية بناءً على مدخلات المستخدم (العمر، الجنس، البشرة، الشعر).
  - إلغاء الحاجة لرفع صورة للتحليل، والاعتماد على الاختيار المباشر.

### 🛠 تعديلات جوهرية (Changed)
- **UnifiedEngine (محرك القصة):**
  - إجبار جميع طلبات الصور على المرور عبر `PromptBuilderService`.
  - تحديث رابط API الصور لاستخدام `Pollinations` مع موديل `flux`.
  - تحسين منطق الـ `seed`: استخدام `storySeed + index` لضمان تنوع المشاهد مع الحفاظ على بصمة القصة.
  - تصحيح صيغة تمرير مفتاح API الصور من `key` إلى `api_key`.

- **AvatarVisionService:**
  - إزالة مكتبات `google_generative_ai` و `flutter_dotenv` من هذا الملف (فك الارتباط بـ Gemini).
  - إزالة البيانات الوهمية (Dummy Data) واستبدالها ببيانات ديناميكية قادمة من المدخلات.
  - [إصلاح] تحديث الواجهة لاستخدام `generateAvatarOptions` بدلاً من الدالة المحذوفة.

### 🐛 إصلاحات (Fixed)
- **Image Generation 401 Error:** حل مشكلة رفض طلبات الصور بسبب صيغة المفتاح الخاطئة.
- **Database Integrity:** إضافة `SupabaseService.ensureProfileExists(userId)` قبل حفظ القصة لمنع خطأ المفتاح الأجنبي (`stories_user_id_fkey`).
- **Prompt Null Safety:** معالجة القيم الفارغة في سمات الأفاتار لتجنب ظهور كلمة `null` في وصف الصورة.

---

## [Phase A: Stabilization] - السابقة
- تأسيس معمارية Clean Architecture.
- فصل الخدمات (Story, Image, Voice).
- اعتماد Supabase كـ Backend.
- توحيد ملفات المواصفات (Specs).