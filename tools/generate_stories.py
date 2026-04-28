#!/usr/bin/env python3
# ============================================================
# Hikayati - AI Story Production Pipeline
# ============================================================
# Generates images (Pollinations) + audio (ElevenLabs) for all 4 stories.
# Saves to: content_studio/public_library/packs/<slug>/{images,audio}/
# After running: tools\publish_pack.ps1 -Slug <slug> for each story.
#
# Usage:
#   python tools/generate_stories.py                       # all 4 stories
#   python tools/generate_stories.py --slug juha_market    # one story
#   python tools/generate_stories.py --skip-images         # audio only
#   python tools/generate_stories.py --skip-audio          # images only
#   python tools/generate_stories.py --force               # regenerate all
# ============================================================

import os
import sys
import time
import argparse
import urllib.parse
from pathlib import Path

# Force UTF-8 output on Windows console
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

try:
    import requests
    import yaml
    from dotenv import load_dotenv
except ImportError:
    print("Missing dependencies. Install with:")
    print("  pip install requests pyyaml python-dotenv")
    sys.exit(1)

# ============================================================
# Configuration
# ============================================================

PROJECT_ROOT = Path(__file__).parent.parent.absolute()
PACKS_DIR = PROJECT_ROOT / "content_studio" / "public_library" / "packs"

load_dotenv(PROJECT_ROOT / ".env")

POLLINATIONS_IMAGE_KEY = os.getenv("POLLINATIONS_IMAGE_API_KEY")
ELEVENLABS_KEY = os.getenv("ELEVENLABS_API_KEY")

# ElevenLabs voice ID. "Lily" works well for warm Arabic narration.
ELEVENLABS_VOICE_ID = "pFZP5JQG7iQjIQuC4Bku"
ELEVENLABS_MODEL = "eleven_multilingual_v2"

# Pollinations image model
# Options: nanobanana-pro (best, expensive), nanobanana (good balance),
#          gptimage-large, flux, zimage, seedream5
IMAGE_MODEL = "nanobanana"

IMAGE_WIDTH = 1024
IMAGE_HEIGHT = 1024

# ============================================================
# Image Prompts (per story per scene)
# ============================================================

STYLE_SUFFIX = (
    "digital painting, children's book illustration, "
    "warm color palette, soft cinematic shadows, beautiful composition, "
    "high quality, detailed, no modern elements, no Western faces"
)

RELIGIOUS_STYLE = (
    "reverent religious art, sacred atmosphere, divine golden light from heaven, "
    "Islamic art aesthetics, beautiful calligraphic feel, "
    "digital painting, children's religious book illustration, "
    "high quality, no modern elements"
)

UNIVERSAL_NEGATIVE = (
    "no scary monsters, no blood, no violence, no horror, "
    "no exposed sharp teeth, no gore, no realistic photography, "
    "no Western faces, no modern elements, child-friendly only"
)

PROPHET_NEGATIVE = (
    "NO HUMAN FACE on prophet, NO facial features visible on prophet, "
    "NO eyes mouth nose on prophet figure, only luminous silhouette, "
    "no idols worshipped, no creatures of jinn"
)

# ---- Story 1: Juha and the Donkey (8 scenes) ----
JUHA_BASE = (
    "Traditional Arab village morning scene, warm golden sunlight, "
    "Juha character: bearded elderly Arab man with kind smile, white turban, beige tunic, "
    "his son: ~8 year old Arab boy with black hair, blue tunic, "
    "small grey donkey with woven baskets, "
    "mud-brick houses, palm trees in background, "
)

JUHA_PROMPTS = {
    1: JUHA_BASE + "Juha and his son loading baskets of dates and bread on the donkey's back at dawn, peaceful village morning, sunrise glow, " + STYLE_SUFFIX,
    2: JUHA_BASE + "Juha and his son both riding the small donkey together on a dusty road, an old Arab man sitting under a tree shaking his head, dust on the path, " + STYLE_SUFFIX,
    3: JUHA_BASE + "Juha riding the donkey alone, his small son walking beside the donkey looking tired, group of Arab village children pointing and shouting, " + STYLE_SUFFIX,
    4: JUHA_BASE + "The young son riding the donkey, Juha walking beside, an old wise sheikh with white beard hitting the ground with his stick angrily, " + STYLE_SUFFIX,
    5: JUHA_BASE + "Juha and his son both walking on the road, the donkey walking behind them empty, a farmer in the field laughing loudly while plowing, " + STYLE_SUFFIX,
    6: JUHA_BASE + "Juha and his son comically carrying the small donkey on their shoulders, villagers around laughing hysterically, absurd funny scene, " + STYLE_SUFFIX,
    7: JUHA_BASE + "Juha and his confused son sitting on a rock resting, the donkey lying down catching its breath, son looking puzzled at his wise father, " + STYLE_SUFFIX,
    8: JUHA_BASE + "Juha gently patting his son's shoulder under a palm tree, sunset golden light, the son smiling with understanding, donkey grazing peacefully, wisdom moment, " + STYLE_SUFFIX,
}

# ---- Story 2: Antar and the Night Wolves (9 scenes) ----
ANTAR_BASE = (
    "Cinematic Arabian desert at night, full bright moon, starry sky, "
    "Antar: ~12 year old brave Arab boy with WHEATISH brown skin tone, "
    "short curly black hair, sharp brave eyes, brown bedouin tunic, "
    "small leather belt, a young hero, NOT a giant, just a brave child, "
    "bedouin camp with white-beige tents, sand dunes, "
)

ANTAR_PROMPTS = {
    1: ANTAR_BASE + "Sunset transitioning to evening, Antar returning from herding camels, sitting beside his elderly grandfather near a warm campfire, peaceful family moment, orange and blue light, " + STYLE_SUFFIX,
    2: ANTAR_BASE + "Night, distant howling of wolves carrying through the dunes, families looking worried around the dying campfire, tension in the air, " + STYLE_SUFFIX,
    3: ANTAR_BASE + "Wolves howling closer, camels gathered shaking in fear, mothers hugging children inside tents, men holding sticks with trembling hands, fear visible, " + STYLE_SUFFIX,
    4: ANTAR_BASE + "Inside a tent, a small ~4 year old child crying scared in his mother's arms, Antar looking at the trembling child with growing resolve in his eyes, " + STYLE_SUFFIX,
    5: ANTAR_BASE + "Antar grabbing a long bamboo staff and a flaming torch from the campfire, his elderly grandfather reaching out concerned, Antar's face determined and resolute, " + STYLE_SUFFIX,
    6: ANTAR_BASE + "Antar walking alone away from camp toward the dunes, holding torch high, FIVE noble grey wolves with glowing golden eyes in the dark distance, peaceful moonlight, " + STYLE_SUFFIX,
    7: "EPIC HEROIC SCENE, " + ANTAR_BASE + "Antar from BEHIND, raising his blazing torch HIGH against the full moon, his long shadow stretching across the sand, the noble wolves retreating into the night, dramatic cinematic lighting, inspiring poster-worthy composition, " + STYLE_SUFFIX,
    8: ANTAR_BASE + "Antar walking back triumphantly to camp at dawn, sweat on his forehead, bamboo staff over shoulder, the small child running to hug him, men silently clapping, mothers smiling, " + STYLE_SUFFIX,
    9: ANTAR_BASE + "Sunrise scene, Antar sitting beside his wise elderly grandfather at the campfire, the grandfather gently placing his hand on Antar's shoulder, peaceful sunrise behind them, wisdom transferred, " + STYLE_SUFFIX,
}

# ---- Story 3: Prophet Sulayman and the Ant (10 scenes) ----
# CRITICAL: NO FACE on prophet
SULAYMAN_BASE = (
    "Reverent Quranic story illustration, ancient lush green valley, "
    "Prophet Sulayman represented as a GLOWING GOLDEN DIVINE LIGHT FIGURE "
    "(NO FACE VISIBLE, only luminous silhouette with white and gold royal robes), "
    "divine halo around the figure, "
    "majestic procession with white and gold banners, "
    "hoopoe bird flying ahead, golden sunlight from heaven, "
)

SULAYMAN_PROMPTS = {
    1: SULAYMAN_BASE + "Vast majestic procession moving through a green valley, banners flying, hoopoe bird in front, prophet figure shown only as glowing golden light, divine atmosphere, " + RELIGIOUS_STYLE,
    2: "Ancient lush green valley with colorful flowers, small streams between stones, butterflies fluttering above grass, hidden ant colony in the corner, golden sunrise, peaceful sacred atmosphere, " + RELIGIOUS_STYLE,
    3: "Tiny cute cartoon-style ant standing on a small stone, looking up wide-eyed at distant dust cloud and approaching banners, valley setting, golden divine light approaching, " + RELIGIOUS_STYLE,
    4: "Many tiny cute cartoon ants rushing into their underground homes, one wise ant on a stone giving warning, scene of organized retreat, lush valley grass, " + RELIGIOUS_STYLE,
    5: SULAYMAN_BASE + "The procession suddenly stops, banners freeze, prophet figure (still as glowing golden light, NO FACE) turns toward the valley, hoopoe bird looking down, divine moment of pause, " + RELIGIOUS_STYLE,
    6: SULAYMAN_BASE + "Prophet figure (as glowing golden light, NO FACE) seemingly smiling toward the valley, very gentle smile sense conveyed only through light intensity and posture, no facial features, divine wonder, " + RELIGIOUS_STYLE,
    7: SULAYMAN_BASE + "Prophet figure (as glowing golden light, NO FACE) raising face toward heaven in prayer, hands raised, divine light beams from sky, sacred du'a moment, " + RELIGIOUS_STYLE,
    8: SULAYMAN_BASE + "The vast procession passing GENTLY around the edges of the ant valley, soldiers walking carefully, banners waving, ants safe in their homes, peaceful respect, " + RELIGIOUS_STYLE,
    9: "Inside the ant kingdom underground, tiny cartoon ants gathered around their queen ant on a small throne, the wise ant being celebrated, warm earthy atmosphere, joyful scene, " + RELIGIOUS_STYLE,
    10: "Beautiful sunset over the now-empty green valley, golden light from heaven, peaceful flowers, distant silhouette of the procession leaving, sense of divine wisdom and lesson, " + RELIGIOUS_STYLE,
}

# ---- Story 4: Prophet Yunus and the Whale (12 scenes) ----
# CRITICAL: NO FACE on prophet
YUNUS_BASE_WALK = (
    "Prophet Yunus represented as a SILHOUETTE FROM BEHIND, "
    "wearing simple white-green prophet robe, head covering, "
    "NO FACE VISIBLE EVER, soft divine light around figure, "
    "reverent atmosphere, "
)

YUNUS_BASE_PRAY = (
    "Prophet Yunus from BEHIND with hands raised in prayer, "
    "NO FACE VISIBLE, only silhouette and raised arms, "
    "soft divine golden light, reverent supplication, "
)

YUNUS_PROMPTS = {
    1: YUNUS_BASE_WALK + "Standing in an ancient stone city, calling people to faith, townspeople in old robes turning away, golden sunset, ancient buildings, " + RELIGIOUS_STYLE,
    2: YUNUS_BASE_WALK + "Walking alone OUT of the city gate, head bowed, sunset behind him, road leading away, silhouette only, no face shown, heavy heart visible in posture, " + RELIGIOUS_STYLE,
    3: YUNUS_BASE_WALK + "At an ancient seaside port, old wooden ship with large sail, sailors loading, sunset over calm sea, prophet boarding silhouette, " + RELIGIOUS_STYLE,
    4: "Massive storm at sea, dark thunderclouds, lightning, towering waves, ancient wooden ship tilting dangerously, sailors panicking, dramatic stormy atmosphere, " + RELIGIOUS_STYLE,
    5: YUNUS_BASE_WALK + "Standing at the edge of the storm-tossed ship, looking down at the raging sea, silhouette against lightning, dramatic moment, NO FACE, " + RELIGIOUS_STYLE,
    6: "MAJESTIC NOBLE blue-green sperm whale, calm intelligent eyes (NOT scary), gentle giant of the deep sea, opening mouth gently in deep ocean, divine miracle moment, " + RELIGIOUS_STYLE,
    7: YUNUS_BASE_PRAY + "INSIDE the whale belly, three layers of darkness, tiny silhouette of prophet praying with raised hands, soft golden light glowing from his prayer in the darkness, mystical reverent, " + RELIGIOUS_STYLE,
    8: YUNUS_BASE_PRAY + "Inside the whale belly, prophet silhouette praying, golden divine light bursting from his prayer, hope shattering darkness, breakthrough moment, " + RELIGIOUS_STYLE,
    9: YUNUS_BASE_WALK + "Lying weak on a sandy beach at dawn, the great whale receding into the sea behind him, blue sky above, prophet's hand reaching out to sand, silhouette only NO FACE, " + RELIGIOUS_STYLE,
    10: YUNUS_BASE_WALK + "A miraculous large yaqteen (gourd) tree growing right beside the prophet, broad green leaves giving wide shade, large yellow gourds hanging, divine gift atmosphere, peaceful beach setting, " + RELIGIOUS_STYLE,
    11: YUNUS_BASE_WALK + "Resting peacefully under the lush yaqteen tree shade on the beach, recovering, silhouette NO FACE, sunset golden light, gentle breeze through leaves, " + RELIGIOUS_STYLE,
    12: "Ancient stone city celebrating, all people raising hands in prayer to heaven together, dark storm clouds parting and revealing golden divine light, collective faith and salvation, joyful relief, " + RELIGIOUS_STYLE,
}

ALL_PROMPTS = {
    "juha_market": JUHA_PROMPTS,
    "antar_courage": ANTAR_PROMPTS,
    "sulayman_ant": SULAYMAN_PROMPTS,
    "yunus_whale": YUNUS_PROMPTS,
}

SEEDS = {
    "juha_market": 7001,
    "antar_courage": 7002,
    "sulayman_ant": 7003,
    "yunus_whale": 7004,
}

NEGATIVES = {
    "juha_market": UNIVERSAL_NEGATIVE,
    "antar_courage": UNIVERSAL_NEGATIVE,
    "sulayman_ant": UNIVERSAL_NEGATIVE + " " + PROPHET_NEGATIVE,
    "yunus_whale": UNIVERSAL_NEGATIVE + " " + PROPHET_NEGATIVE,
}

# ============================================================
# Image generation (Pollinations)
# ============================================================

def generate_image(prompt, output_path, seed, negative="", retries=2, force=False):
    if output_path.exists() and not force:
        print("  [SKIP] " + output_path.name + " (exists)")
        return True

    encoded = urllib.parse.quote(prompt[:1500])
    url = "https://gen.pollinations.ai/image/" + encoded
    params = {
        "model": IMAGE_MODEL,
        "width": IMAGE_WIDTH,
        "height": IMAGE_HEIGHT,
        "seed": seed,
        "nologo": "true",
        "private": "true",
    }
    if negative:
        params["negative_prompt"] = negative[:500]

    headers = {"Authorization": "Bearer " + (POLLINATIONS_IMAGE_KEY or "")}

    for attempt in range(retries + 1):
        try:
            print("  [IMG]  " + output_path.name + " (attempt " + str(attempt + 1) + ")...", flush=True)
            r = requests.get(url, params=params, headers=headers, timeout=180)
            if r.status_code == 200 and len(r.content) > 1000:
                output_path.write_bytes(r.content)
                kb = len(r.content) // 1024
                print("         OK saved (" + str(kb) + " KB)")
                return True
            else:
                print("         WARN HTTP " + str(r.status_code) + ", size=" + str(len(r.content)))
                if r.status_code == 402:
                    print("         ERR INSUFFICIENT BALANCE - top up at enter.pollinations.ai")
                    return False
                if attempt < retries:
                    time.sleep(5)
        except Exception as e:
            print("         WARN error: " + str(e))
            if attempt < retries:
                time.sleep(5)
    return False

# ============================================================
# Audio generation (ElevenLabs)
# ============================================================

def generate_audio(text, output_path, retries=2, force=False):
    if output_path.exists() and not force:
        print("  [SKIP] " + output_path.name + " (exists)")
        return True

    url = "https://api.elevenlabs.io/v1/text-to-speech/" + ELEVENLABS_VOICE_ID
    headers = {
        "xi-api-key": ELEVENLABS_KEY or "",
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
    }
    payload = {
        "text": text,
        "model_id": ELEVENLABS_MODEL,
        "voice_settings": {
            "stability": 0.65,
            "similarity_boost": 0.75,
            "style": 0.45,
            "use_speaker_boost": True,
        },
    }

    for attempt in range(retries + 1):
        try:
            print("  [AUD]  " + output_path.name + " (attempt " + str(attempt + 1) + ")...", flush=True)
            r = requests.post(url, json=payload, headers=headers, timeout=180)
            if r.status_code == 200 and len(r.content) > 1000:
                output_path.write_bytes(r.content)
                kb = len(r.content) // 1024
                print("         OK saved (" + str(kb) + " KB)")
                return True
            else:
                print("         WARN HTTP " + str(r.status_code) + ": " + r.text[:200])
                if attempt < retries:
                    time.sleep(5)
        except Exception as e:
            print("         WARN error: " + str(e))
            if attempt < retries:
                time.sleep(5)
    return False

# ============================================================
# Story processing
# ============================================================

def process_story(slug, skip_images=False, skip_audio=False, force=False):
    pack_dir = PACKS_DIR / slug
    yaml_path = pack_dir / "story_pack.yaml"
    images_dir = pack_dir / "images"
    audio_dir = pack_dir / "audio"

    if not yaml_path.exists():
        print("ERR YAML not found: " + str(yaml_path))
        return False

    images_dir.mkdir(parents=True, exist_ok=True)
    audio_dir.mkdir(parents=True, exist_ok=True)

    print("")
    print("=" * 60)
    print("Processing: " + slug)
    print("=" * 60)

    with open(yaml_path, "r", encoding="utf-8") as f:
        pack = yaml.safe_load(f)

    title = pack.get("title", slug)
    scenes = pack.get("scenes", [])
    seed = SEEDS.get(slug, 1000)
    negative = NEGATIVES.get(slug, UNIVERSAL_NEGATIVE)
    prompts = ALL_PROMPTS.get(slug, {})

    print("  Title: " + str(title))
    print("  Scenes: " + str(len(scenes)))
    print("  Seed: " + str(seed))
    print("  Image model: " + IMAGE_MODEL)

    success = 0
    fail = 0

    for scene in scenes:
        scene_num = scene["scene"]
        text = scene["text"]
        image_filename = scene["image"]
        audio_filename = scene["audio"]

        print("")
        print("  Scene " + str(scene_num) + "/" + str(len(scenes)))

        if not skip_images:
            prompt = prompts.get(scene_num)
            if not prompt:
                print("  WARN no image prompt defined for scene " + str(scene_num))
                fail += 1
            else:
                img_path = images_dir / image_filename
                if generate_image(prompt, img_path, seed + scene_num, negative, force=force):
                    success += 1
                else:
                    fail += 1
                time.sleep(2)

        if not skip_audio:
            audio_path = audio_dir / audio_filename
            if generate_audio(text, audio_path, force=force):
                success += 1
            else:
                fail += 1
            time.sleep(1)

    print("")
    print("  Result: " + str(success) + " ok, " + str(fail) + " failed")
    return fail == 0

# ============================================================
# Main
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="Hikayati AI Story Production Pipeline")
    parser.add_argument("--slug", type=str, default=None, help="Process only this story (default: all)")
    parser.add_argument("--skip-images", action="store_true", help="Skip image generation")
    parser.add_argument("--skip-audio", action="store_true", help="Skip audio generation")
    parser.add_argument("--force", action="store_true", help="Regenerate even if files exist")
    parser.add_argument("--model", type=str, default=None, help="Override image model (e.g., nanobanana-pro)")
    args = parser.parse_args()

    if args.model:
        global IMAGE_MODEL
        IMAGE_MODEL = args.model

    if not POLLINATIONS_IMAGE_KEY:
        print("ERR POLLINATIONS_IMAGE_API_KEY not set in .env")
        sys.exit(1)
    if not ELEVENLABS_KEY:
        print("ERR ELEVENLABS_API_KEY not set in .env")
        sys.exit(1)

    print("=" * 60)
    print("  Hikayati AI Story Production Pipeline")
    print("=" * 60)
    print("  Project root:    " + str(PROJECT_ROOT))
    print("  Image model:     " + IMAGE_MODEL)
    print("  Voice ID:        " + ELEVENLABS_VOICE_ID)
    print("  Voice model:     " + ELEVENLABS_MODEL)
    print("  Force regen:     " + str(args.force))

    stories = ["juha_market", "antar_courage", "sulayman_ant", "yunus_whale"]
    if args.slug:
        if args.slug not in stories:
            print("ERR unknown slug: " + args.slug)
            print("    Available: " + ", ".join(stories))
            sys.exit(1)
        stories = [args.slug]

    print("  Stories queued:  " + str(len(stories)))
    print("")

    start = time.time()
    results = {}

    for slug in stories:
        try:
            results[slug] = process_story(
                slug,
                skip_images=args.skip_images,
                skip_audio=args.skip_audio,
                force=args.force,
            )
        except KeyboardInterrupt:
            print("")
            print("Interrupted by user")
            break
        except Exception as e:
            print("ERR processing " + slug + ": " + str(e))
            results[slug] = False

    elapsed = time.time() - start

    print("")
    print("=" * 60)
    print("  Production Summary")
    print("=" * 60)
    for slug, ok in results.items():
        label = "[OK]     " if ok else "[PARTIAL]"
        print("  " + label + "  " + slug)
    mins = elapsed / 60.0
    print("")
    print("  Elapsed: " + ("%.1f" % mins) + " minutes")
    print("")
    print("  Next step - publish each story to assets/:")
    for slug in stories:
        print("    .\\tools\\publish_pack.ps1 -Slug " + slug)


if __name__ == "__main__":
    main()
