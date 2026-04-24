# Image Prompt Template — قالب برومبت الصورة
**الغرض:** فرض اتساق بصري كامل بين جميع المشاهد وإنتاج صور بجودة كتاب أطفال ممتاز.

> كل prompt يُنشأ من هذا القالب. لا تنتج صورة بدون المرور بهذه البنية.

---

## البنية الإلزامية (5 طبقات)

### 1. Scene Action (من Scene Sheet)
وصف الحدث في المشهد فقط — ليس الشخصية.
```
Layla walks carefully on a glowing forest path at dusk, tall magical trees around her, fireflies floating in the air
```

### 2. Character Lock (من Character Bible — ثابت لكل مشهد)
```
Main character: Layla, a 7-year-old girl with long black hair and warm brown eyes,
wearing a red hooded cape over a white modest dress and brown leather shoes,
rosy cheeks, child proportions, same character design as all other scenes in this story
```

### 3. Camera & Composition (من Scene Sheet)
```
medium shot, slight low angle, Layla centered in frame
```

### 4. Style Lock (ثابت لكل القصص)
```
Style: cinematic 3D storybook illustration, premium children book quality,
warm magical lighting, soft volumetric light, rich detailed environment,
consistent character style across all scenes, safe for children,
Pixar-inspired rendering, high detail
```

### 5. Negative Prompt (ثابت لكل القصص)
```
no deformities, no extra fingers, no missing fingers, no extra limbs,
no distorted face, no melted features,
no text, no watermark, no logo, no signature, no writing anywhere in image,
no adult features on child, no teenager features, no baby features,
no modern clothing, no sunglasses,
no scary elements, no horror, no violence, no blood, no weapons,
no blur on face, no cropped face, no duplicate character,
no mirror reflection, no background text, no photo-realistic photo
```

---

## البرومبت النهائي (جاهز للنسخ)

```
<Scene Action>.
Main character: <Character Lock from Bible>.
Camera: <Camera & Composition>.
Style: cinematic 3D storybook illustration, premium children book quality,
warm magical lighting, soft volumetric light, rich detailed environment,
consistent character style across all scenes, safe for children,
Pixar-inspired rendering, high detail.
Negative: no deformities, no extra fingers, no extra limbs, no distorted face,
no text, no watermark, no logo, no signature,
no adult features, no teenager features, no baby features,
no modern clothing, no sunglasses, no scary elements, no horror, no violence,
no blur on face, no cropped face, no duplicate character, no background text.
```

---

## قواعد صارمة

### إجبارية (لا تُكسر)
- ✅ same character across all scenes (هذه العبارة حرفياً في كل prompt)
- ✅ fixed age (رقم صريح — "7 years old")
- ✅ fixed clothes (من Character Bible حرفياً)
- ✅ fixed facial features (من Character Bible)
- ✅ natural hands (5 fingers each, no extras)
- ✅ natural feet (no deformities)
- ✅ no deformities
- ✅ no text in image
- ✅ no watermark
- ✅ no horror
- ✅ premium 3D cinematic children storybook style

### ممنوعة (لا تُستخدم أبداً)
- ❌ "photo-realistic" (نريد storybook style)
- ❌ "adult", "mature", "baby" عند وصف طفل بعمر 7
- ❌ "modern clothing" / "urban"
- ❌ "action movie" / "dramatic horror"
- ❌ الأسماء العربية بشكل يربك المُولِّد (استخدم الوصف: "a 7-year-old girl" بدل "Layla")

---

## مثال مكتمل — ليلى والذئب، المشهد 2

```
Layla walks carefully on a glowing forest path at dusk, tall magical trees around her,
fireflies floating in the air, small woven basket in her hand.
Main character: Layla, a 7-year-old girl with long black hair and warm brown eyes,
wearing a red hooded cape over a white modest dress and brown leather shoes,
rosy cheeks, child proportions, same character design as all other scenes in this story.
Camera: medium shot, slight low angle, Layla centered in frame.
Style: cinematic 3D storybook illustration, premium children book quality,
warm magical lighting, soft volumetric light, rich detailed forest environment,
consistent character style across all scenes, safe for children,
Pixar-inspired rendering, high detail.
Negative: no deformities, no extra fingers, no extra limbs, no distorted face,
no text, no watermark, no logo, no signature,
no adult features, no teenager features, no baby features,
no modern clothing, no sunglasses, no scary elements, no horror, no violence,
no blur on face, no cropped face, no duplicate character, no background text.
```

---

## Generators المُوصى بها (خارج التطبيق)

### الجودة العالية (للإطلاق)
- **Midjourney v6+** — أفضل اتساق ومشاهد ممتازة
- **Google Imagen 3** — جودة سينمائية
- **Ideogram v2** — ممتاز للتفاصيل والاتساق

### متوسطة (للتجريب)
- **Pollinations flux** — سريع ومجاني لكن أقل اتساقاً
- **Stable Diffusion XL** — تحتاج خبرة في tuning

**القاعدة:** للمكتبة العامة، ابذل وقت للمراجعة والإعادة حتى تصل لنتيجة ممتازة. لا تقبل صورة "حسنة" — اطلب "ممتازة".
