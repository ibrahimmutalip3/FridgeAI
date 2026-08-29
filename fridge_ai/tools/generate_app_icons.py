#!/usr/bin/env python3
"""
Generates every Android + iOS launcher icon size directly from
assets/icons/app_icon.png and writes them straight into the
android/ and ios/ folders, committed as regular files.

Why this exists: flutter_launcher_icons (run automatically in CI) can also
generate these, but generating them ahead of time and committing them means
the icon in the repo is always exactly what you see when you open the repo,
independent of any CI step succeeding or a future config change.

This script intentionally does NOT crop/re-crop the logo out of the
background. app_icon.png already contains the logo AND the orange gradient
baked into a single flat image. Every generated size is just a resize of
that same full image - never a separately-cropped "foreground-only" logo
composited onto a flat/solid color. That's the actual fix for the "gradient
turned into a solid color" bug this script was written to prevent from
recurring.

Android gets a single flat ic_launcher.png per density bucket - no adaptive
icon (no background/foreground layers, no mipmap-anydpi-v26/ic_launcher.xml).
A single flat icon is simpler, has no risk of the background/foreground
layers doubling or misaligning the logo, and is still displayed correctly
(masked to the device's icon shape) on every Android version.

Usage:
    python3 tools/generate_app_icons.py
Requires: pip install Pillow
"""
import json
import os
from PIL import Image

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(REPO_ROOT, "assets", "icons", "app_icon.png")

ANDROID_RES = os.path.join(REPO_ROOT, "android", "app", "src", "main", "res")
IOS_ICONSET = os.path.join(
    REPO_ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
)

LEGACY_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def generate_android(src_rgba: Image.Image) -> None:
    # Remove any leftover adaptive-icon files from a previous run so the
    # repo never ends up with both the single flat icon AND stale
    # background/foreground layers sitting side by side.
    anydpi = os.path.join(ANDROID_RES, "mipmap-anydpi-v26")
    stale_xml = os.path.join(anydpi, "ic_launcher.xml")
    if os.path.exists(stale_xml):
        os.remove(stale_xml)
    if os.path.isdir(anydpi) and not os.listdir(anydpi):
        os.rmdir(anydpi)

    for folder, size in LEGACY_SIZES.items():
        d = os.path.join(ANDROID_RES, folder)
        os.makedirs(d, exist_ok=True)
        for stale in ("ic_launcher_background.png", "ic_launcher_foreground.png"):
            stale_path = os.path.join(d, stale)
            if os.path.exists(stale_path):
                os.remove(stale_path)
        src_rgba.resize((size, size), Image.LANCZOS).save(
            os.path.join(d, "ic_launcher.png")
        )

    print(f"Android: wrote {len(LEGACY_SIZES)} single-layer icon sizes")


def generate_ios(src_rgb: Image.Image) -> None:
    with open(os.path.join(IOS_ICONSET, "Contents.json")) as f:
        manifest = json.load(f)

    seen = set()
    for entry in manifest["images"]:
        base = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].replace("x", ""))
        px = round(base * scale)
        filename = entry["filename"]
        if filename in seen:
            continue
        seen.add(filename)
        src_rgb.resize((px, px), Image.LANCZOS).save(
            os.path.join(IOS_ICONSET, filename)
        )

    print(f"iOS: wrote {len(seen)} icon sizes into AppIcon.appiconset")


def main() -> None:
    if not os.path.exists(SRC):
        raise SystemExit(f"Source icon not found: {SRC}")

    src_rgba = Image.open(SRC).convert("RGBA")
    src_rgb = Image.open(SRC).convert("RGB")  # iOS icons must have no alpha

    generate_android(src_rgba)
    generate_ios(src_rgb)
    print("Done. Review the changed files, then commit them.")


if __name__ == "__main__":
    main()
