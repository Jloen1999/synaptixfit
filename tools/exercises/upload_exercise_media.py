"""Sube a R2 (bucket `synaptixfit`) las fotos y vídeos elegidos por exercise_images.py (ADR 0056).

- Fotos: a WebP de 720 px como mucho, calidad 80 y fondo blanco (muchos dibujos tienen fondo transparente, que en el
  tema oscuro no se vería). Pasaron de unos 15 MB a menos de 1 MB por cada 40. Cambiar tamaño o formato es una
  modificación técnica que las licencias Creative Commons permiten.
- Vídeos: a MP4 ligero con ffmpeg (H.264, 720 px como mucho, sin sonido); los originales de wger son .mov enormes.
- Cada archivo va a la clave que dice el JSON (`ejercicios/wger/…`, `ejercicios/fedb/…`) y no se vuelve a subir si
  ya está publicado. Escribe la URL pública en el JSON (`url`).
- Sube con la API S3 de R2 y las claves R2_ENDPOINT, R2_ACCESS_KEY y R2_SECRET_KEY de
  %USERPROFILE%/.config/synaptixfit/cloudflare.env, que nunca se imprimen.

Necesita Pillow (`py -m pip install --user pillow`) y se ejecuta sin `-I` (Pillow está en los paquetes del usuario):

    py tools/exercises/upload_exercise_media.py
"""
import datetime
import hashlib
import hmac
import io
import json
import os
import pathlib
import sys
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

from PIL import Image

DATA = pathlib.Path(__file__).resolve().parent / "data"
MAPPING = DATA / "imagenes_ejercicios.json"
CACHE = pathlib.Path(tempfile.gettempdir()) / "synaptixfit-exercise-media"
PUBLIC = "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev"
MAX_SIDE = 720
QUALITY = 80
UA = {"User-Agent": "exercise-catalog-script/1.0"}


def env_value(name):
    env = pathlib.Path(os.environ["USERPROFILE"]) / ".config" / "synaptixfit" / "cloudflare.env"
    return next(l.split("=", 1)[1].strip() for l in env.read_text(encoding="utf-8").splitlines()
                if l.startswith(name + "="))


def put_object(key, body, content_type, method="PUT"):
    """PUT (o DELETE) a la API S3 de R2 con las claves de R2 y firma AWS SigV4 (sin boto3)."""
    endpoint = env_value("R2_ENDPOINT").rstrip("/")
    access, secret = env_value("R2_ACCESS_KEY"), env_value("R2_SECRET_KEY")
    host = endpoint.split("//", 1)[1]
    path = "/synaptixfit/" + urllib.parse.quote(key)
    now = datetime.datetime.now(datetime.timezone.utc)
    amz_date, day = now.strftime("%Y%m%dT%H%M%SZ"), now.strftime("%Y%m%d")
    payload_hash = hashlib.sha256(body).hexdigest()
    headers = {"host": host, "x-amz-content-sha256": payload_hash, "x-amz-date": amz_date}
    if method == "PUT":
        headers["content-type"] = content_type
    signed = ";".join(sorted(headers))
    canonical = "\n".join([method, path, "", *[f"{k}:{headers[k]}" for k in sorted(headers)], "", signed,
                           payload_hash])
    scope = f"{day}/auto/s3/aws4_request"
    to_sign = "\n".join(["AWS4-HMAC-SHA256", amz_date, scope, hashlib.sha256(canonical.encode()).hexdigest()])

    def hm(k, m):
        return hmac.new(k, m.encode(), hashlib.sha256).digest()

    key_ = hm(hm(hm(hm(("AWS4" + secret).encode(), day), "auto"), "s3"), "aws4_request")
    signature = hmac.new(key_, to_sign.encode(), hashlib.sha256).hexdigest()
    headers["authorization"] = (f"AWS4-HMAC-SHA256 Credential={access}/{scope}, SignedHeaders={signed}, "
                                f"Signature={signature}")
    req = urllib.request.Request(endpoint + path, data=body or None, method=method,
                                 headers={k: v for k, v in headers.items() if k != "host"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.status


def published(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD", headers=UA), timeout=30) as r:
            return r.status == 200
    except urllib.error.HTTPError:
        return False


def to_webp(raw):
    img = Image.open(io.BytesIO(raw))
    img = img.convert("RGBA")
    background = Image.new("RGBA", img.size, (255, 255, 255, 255))
    img = Image.alpha_composite(background, img).convert("RGB")
    img.thumbnail((MAX_SIDE, MAX_SIDE), Image.Resampling.LANCZOS)
    out = io.BytesIO()
    img.save(out, "WEBP", quality=QUALITY, method=6)
    return out.getvalue()


VIDEO_TYPES = {".mp4": "video/mp4", ".webm": "video/webm", ".mov": "video/quicktime"}


def to_mp4(raw):
    """Vídeo ligero para el móvil: H.264, 720 px de lado como mucho, 24 fps, sin sonido y con el índice al
    principio para que empiece a verse mientras se descarga."""
    with tempfile.TemporaryDirectory() as tmp:
        src, dst = pathlib.Path(tmp) / "in", pathlib.Path(tmp) / "out.mp4"
        src.write_bytes(raw)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(src), "-an", "-vf",
                        "scale='min(720,iw)':'min(720,ih)':force_original_aspect_ratio=decrease,"
                        "scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=24",
                        "-c:v", "libx264", "-preset", "slow", "-crf", "28", "-pix_fmt", "yuv420p",
                        "-movflags", "+faststart", str(dst)], check=True)
        return dst.read_bytes()


def fetch(url, tries=4):
    """Descarga con reintentos: GitHub y wger cortan a veces la conexión si se piden muchas seguidas."""
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120) as r:
                return r.read()
        except (urllib.error.URLError, ConnectionError, TimeoutError):
            if attempt == tries - 1:
                raise
            time.sleep(5 * (attempt + 1))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    data = json.loads(MAPPING.read_text(encoding="utf-8"))
    CACHE.mkdir(exist_ok=True)
    done, before, after = {}, 0, 0
    for entry in data["ejercicios"].values():
        for kind in ("foto", "video"):
            media = entry.get(kind)
            if media is None:
                continue
            key = media["clave"]
            url = f"{PUBLIC}/{key}"
            if key not in done:
                local = CACHE / key.replace("/", "_")
                if not local.exists():
                    raw = fetch(media["origen"])
                    body = to_webp(raw) if kind == "foto" else to_mp4(raw)
                    local.write_bytes(body)
                    before += len(raw)
                    after += len(body)
                if not published(url):
                    content_type = ("image/webp" if kind == "foto"
                                    else VIDEO_TYPES.get(pathlib.Path(key).suffix, "video/mp4"))
                    put_object(key, local.read_bytes(), content_type)
                    print("subida", key)
                done[key] = url
            media["url"] = done[key]
    MAPPING.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if before:
        print(f"descargado y convertido: {before // 1024} KB → {after // 1024} KB")
    print(f"archivos distintos: {len(done)} · ejercicios: {len(data['ejercicios'])}")
    missing = [u for u in done.values() if not published(u)]
    print("comprobación pública:", "todos responden 200" if not missing else f"FALTAN {len(missing)}: {missing[:5]}")


if __name__ == "__main__":
    main()
