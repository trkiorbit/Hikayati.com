-- ══════════════════════════════════════════════════════════════════
-- Migration: إضافة عمود cloned_voice_id إلى جدول profiles
-- التاريخ: 2026-04-24
-- الهدف: تخزين voice_id لكل مستخدم بشكل دائم في Supabase
--        (مصدر حقيقة لا يُمسح عند signOut/uninstall)
-- ══════════════════════════════════════════════════════════════════
--
-- طريقة التنفيذ:
-- 1. افتح Supabase Dashboard → SQL Editor
-- 2. الصق هذا السكربت كاملاً
-- 3. اضغط Run
-- 4. تحقق من النتيجة في جدول profiles
--
-- آمن للتشغيل على DB إنتاج (IF NOT EXISTS + لا تعديل بيانات موجودة)
-- ══════════════════════════════════════════════════════════════════

-- الخطوة 1: إضافة العمود (آمن — يُتجاهل إن كان موجوداً)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS cloned_voice_id TEXT;

-- الخطوة 2: (اختياري) مزامنة المستخدمين الحاليين الذين voice_clone_enabled=true
--           لكن ليس لديهم cloned_voice_id في DB (سيحتاجون إعادة الإنشاء)
-- لا نشغّل UPDATE تلقائياً — المستخدم يعيد الإنشاء وقت ما يستخدم الميزة.

-- الخطوة 3: تحقق
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name IN ('voice_clone_enabled', 'cloned_voice_id')
ORDER BY column_name;

-- يجب أن تظهر النتيجة:
--   cloned_voice_id     | text    | YES | NULL
--   voice_clone_enabled | boolean | YES | false
