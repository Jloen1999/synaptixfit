"""
Generate exercise_videos.json from exercise_images.json.

Image pattern:
  https://apilyfta.com/static/GymvisualPNG/00251101-Barbell-Bench-Press_Chest-FIX2_small.png
Video pattern:
  https://apilyfta.com/static/GymvisualMP4/00251201-Barbell-Bench-Press_Chest-FIX2_.mp4

Transformations:
  GymvisualPNG → GymvisualMP4
  ID last 3 digits: 101 → 201
  _small.png → _.mp4

Usage:
  python build_video_json.py
  python build_video_json.py exercise_images.json exercise_videos.json
"""

import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse, parse_qs

INPUT = Path(__file__).parent / "exercise_images.json"
OUTPUT = Path(__file__).parent / "exercise_videos.json"


def extract_raw_url(entry: dict) -> str | None:
    """Extract the raw CDN URL from an image entry (handling _next/image proxy)."""
    url = entry.get("url", "")
    parsed = urlparse(url)

    # Check if it's a Next.js image proxy
    if "/_next/image" in parsed.path:
        qs = parse_qs(parsed.query)
        raw = qs.get("url", [None])[0]
        if raw:
            return unquote(raw)
        return None

    # Direct CDN URL
    return url


def transform_image_to_video(cdn_url: str) -> str | None:
    """Convert a GymvisualPNG image URL to a GymvisualMP4 video URL."""
    if "GymvisualPNG" not in cdn_url:
        return None

    # 1) GymvisualPNG → GymvisualMP4
    result = cdn_url.replace("GymvisualPNG", "GymvisualMP4")

    # 2) ID transformation: the file starts with a numeric ID like 00251101
    #    Change last 3 digits from 101 → 201
    #    Pattern: /NNNNNN101-*_small.png → /NNNNNN201-*_.mp4
    m = re.search(r"/(\d+)-", result)
    if not m:
        return None
    old_id = m.group(1)
    if not old_id.endswith("101"):
        return None
    new_id = old_id[:-3] + "201"
    result = result.replace(f"/{old_id}-", f"/{new_id}-")

    # 3) Remove _small.png suffix and replace with _.mp4
    result = result.replace("_small.png", "_.mp4")

    # 4) Strip any query params after .mp4
    result = result.split("?")[0]

    return result


def extract_exercise_name(cdn_url: str) -> str:
    """Extract human-readable exercise name from the CDN URL path."""
    # URL like: .../GymvisualPNG/00251101-Barbell-Bench-Press_Chest-FIX2_small.png
    # Extract: Barbell-Bench-Press_Chest-FIX2 → Barbell Bench Press (Chest)
    parts = cdn_url.split("/")
    filename = parts[-1]  # 00251101-Barbell-Bench-Press_Chest-FIX2_small.png

    # Remove ID prefix
    filename = re.sub(r"^\d+-", "", filename)

    # Remove _small.png or _.mp4 suffix
    filename = filename.replace("_small.png", "").replace("_.mp4", "")

    # Remove variant suffixes like -FIX, -FIX2, -FLIPPED
    filename = re.sub(r"-FIX\d*$", "", filename)
    filename = re.sub(r"-FLIPPED$", "", filename)

    # Replace dashes and underscores with spaces
    name = filename.replace("-", " ").replace("_", " ")

    # Clean up extra spaces
    name = re.sub(r"\s+", " ", name).strip()

    return name


def main():
    input_path = Path(sys.argv[1]) if len(sys.argv) > 1 else INPUT
    output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else OUTPUT

    if not input_path.exists():
        print(f"ERROR: {input_path} not found.")
        sys.exit(1)

    raw_text = input_path.read_text("utf-8")
    # Handle files with trailing garbage after the JSON array
    decoder = json.JSONDecoder()
    data, end = decoder.raw_decode(raw_text)
    if isinstance(data, list):
        print(f"Read {len(data)} entries from {input_path}")
    else:
        data = data if isinstance(data, list) else []
        print(f"WARNING: root is not an array, got {len(data)} entries")

    videos: list[dict] = []
    seen_urls: set[str] = set()
    skipped = 0

    for entry in data:
        raw = extract_raw_url(entry)
        if not raw:
            continue

        video_url = transform_image_to_video(raw)
        if not video_url:
            skipped += 1
            continue

        # Deduplicate — same video can appear from multiple image variants
        if video_url in seen_urls:
            continue
        seen_urls.add(video_url)

        exercise_name = extract_exercise_name(raw)
        category = entry.get("category", "")

        videos.append({
            "url": video_url,
            "exercise_name": exercise_name,
            "category": category,
        })

    output_path.write_text(json.dumps(videos, ensure_ascii=False, indent=2), "utf-8")
    print(f"Generated {len(videos)} video entries -> {output_path}")
    print(f"Skipped {skipped} non-GymvisualPNG entries")
    print(f"Duplicates merged: {len(data) - skipped - len(videos)}")


if __name__ == "__main__":
    main()
