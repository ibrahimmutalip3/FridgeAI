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

For the Android adaptive icon specifically: Android draws two layers
(background + foreground) and masks them together. To keep the gradient
intact without doubling the logo, the background layer gets the full image
and the foreground layer is fully transparent.

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

# Adaptive icon canvas is larger than the legacy icon so the system has
# room to mask/animate it; Google's spec size per density bucket.
ADAPTIVE_SIZES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

ADAPTIVE_ICON_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""


def generate_android(src_rgba: Image.Image) -> None:
    for folder, size in LEGACY_SIZES.items():
        d = os.path.join(ANDROID_RES, folder)
        os.makedirs(d, exist_ok=True)
        src_rgba.resize((size, size), Image.LANCZOS).save(
            os.path.join(d, "ic_launcher.png")
        )

    for folder, size in ADAPTIVE_SIZES.items():
        d = os.path.join(ANDROID_RES, folder)
        os.makedirs(d, exist_ok=True)
        src_rgba.resize((size, size), Image.LANCZOS).save(
            os.path.join(d, "ic_launcher_background.png")
        )
        Image.new("RGBA", (size, size), (0, 0, 0, 0)).save(
            os.path.join(d, "ic_launcher_foreground.png")
        )

    anydpi = os.path.join(ANDROID_RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
        f.write(ADAPTIVE_ICON_XML)

    print(f"Android: wrote {len(LEGACY_SIZES)} legacy + {len(ADAPTIVE_SIZES)} adaptive icon sizes")


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
