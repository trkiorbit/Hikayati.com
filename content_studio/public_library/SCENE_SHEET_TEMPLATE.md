# Scene Sheet — قالب جدول المشاهد
**الغرض:** جدول موحّد لكل 6 مشاهد في القصة، يُملأ قبل أي توليد صورة أو صوت.

> استخدم جدول واحد لكل قصة. سَمِّ الملف: `<story-slug>_scene_sheet.md` مثل `layla_wolf_scene_sheet.md`

---

## معلومات أساسية

| الحقل | القيمة |
|---|---|
| **story_title** | (اسم القصة) |
| **character_bible** | مرجع ملف `02_visual_bibles/<story>_character.md` |
| **style_locked** | cinematic 3D storybook, warm lighting, premium children quality |
| **total_scenes** | 6 |

---

## جدول المشاهد

| scene_number | arabic_text | visual_description | character_position | emotion | environment | camera_angle | image_prompt | audio_text | qc_status |
|:---:|---|---|---|---|---|---|---|---|:---:|
| 1 | (3-5 أسطر نص سردي عربي) | (وصف بصري EN: ما يحدث، ما يُرى) | center / left / right / background | curious / happy / surprised / concerned / proud / peaceful | forest path / cozy home / mountain / sky / cave / garden | close-up / medium shot / wide shot / over-shoulder / low angle | (Prompt كامل جاهز للـ image generator — انسخه من `IMAGE_PROMPT_TEMPLATE.md`) | (نفس arabic_text أو نسخة مُنقّحة للنطق) | ⏳ |
| 2 | | | | | | | | | ⏳ |
| 3 | | | | | | | | | ⏳ |
| 4 | | | | | | | | | ⏳ |
| 5 | | | | | | | | | ⏳ |
| 6 | | | | | | | | | ⏳ |

**qc_status values:** ⏳ draft / 🟡 in review / ✅ approved / ❌ rejected

---

## قواعد التعبئة

### arabic_text
- عربية فصحى سهلة
- 3-5 أسطر لكل مشهد (بين 40-80 كلمة)
- جمل قصيرة غنية
- لا خلط لغات
- لا ذكر "مشهد رقم X" داخل النص
- صالح للنطق TTS بدون تعديلات

### visual_description
- إنجليزية موجزة
- يصف **الفعل والبيئة فقط** (لا يصف الشخصية — الشخصية ثابتة من Character Bible)
- مثال: `Layla walks carefully on a glowing forest path at dusk, tall magical trees around her, fireflies floating in the air`

### character_position
- center: البطلة في منتصف الإطار
- left / right: على جانب
- background: في العمق
- over-shoulder: لقطة من خلفها

### emotion
- يُظهر على الوجه
- يجب أن يتطور عبر المشاهد (لا تكرار 6 مشاهد بنفس التعبير)

### environment
- مكان واضح من قائمة محدودة (forest / home / mountain / sky / etc.)
- يتطور القصة

### camera_angle
- close-up: تركيز على الوجه/التعابير
- medium shot: من الخصر لفوق
- wide shot: إطار كامل + بيئة
- over-shoulder: لقطة من خلف الشخصية
- low angle: كاميرا منخفضة (تُعطي شعور ضخامة/بطولة)

### image_prompt
- **المنشأ بناءً على:** `IMAGE_PROMPT_TEMPLATE.md`
- يُحقَن: scene description + character bible + style + negative prompt
- يُقرأ وينقَّح يدوياً قبل إرساله للـ generator

### audio_text
- عادةً نفس `arabic_text`
- قد يُعدَّل قليلاً لسلاسة النطق TTS
- مثال: "١" → "واحد"، "ه-ا-ل-و" → "هالو"

---

## QC الخاص بالمشهد

بعد توليد الصورة والصوت لكل مشهد:

- [ ] الصورة تُطابق visual_description
- [ ] الشخصية تُطابق Character Bible تماماً
- [ ] لا تشوّه في اليدين/القدمين/الوجه
- [ ] لا نص أو logo في الصورة
- [ ] الصوت يُطابق audio_text
- [ ] الصوت واضح بدون تقطع
- [ ] لا أخطاء نطق واضحة
- [ ] qc_status = ✅ approved

**عند فشل أي مشهد:** إعادة التوليد (لا تقبل scene ناقص).
