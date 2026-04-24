# Character Bible — قالب بصمة الشخصية
**الغرض:** تثبيت هوية الشخصية عبر جميع المشاهد لتجنّب التضارب البصري.

> ⚠️ **كل image prompt يجب أن يحقن هذه المواصفات حرفياً.**

---

## character_name
(اسم الشخصية بالعربية والإنجليزية)
- **AR:** ليلى
- **EN:** Layla

---

## fixed_age
(العمر بالضبط — يظهر في كل prompt)
- **age:** 7 years old
- **visual_note:** looks like a clearly 7-year-old child (not toddler, not teenager)

---

## face_description
- **shape:** round, soft
- **skin_tone:** warm medium
- **distinctive_features:** rosy cheeks, big expressive eyes
- **freckles:** light freckles across nose (اختياري)

---

## hair
- **color:** long black hair
- **style:** loose, slightly wavy, reaching shoulders
- **accessory:** none (أو: simple red ribbon)

---

## eyes
- **color:** warm brown
- **shape:** large, round, friendly
- **expression_default:** curious and kind

---

## clothes
(ملابس ثابتة طوال القصة — لا تتغيّر)
- **top:** red hooded cape over white modest dress
- **bottom:** (إن وُجد) simple skirt
- **shoes:** brown leather shoes
- **style_note:** traditional fairy-tale look, modest, warm colors

---

## accessories
- **items:** small woven basket (إذا كانت جزءاً من القصة)
- **worn_always:** red hood

---

## body_type
- **build:** slim, age-appropriate child proportions
- **height:** small relative to adults in scene

---

## personality
(يظهر في التعابير البصرية)
- curious
- kind-hearted
- smart
- a bit cautious but not afraid

---

## must_remain_consistent
(خصائص **إلزامية** في كل صورة)

| خاصية | القيمة الثابتة |
|---|---|
| العمر | 7 years |
| لون الشعر | long black |
| لون العينين | brown |
| الملابس الأساسية | red hood + white dress |
| لون البشرة | warm medium |
| الطول النسبي | child proportions |

---

## forbidden_identity_variations
❌ **لا تظهر الشخصية بأي من التالي:**
- لا تظهر كطفل صغير رضيع
- لا تظهر كمراهقة أو بالغة
- لا تغيّر لون الشعر
- لا تظهر بملابس حديثة (جينز / تيشيرت)
- لا تُزال القلنسوة الحمراء
- لا تُستبدل بشخصية أخرى
- لا تظهر متعددة (نسختان في صورة واحدة)

---

## negative_prompt
(يُحقن في كل image prompt — جاهز للنسخ)

```
no deformities, no extra fingers, no extra limbs, no distorted face,
no text, no watermark, no logo, no signature,
no adult features, no teenager features, no baby features,
no modern clothing, no hijab style variations, no sunglasses,
no scary elements, no horror, no violence, no weapons,
no blur on face, no cropped face, no duplicate character,
no mirror reflection of character, no background text
```

---

## Usage in Every Scene Prompt

```
[scene description]...
Main character: Layla, a 7-year-old girl with long black hair and warm brown eyes,
wearing a red hooded cape over a white modest dress and brown leather shoes,
rosy cheeks, child proportions, same character as previous scenes.
Style: cinematic 3D storybook illustration, high detail, warm magical lighting,
premium children book quality, safe for children, consistent character design.
Negative: [negative_prompt above]
```
