# Character Bible — ليلى (layla)
**Story:** ليلى والذئب الذكي
**الإصدار:** 2.0 — **مُثبّت على الصورة المرجعية المعتمدة**
**المرجع البصري الرسمي:** `content_studio/public_library/04_images/layla_wolf/layla_reference.png`

---

## 🔒 الصورة المرجعية المعتمدة

```
📁 content_studio/public_library/04_images/layla_wolf/layla_reference.png
```

**هذه هي الهوية الرسمية لليلى.** أي صورة مشهد تختلف عن هذه المرجعية في الوجه أو الملابس أو الشعر أو العمر تُرفض تلقائياً في QC.

**في كل image prompt يجب أن يُذكر حرفياً:**
> Use the approved Layla reference image as the identity anchor.

---

## character_name
- **AR:** ليلى
- **EN:** Layla
- **note_for_image_generator:** Refer to reference image. Use description "an 8-year-old Arab girl" — not the name directly, to avoid generator confusion.

---

## fixed_age
- **age:** 8 years old (بالضبط — ليست 7، ليست 9)
- **visual_note:** تبدو بوضوح كطفلة في الثامنة — **لا رضيعة، لا مراهقة**
- **proportions:** child proportions — head slightly larger relative to body, small hands, short stature
- **strict rule:** Do not change her age in any scene.

---

## face_description
(مأخوذ حرفياً من الصورة المرجعية المعتمدة)

- **shape:** round, soft, natural child face
- **skin_tone:** warm olive — Arab complexion
- **cheeks:** soft rosy cheeks
- **expression_default:** light friendly smile, curious eyes
- **childlike features:** طبيعية تماماً — لا ملامح بالغ، لا ملامح رضيع
- **strict rule:** Do not change her face in any scene.

---

## hair
(مأخوذ حرفياً من الصورة المرجعية)

- **color:** dark brown
- **length:** long
- **style:** **single long side braid** (ضفيرة جانبية طويلة واحدة)
- **consistency:** نفس التسريحة في **كل** المشاهد — لا تتغير، لا تُفكّ، لا تُستبدل بتسريحتين
- **behavior with hood:** الضفيرة تظهر خارج القلنسوة من الأمام/الجانب حتى عندما تكون القلنسوة مرفوعة
- **strict rule:** Do not change her hairstyle in any scene.

---

## eyes
(مأخوذ حرفياً من الصورة المرجعية)

- **color:** warm brown
- **shape:** large, almond-shaped, expressive
- **expression:** curious, kind, alert
- **strict rule:** عيون كبيرة دافئة — لا عيون صغيرة، لا أنمي مبالغ، لا توهج

---

## clothes
(الملابس المعتمدة بناءً على الصورة المرجعية)

### 1. الرداء الأحمر بالقلنسوة
- **item:** red hooded cape
- **color:** warm crimson red
- **length:** reaches knees
- **hood:** قابلة للرفع أو الإنزال حسب المشهد
- **fabric_feel:** soft warm wool-like texture

### 2. الفستان الأبيض الطويل
- **item:** simple long white dress
- **style:** traditional, modest, long sleeves
- **length:** أسفل الركبتين (يظهر من تحت الرداء)
- **texture:** simple, soft, unadorned

### 3. الحذاء البني
- **item:** brown leather shoes
- **style:** simple, comfortable, ankle-high
- **color:** warm brown matching the reference

**strict rule:** Do not change her outfit in any scene.

---

## accessories
- **always:** red hooded cape (القطعة المميزة — دائماً)
- **when_relevant:** small **woven** basket (سلة خوص صغيرة — مشاهد 1, 2, 3, 6)
- **basket_style:** woven / wicker texture, brown/beige color, small handle
- **never:** no jewelry, no modern accessories, no hat (other than the hood), no bag

---

## body_type
- **build:** slim, age-appropriate child body
- **height:** small (child proportions — about 125cm equivalent)
- **proportions:** normal child proportions
- **hands:** small child hands, **5 fingers each, natural length** (مؤكد)
- **feet:** small child feet, natural shape

**strict rules:**
- Natural hands with five fingers each.
- Natural feet.
- No deformities.

---

## personality
(تظهر عبر التعابير والمواقف البصرية)
- **smart** — تفكر قبل التصرّف (تعابير انتباه)
- **kind-hearted** — تعابير ناعمة
- **curious** — عيون متسعة عند رؤية جديد
- **brave without recklessness** — منتبهة، ليست متجمّدة من الخوف
- **compassionate** — روح القصة الأساسية

---

## must_remain_consistent

**جدول إلزامي — كل خاصية يتم التحقق منها بصرياً في QC لكل مشهد بمقارنة مع الصورة المرجعية:**

| الخاصية | القيمة الثابتة (من المرجعية) |
|---|---|
| العمر | 8 years old |
| لون الشعر | dark brown |
| تسريحة الشعر | single long side braid |
| لون العينين | warm brown |
| حجم العينين | large, almond-shaped |
| لون البشرة | warm olive |
| شكل الوجه | round, soft, childlike |
| الرداء الأحمر | red hooded cape (crimson) |
| الفستان الداخلي | simple long white dress |
| الحذاء | brown leather shoes |
| السلة (عند الظهور) | small woven basket |
| الطول النسبي | child proportions |

---

## forbidden_identity_variations

❌ **لا يُسمح بأي من التالي في أي مشهد:**

- ❌ لا تتحول ليلى إلى رضيعة
- ❌ لا تتحول إلى مراهقة
- ❌ لا تتحول إلى ولد
- ❌ لا ملامح ذئبية عليها (no wolf-like features)
- ❌ لا أذن ذئب، لا ذيل، لا فرو على الجلد، لا أنف ذئبي
- ❌ لا تغيير في الملابس (لا جينز، لا تيشيرت، لا ملابس حديثة)
- ❌ لا إزالة دائمة للرداء الأحمر
- ❌ لا تغيير في لون الشعر
- ❌ لا تغيير في تسريحة الشعر (تبقى ضفيرة جانبية واحدة)
- ❌ لا تغيير في لون العينين
- ❌ لا تغيير في شكل الوجه
- ❌ لا ظهور نسختين من ليلى في صورة واحدة
- ❌ لا نظارات شمسية
- ❌ لا makeup
- ❌ لا أصابع زائدة أو ناقصة
- ❌ لا تشوّه في الأطراف

---

## negative_prompt
(يُحقن في كل image prompt — جاهز للنسخ)

```
no deformities, no extra fingers, no missing fingers, no six fingers, no four fingers,
no extra limbs, no distorted hands, no distorted feet, no malformed body,
no distorted face, no melted features, no facial asymmetry, no uncanny valley,
no text, no writing, no words, no letters, no numbers, no watermark, no logo, no signature, no caption,
no adult features, no teenager features, no pre-teen features, no baby features, no toddler features,
no modern clothing, no jeans, no t-shirt, no sneakers, no sunglasses, no modern hat,
no wolf-like features on Layla, no wolf ears on Layla, no wolf tail on Layla, no fur on Layla skin, no animal features on Layla,
no scary elements, no horror, no violence, no blood, no weapons, no scary teeth, no glowing eyes,
no blur on face, no cropped face, no duplicate character, no twin, no mirror reflection of character,
no adult makeup, no jewelry, no modern accessories,
no color change in hair, no color change in eyes, no color change in clothing,
no photo-realistic style, no 3D render looking plastic
```

---

## 🎯 Identity Lock Block (يُلصق في كل prompt)

```
Use the approved Layla reference image as the identity anchor.
Keep the exact same face, same warm brown eyes, same dark brown long side braid,
same red hooded cape, same white dress, same brown shoes,
and same small woven basket when she carries one.

Layla must look exactly 8 years old.
Do not change her age.
Do not change her face.
Do not change her outfit.
Do not change her hairstyle.
Natural hands with five fingers.
Natural feet.
No wolf-like features.
No text, no logo, no watermark.
```

---

## Usage Protocol

### في Midjourney v6+
1. استخدم الصورة المرجعية كـ character reference:
   ```
   --cref <URL of layla_reference.png> --cw 100
   ```
2. الصق Identity Lock Block أعلاه في كل prompt
3. أضف الـ negative prompt كاملاً

### في Imagen 3 / Ideogram
1. ارفع `layla_reference.png` كصورة مرجعية إن سمح المُولِّد
2. الصق Identity Lock Block في كل prompt
3. أضف الـ negative prompt كاملاً
4. قارن كل صورة منتجة مع المرجعية — ارفض أي اختلاف

---

## Quality Gate

**قبل قبول أي صورة مشهد، تحقق بصرياً من:**
1. ✅ نفس الوجه (شكل، ملامح، ابتسامة)
2. ✅ نفس العينين (لون، حجم)
3. ✅ نفس لون البشرة
4. ✅ نفس الشعر (لون، ضفيرة جانبية واحدة)
5. ✅ نفس الرداء الأحمر بالقلنسوة
6. ✅ نفس الفستان الأبيض
7. ✅ نفس الحذاء البني
8. ✅ نفس السلة (عند الظهور)
9. ✅ 5 أصابع في كل يد
10. ✅ قدمان طبيعيتان
11. ✅ لا نصوص أو watermark
12. ✅ العمر يبدو 8 سنوات

**إذا فشل أي بند → ارفض الصورة وأعد التوليد.**
