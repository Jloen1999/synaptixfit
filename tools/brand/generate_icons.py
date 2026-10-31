"""Genera los iconos de la app a partir del logo (frontend/assets/images/logo.png).

Uso (desde la raíz del repositorio):
    py tools/brand/generate_icons.py

Crea:
- Android: mipmap-*/launcher_icon.png e ic_launcher.png (el logo ya es circular).
- Web: favicon.png, icons/Icon-192/512 y las versiones «maskable» (el logo al 80 % sobre
  blanco, dentro de la zona segura que recortan los lanzadores).
- Windows: runner/resources/app_icon.ico con varios tamaños.

Si cambia el logo, basta con volver a ejecutarlo.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRONTEND = ROOT / "frontend"
LOGO = FRONTEND / "assets/images/logo.png"

ANDROID_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
WINDOWS_SIZES = [16, 24, 32, 48, 64, 128, 256]
# Zona segura de un icono «maskable»: el contenido importante dentro del 80 % central.
MASKABLE_SCALE = 0.8


def resized(logo: Image.Image, size: int) -> Image.Image:
    return logo.resize((size, size), Image.Resampling.LANCZOS)


def maskable(logo: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    inner = int(size * MASKABLE_SCALE)
    offset = (size - inner) // 2
    canvas.alpha_composite(resized(logo, inner), (offset, offset))
    return canvas


def main() -> None:
    logo = Image.open(LOGO).convert("RGBA")

    res = FRONTEND / "android/app/src/main/res"
    for density, size in ANDROID_SIZES.items():
        icon = resized(logo, size)
        for name in ("launcher_icon.png", "ic_launcher.png"):
            icon.save(res / f"mipmap-{density}" / name)

    web = FRONTEND / "web"
    resized(logo, 32).save(web / "favicon.png")
    resized(logo, 192).save(web / "icons/Icon-192.png")
    resized(logo, 512).save(web / "icons/Icon-512.png")
    maskable(logo, 192).save(web / "icons/Icon-maskable-192.png")
    maskable(logo, 512).save(web / "icons/Icon-maskable-512.png")

    largest = resized(logo, max(WINDOWS_SIZES))
    largest.save(FRONTEND / "windows/runner/resources/app_icon.ico",
                 sizes=[(s, s) for s in WINDOWS_SIZES])
    print("Iconos generados desde", LOGO.relative_to(ROOT))


if __name__ == "__main__":
    main()
