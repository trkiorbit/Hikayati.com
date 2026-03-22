# HIKAYATI_MASTER_SPEC_KIT_FULL.md

# 🚀 HIKAYATI — MASTER SPEC KIT (PRO VERSION)

هذا الملف هو:
👉 الدستور الكامل
👉 نظام التشغيل
👉 خطة التنفيذ
👉 نظام إدارة الوكلاء

أي Agent أو AI يعمل على المشروع يجب أن يعتمد هذا الملف فقط.

---

# 🎯 1. تعريف المشروع

## الاسم:
Hikayati (حكواتي)

## النوع:
AI Storytelling Platform + Cinematic Experience + Monetization System

## الهدف:
تحويل الطفل إلى بطل قصة مخصصة تُعرض كتجربة سينمائية قابلة للحفظ والبيع.

---

# 🧠 2. المعمارية (Architecture)

## Layers:

### 1. Presentation
- Flutter UI
- Screens only
- NO business logic

### 2. Application
- UseCases فقط
- orchestration logic

### 3. Domain
- Models
- Entities

### 4. Services
- AI Services
- Backend Services

### 5. Backend
- Supabase

---

# ⚠️ 3. القوانين الصارمة (NON-NEGOTIABLE)

1. UI لا تستدعي AI مباشرة
2. CinemaScreen = عرض فقط
3. IntroCinematicScreen = تحميل فقط
4. Story generation فقط داخل UseCase
5. Avatar لا يدخل StoryWizard
6. كل Service منفصلة
7. لا Feature خارج المرحلة الحالية

---

# 🔄 4. التدفق الأساسي (FLOW)

StoryWizard → GenerateStoryUseCase → UnifiedEngine → Intro → Cinema

---

# 🧠 5. Story Engine

## المدخلات:
- heroName
- age
- style

## المخرجات:
- storyData

---

# 🗄️ 6. قاعدة البيانات

Tables:
- profiles
- stories
- public_stories
- unlocked_stories
- credits
- orders

---

# 🛒 7. نظام الربح

- Credits
- Unlock
- Digital
- Physical (future)

---

# 🧪 8. مراحل المشروع (PHASES)

## Phase A — Stabilization
Fix runtime issues

## Phase 1 — Story Flow
Generate + Cinema

## Phase 2 — Auth + Save
Auth + Private Library

## Phase 3 — Public Library
Explore + Unlock

## Phase 4 — Settings

## Phase 5 — Store

## Phase 6 — Avatar + Voice

## Phase 7 — Advanced AI

---

# 🧩 9. نظام التنفيذ (BATCH SYSTEM)

## كل العمل يتم عبر Batches فقط

### كل Batch يحتوي:
- الهدف
- الملفات
- الوكلاء
- التحقق

---

# 🧠 10. إدارة الوكلاء

## القواعد:
- لا يعمل أكثر من 3 وكلاء إلا عند الحاجة
- كل وكيل له ملفات محددة
- ممنوع لمس ملفات خارج المهمة

---

# 🔁 11. نظام الاستئناف (CRITICAL)

عند التوقف:

يجب حفظ:
- Current Phase
- Current Batch
- NEXT_BATCH

عند العودة:
- يبدأ من NEXT_BATCH مباشرة
- لا يسأل المستخدم

---

# 📊 12. ملفات الحالة

## REQUIRED:

### HIKAYATI_RUNTIME_STATUS.md
### task.md
### سجل_الأخطاء.md

---

# 🧨 13. تقليل التوكن (CRITICAL)

## ممنوع:
- تحليل المشروع كامل كل مرة
- إعادة شرح Spec
- تنفيذ مراحل كاملة دفعة واحدة

## المطلوب:
- Batch صغيرة
- تحقق بعد كل Batch

---

# 🔧 14. WORKFLOW

1. Read State
2. Define Batch
3. Execute
4. Verify
5. Update State

---

# 🧪 15. VERIFICATION

### كل Batch:
- flutter analyze
- runtime test

---

# 🎯 16. Definition of Done

- Create story
- Watch story
- Save story
- Unlock story

---

# 🚨 17. BLOCKER POLICY

إذا ظهر خطأ:
- سجل في سجل_الأخطاء.md
- أنشئ Batch خاصة
- لا تكمل

---

# 🚀 18. EXECUTION COMMAND

اقرأ هذا الملف فقط.

ابدأ من الحالة الحالية.

قسّم العمل إلى Batches.

نفّذ Batch واحدة فقط في كل مرة.

تحقق.

حدث الحالة.

ثم أكمل.

---

# 🔚 النهاية

هذا الملف = النظام الكامل

أي انحراف عنه = خطأ معماري
