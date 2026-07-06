#!/usr/bin/env python3
"""Генерация арт-ассетов через Nano Banana (Gemini image API) в стиле Roblox × «99 Nights in the Forest».

Ключ: ~/.keys/nano_banana.key (ВНЕ репозитория — не коммитить!)
Запуск: python3 tools/gen_assets_nb.py [имя_ассета ...]   # без аргументов — весь манифест
Выход:  art/gen/<имя>.png

Требование: у Google-проекта ключа должен быть включён биллинг —
у бесплатного тира Gemini API квота имидж-моделей = 0 (проверено 2026-07-06).
"""
import base64
import json
import sys
import time
import urllib.request
from pathlib import Path

KEY_PATH = Path.home() / ".keys" / "nano_banana.key"
OUT_DIR = Path(__file__).resolve().parent.parent / "art" / "gen"
# порядок попыток: nano banana → новее (вдруг у тира другой доступ)
MODELS = ["gemini-2.5-flash-image", "gemini-3.1-flash-image", "gemini-3-pro-image"]

STYLE = (
    "Chunky low-poly Roblox blocky style like the game '99 Nights in the Forest', "
    "flat vibrant colors, soft warm lighting, kid-friendly spooky-cozy mood, no text, no watermark"
)

# имя → (aspect_ratio, промпт)
MANIFEST = {
    "title_bg": ("16:9",
        f"{STYLE}. Wide key art for a game title screen: dense blocky pine forest at dusk, "
        "cozy log cabin with glowing warm windows in the middle distance, big pale moon, light fog, "
        "fireflies, red gable roof, dirt path leading to the cabin, dramatic but friendly"),
    "icon": ("1:1",
        f"{STYLE}. Mobile game app icon composition, extreme close-up: cute-scary blocky bear-like "
        "mascot face peeking out of dark forest between blocky trees, glowing eyes, big moon behind, "
        "high contrast, bold silhouette, centered"),
    "lose_bg": ("16:9",
        f"{STYLE}. Night blocky forest clearing lit by a huge full moon, long shadows, "
        "abandoned campfire with fading embers, empty and quiet, melancholic but not gory"),
    "note_paper": ("1:1",
        "Aged paper texture for an in-game note, slightly crumpled, warm beige, "
        "child crayon doodles in corners (tiny house, tree, moon), no text, flat scan look"),
}


def gen(name: str, aspect: str, prompt: str, key: str) -> bool:
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
            "imageConfig": {"aspectRatio": aspect},
        },
    }
    for model in MODELS:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
        req = urllib.request.Request(
            url, data=json.dumps(body).encode(),
            headers={"Content-Type": "application/json", "x-goog-api-key": key})
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                d = json.load(r)
        except urllib.error.HTTPError as e:
            err = json.loads(e.read() or b"{}").get("error", {})
            msg = err.get("message", "")[:160]
            print(f"  {model}: HTTP {e.code} — {msg}")
            if e.code == 429 and "free_tier" in msg:
                continue  # пробуем следующую модель
            if e.code in (429, 500, 503):
                time.sleep(8)
                continue
            continue
        for part in d.get("candidates", [{}])[0].get("content", {}).get("parts", []):
            blob = part.get("inlineData") or part.get("inline_data")
            if blob:
                OUT_DIR.mkdir(parents=True, exist_ok=True)
                out = OUT_DIR / f"{name}.png"
                out.write_bytes(base64.b64decode(blob["data"]))
                print(f"  ✓ {out} ({model})")
                return True
        print(f"  {model}: ответ без картинки")
    return False


def main() -> None:
    if not KEY_PATH.exists():
        sys.exit(f"нет ключа: {KEY_PATH}")
    key = KEY_PATH.read_text().strip()
    names = sys.argv[1:] or list(MANIFEST)
    ok = 0
    for n in names:
        if n not in MANIFEST:
            print(f"? неизвестный ассет {n} (есть: {', '.join(MANIFEST)})")
            continue
        aspect, prompt = MANIFEST[n]
        print(f"[{n}] {aspect}")
        ok += gen(n, aspect, prompt, key)
        time.sleep(2)
    print(f"готово: {ok}/{len(names)}")


if __name__ == "__main__":
    main()
