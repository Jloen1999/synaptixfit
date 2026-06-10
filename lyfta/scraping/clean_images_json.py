"""
Clean exercise_images.json: removes profile pics, icons/logos,
converts Next.js proxy URLs to direct CDN URLs, deduplicates sizes.

Keeps only: exercise images (GymvisualPNG) + muscle group SVG icons.

Usage:
  python clean_images_json.py
  python clean_images_json.py exercise_images.json exercise_images_clean.json
"""

import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse, parse_qs

INPUT = Path(__file__).parent / "exercise_images.json"
OUTPUT = Path(__file__).parent / "exercise_images_clean.json"


def extract_raw_url(url: str) -> str | None:
    """Extract the raw CDN URL from a Next.js _next/image proxy or return as-is."""
    parsed = urlparse(url)
    if "/_next/image" in parsed.path:
        qs = parse_qs(parsed.query)
        raw = qs.get("url", [None])[0]
        return unquote(raw) if raw else None
    return url.split("?")[0]


def extract_exercise_name(cdn_url: str) -> str:
    """Extract human-readable exercise name from the CDN URL path."""
    parts = cdn_url.split("/")
    filename = parts[-1]
    filename = re.sub(r"^\d+-", "", filename)
    filename = filename.replace("_small.png", "").replace("_.mp4", "")
    filename = re.sub(r"-FIX\d*$", "", filename)
    filename = re.sub(r"-FLIPPED$", "", filename)
    name = filename.replace("-", " ").replace("_", " ")
    name = re.sub(r"\s+", " ", name).strip()
    return name


def extract_muscle_name(cdn_url: str) -> str:
    """Extract muscle name from SVG icon filename like ic_chip_back_b.svg."""
    parts = cdn_url.split("/")
    filename = parts[-1]
    filename = filename.replace(".svg", "")
    filename = filename.replace("ic_chip_", "").replace("chip_", "")
    filename = filename.replace("_b", "").replace("_", " ").title()
    return filename


def clean_base(url: str) -> str:
    """Remove size variant to get a unique exercise key (w=640 vs w=1200)."""
    return re.sub(r"_small\.png$", "", url)


def main():
    input_path = Path(sys.argv[1]) if len(sys.argv) > 1 else INPUT
    output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else OUTPUT

    decoder = json.JSONDecoder()
    data, _ = decoder.raw_decode(input_path.read_text("utf-8"))
    print(f"Read {len(data)} entries from {input_path}")

    exercises: list[dict] = []
    muscles: list[dict] = []
    seen_exercise: set[str] = set()
    seen_muscle: set[str] = set()
    removed = {"profile": 0, "other": 0, "duplicate": 0}

    for entry in data:
        url = entry["url"]
        category = entry.get("category", "")
        alt_text = entry.get("alt", "")

        # Remove profile pictures
        if "profilePic" in url:
            removed["profile"] += 1
            continue

        raw = extract_raw_url(url)
        if not raw:
            removed["other"] += 1
            continue

        # Muscle group SVG icons
        if "/icons/muscles/" in raw or re.search(r"chip_[\w]+\.svg$", raw):
            muscle_name = extract_muscle_name(raw)
            if raw not in seen_muscle:
                seen_muscle.add(raw)
                muscles.append({
                    "url": raw,
                    "muscle_name": muscle_name,
                    "type": "muscle_icon",
                })
            continue

        # Exercise images (GymvisualPNG)
        if "GymvisualPNG" not in raw:
            removed["other"] += 1
            continue

        # Deduplicate sizes — keep w=1200 (larger), remove w=640
        base = clean_base(raw)
        if base in seen_exercise:
            removed["duplicate"] += 1
            continue
        seen_exercise.add(base)

        exercise_name = extract_exercise_name(raw)

        exercises.append({
            "url": raw,
            "exercise_name": exercise_name,
            "category": category,
            "type": "exercise",
        })

    # Combine exercises + muscles
    result = exercises + muscles

    output_path.write_text(json.dumps(result, ensure_ascii=False, indent=2), "utf-8")

    print(f"Exercises:  {len(exercises)}")
    print(f"Muscle icons: {len(muscles)}")
    print(f"Total: {len(result)} -> {output_path}")
    print(f"Removed: {removed['profile']} profile pics, "
          f"{removed['duplicate']} duplicate sizes, "
          f"{removed['other']} other")


if __name__ == "__main__":
    main()
