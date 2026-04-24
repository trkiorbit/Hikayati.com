-- ═══════════════════════════════════════════════════════════════════
-- DRAFT — لا يُنفّذ الآن
-- Phase: Public Library Content Transfer
-- الغرض: إضافة الأعمدة المطلوبة لحفظ مشاهد القصص العامة
-- ═══════════════════════════════════════════════════════════════════

-- الخطوة 1 — إضافة الأعمدة الناقصة إلى public_stories
-- (idempotent: آمن التنفيذ أكثر من مرة)
ALTER TABLE public.public_stories
  ADD COLUMN IF NOT EXISTS scenes_json JSONB,
  ADD COLUMN IF NOT EXISTS voice_type VARCHAR(20) DEFAULT 'echo';

-- الخطوة 2 — تحقق من إضافة الأعمدة
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'public_stories'
ORDER BY ordinal_position;
-- النتيجة المتوقعة: id, title, summary, cover, price_credits, category,
--                   created_at, scenes_json, voice_type

-- ═══════════════════════════════════════════════════════════════════
-- سكربت نقل قصة (استبدل المتغيرات قبل التنفيذ)
-- ═══════════════════════════════════════════════════════════════════

-- استبدل:
-- <STORY_UUID>      = id القصة من جدول stories
-- <SUMMARY>         = وصف تسويقي قصير (جملتين أو ثلاث)
-- <CATEGORY>        = تصنيف: 'مغامرات' / 'خيال' / 'تعليمية' / 'موروث' / 'صداقة'

INSERT INTO public.public_stories (
  title,
  summary,
  cover,
  scenes_json,
  voice_type,
  price_credits,
  category
)
SELECT
  s.title,
  '<SUMMARY>'::TEXT                    AS summary,
  s.cover_image                        AS cover,
  s.scenes_json                        AS scenes_json,
  COALESCE(s.voice_type, 'echo')       AS voice_type,
  10                                   AS price_credits,
  '<CATEGORY>'::VARCHAR(50)            AS category
FROM public.stories s
WHERE s.id = '<STORY_UUID>'::UUID
  AND s.user_id = auth.uid();  -- حماية: المطور فقط يقدر ينقل قصصه

-- تحقق من النقل
SELECT id, title, category, price_credits, created_at
FROM public.public_stories
ORDER BY created_at DESC
LIMIT 5;
