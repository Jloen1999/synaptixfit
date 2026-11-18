"""Fotos y vídeos para los ejercicios del catálogo que no tienen ninguno (fase 3C, ADR 0056).

Fuentes, por orden de preferencia (el propietario pidió cobertura completa el 18 nov 2026 y asume el riesgo de
licencia; cada imagen guarda su fuente para poder retirarla de una vez, ver ADR 0056):
  1. wger (https://wger.de), ilustraciones de Everkinetic (CC BY-SA 3.0): procedencia conocida.
  2. wger, el resto de imágenes: cada una declara su licencia y su autor, pero las suben usuarios sin revisión.
  3. free-exercise-db (https://github.com/yuhonas/free-exercise-db): repositorio con Unlicense; las fotos vienen de
     wrkout/exercises.json y su origen no está documentado.
  Vídeos: solo wger (/api/v2/video/), con su licencia por vídeo.

Empareja por nombre en inglés normalizado con data/nombres_i18n.json y, a mano, por MANUAL. Solo rellena los
ejercicios sin foto ni vídeo (los 909 del catálogo original ya los tienen). Escribe data/imagenes_ejercicios.json;
upload_exercise_media.py convierte y sube cada archivo a R2.

    py -I tools/exercises/exercise_images.py
"""
import json
import re
import sys
import time
import urllib.request
from pathlib import Path

DATA = Path(__file__).resolve().parent / "data"
OUT = DATA / "imagenes_ejercicios.json"
HEADERS = {"User-Agent": "exercise-catalog-script/1.0", "Accept": "application/json"}
WGER_INFO = ("https://wger.de/api/v2/exerciseinfo/?format=json&limit=100&offset={offset}",
             DATA / "wger_exerciseinfo.json")
WGER_VIDEOS = ("https://wger.de/api/v2/video/?format=json&limit=100&offset={offset}", DATA / "wger_videos.json")
FEDB_JSON = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
FEDB_IMAGES = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/"
FEDB_CACHE = DATA / "fedb_exercises.json"
ENGLISH = 2
# Licencias de wger (ids de /api/v2/license/).
LICENSES = {
    1: ("CC BY-SA 3.0", "https://creativecommons.org/licenses/by-sa/3.0/"),
    2: ("CC BY-SA 4.0", "https://creativecommons.org/licenses/by-sa/4.0/"),
    3: ("CC0 1.0", "https://creativecommons.org/publicdomain/zero/1.0/"),
    4: ("CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/"),
}
FEDB_LICENSE = ("Unlicense", "https://unlicense.org/")

# Emparejados a mano (nombre nuestro → id de ejercicio de wger): mismo movimiento con otro nombre. Se dejan sin foto
# los que cambian de agarre, material o dificultad: una foto de otra variante confunde más que el icono.
MANUAL = {
    "Curl de bíceps con mancuernas de pie": 92,
    "Curl femoral tumbado en máquina": 365,
    "Elevación de gemelos de pie con apoyo": 1243,
    "Elevación de gemelos de pie con barra": 622,
    "Elevación lateral con botella": 348,
    "Elevación lateral con mancuernas sentado": 348,
    "Extensión de cuádriceps sentado en máquina": 369,
    "Extensión de tríceps en polea alta": 659,
    "Extensión de tríceps sentado con mancuernas": 1336,
    "Face pull de pie con polea": 1732,
    "Hip thrust con barra": 1642,
    "Peso muerto rumano con barra (glúteo mayor)": 1652,
    "Plancha abdominal sobre antebrazos": 458,
    "Prensa de piernas a 45° (postura estándar)": 371,
    "Press de banca con barra": 73,
    "Press de banca con mancuerna": 75,
    "Press de hombros con mancuernas sentado": 567,
    "Press de hombros de pie con mancuerna": 567,
    "Press de hombros sentado en máquina": 543,
    "Press de pecho en máquina": 129,
    "Press en el suelo a una mano con mancuerna": 1084,
    "Remo a una mano con mancuerna": 81,
    "Remo axilar con botella": 81,
    "Remo con barra y agarre prono": 83,
    "Remo sentado en polea baja con agarre estrecho": 512,
    "Sentadilla búlgara con mancuerna": 1706,
    "Sentadilla goblet con kettlebell": 203,
    "Sentadilla trasera con barra (postura estándar)": 1801,
    "Remo inclinado con barra": 83,
    "Remo inclinado con agarre inverso y barra": 84,
    "Curl en polea": 95,
    "Abdominal declinado": 171,
    "Fondos en banco con piernas en el banco": 197,
    "Sentadilla frontal con barra": 257,
    "Curl martillo en polea": 275,
    "Hiperextensión": 301,
    "Cruce de poleas": 323,
    "Elevaciones laterales con mancuernas": 348,
    "Press de hombros sentado con mancuernas": 567,
    "Encogimiento de hombros con barra": 571,
    "Encogimientos de hombros con mancuernas": 572,
    "Good morning con barra": 1392,
}

# Palabras que no cambian el movimiento y se quitan al comparar.
NOISE = re.compile(r"\b(the|a|an|with|on|of|exercise|standard|stance)\b")
SYNONYMS = [
    (r"\bdumbbells?\b", "db"), (r"\bbarbell\b", "bb"), (r"\bpush ?ups?\b", "pushup"),
    (r"\bpull ?ups?\b", "pullup"), (r"\bchin ?ups?\b", "chinup"), (r"\bsit ?ups?\b", "situp"),
    (r"\blat ?pull ?down\b", "lat pulldown"), (r"\bpulldown\b", "pulldown"), (r"\bcurls\b", "curl"),
    (r"\bsquats\b", "squat"), (r"\blunges\b", "lunge"), (r"\braises\b", "raise"), (r"\brows\b", "row"),
    (r"\bcrunches\b", "crunch"), (r"\bplanks\b", "plank"), (r"\bdips\b", "dip"), (r"\bextensions\b", "extension"),
]


def norm(name):
    t = (name or "").lower().replace("-", " ").replace("_", " ")
    t = re.sub(r"\(.*?\)", " ", t)
    for pattern, repl in SYNONYMS:
        t = re.sub(pattern, repl, t)
    t = NOISE.sub(" ", re.sub(r"[^a-z0-9 ]+", " ", t))
    return " ".join(sorted(t.split()))


def get_json(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def wger_pages(source):
    url, cache = source
    if cache.exists():
        return json.loads(cache.read_text(encoding="utf-8"))
    items, offset = [], 0
    while True:
        page = get_json(url.format(offset=offset))
        items += page["results"]
        print(f"wger {cache.stem}: {len(items)} de {page['count']}")
        if not page.get("next"):
            break
        offset += 100
        time.sleep(1)  # sin prisa: es un servicio de voluntarios
    cache.write_text(json.dumps(items, ensure_ascii=False), encoding="utf-8")
    return items


def fedb():
    if not FEDB_CACHE.exists():
        FEDB_CACHE.write_text(json.dumps(get_json(FEDB_JSON), ensure_ascii=False), encoding="utf-8")
    return json.loads(FEDB_CACHE.read_text(encoding="utf-8"))


def credit(source, license_id=None, author=None, work=None):
    title, url = LICENSES[license_id] if license_id else FEDB_LICENSE
    return {"fuente": source, "licencia": title, "licencia_url": url,
            "autor": (author or "").strip() or None, "obra_url": (work or "").strip() or None}


def wger_media():
    """Por id de ejercicio de wger: nombre en inglés, mejor imagen (Everkinetic primero) y mejor vídeo."""
    videos = {}
    for v in wger_pages(WGER_VIDEOS):
        if v.get("license") in LICENSES and v.get("video"):
            best = videos.get(v["exercise"])
            if best is None or (v.get("is_main") and not best.get("is_main")):
                videos[v["exercise"]] = v
    out = {}
    for ex in wger_pages(WGER_INFO):
        images = [i for i in ex.get("images") or [] if i.get("license") in LICENSES and not i.get("is_ai_generated")]
        images.sort(key=lambda i: ((i.get("license_author") or "").strip() != "Everkinetic", not i.get("is_main"),
                                   i.get("id", 0)))
        video = videos.get(ex["id"]) or next((videos.get(v["exercise"]) for v in ex.get("videos") or []
                                             if videos.get(v.get("exercise"))), None)
        if not images and not video:
            continue
        english = next((t["name"] for t in ex.get("translations") or [] if t.get("language") == ENGLISH), None)
        out[ex["id"]] = {"en": english, "image": images[0] if images else None, "video": video}
    return out


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    wger = wger_media()
    wger_by_name = {}
    for wid, m in wger.items():
        if m["en"]:
            wger_by_name.setdefault(norm(m["en"]), wid)
    fedb_by_name = {}
    for e in fedb():
        if e.get("images"):
            fedb_by_name.setdefault(norm(e["name"]), e)
    print(f"wger: {len(wger)} con foto o vídeo · free-exercise-db: {len(fedb_by_name)} con foto")

    ours = json.loads((DATA / "nombres_i18n.json").read_text(encoding="utf-8"))
    bd = json.loads((DATA / "ejercicios_bd.json").read_text(encoding="utf-8"))
    names = {e["id"]: e["nombre"] for e in bd}
    # Segunda clave: el nombre inglés original de openGym (el nuestro lo tradujo la IA y a veces difiere).
    og_names = {e["id"]: e["n"] for e in json.loads((DATA / "opengym_catalogo.json").read_text(encoding="utf-8"))}
    original_en = {e["id"]: og_names.get(e.get("code")) for e in bd}
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from catalog_lib import v2_rows
    _, v2 = v2_rows("ejercicios")
    has_media = {r["id"] for r in v2 if r.get("url_preview") or r.get("url_gif")}
    ids_by_name = {}
    for eid, name in names.items():
        ids_by_name.setdefault(name, []).append(eid)
    manual = {eid: wid for n, wid in MANUAL.items() if wid in wger for eid in ids_by_name.get(n, [])}
    unresolved = [n for n, wid in MANUAL.items() if n not in ids_by_name or wid not in wger]
    if unresolved:
        print("AVISO, emparejamiento manual sin resolver:", unresolved)

    result = {}
    for eid, langs in ours.items():
        if eid in has_media:
            continue
        keys = [k for k in (norm(langs.get("en")), norm(original_en.get(eid))) if k]
        entry = {}
        wid = manual.get(eid) or next((wger_by_name[k] for k in keys if k in wger_by_name), None)
        key = next((k for k in keys if k in fedb_by_name), None)
        w = wger.get(wid) if wid else None
        if w and w["image"]:
            i = w["image"]
            entry["foto"] = {"origen": i["image"], "clave": f"ejercicios/wger/{wid}.webp",
                             **credit("wger", i["license"], i.get("license_author"), i.get("license_object_url"))}
        elif key in fedb_by_name:
            f = fedb_by_name[key]
            entry["foto"] = {"origen": FEDB_IMAGES + f["images"][0], "clave": f"ejercicios/fedb/{f['id']}.webp",
                             **credit("free-exercise-db", work=f"https://github.com/yuhonas/free-exercise-db")}
        if w and w["video"]:
            v = w["video"]
            # Siempre MP4: upload_exercise_media.py lo convierte (los originales son .mov de hasta 57 MB).
            entry["video"] = {"origen": v["video"], "clave": f"ejercicios/wger/video/{v['id']}.mp4",
                              **credit("wger", v["license"], v.get("license_author"), v.get("license_object_url"))}
        if entry:
            result[eid] = {"nombre": names.get(eid), "en": langs.get("en"), **entry}

    templates = json.loads((DATA / "plantillas_rutina_3.json").read_text(encoding="utf-8"))
    used = sorted({s[0] for sesion in templates["sesiones"].values() for s in sesion})

    def status(name):
        ids = ids_by_name.get(name, [])
        if any(i in has_media for i in ids):
            return "original"
        return "nueva" if any(i in result for i in ids) else "sin foto"

    report = {n: status(n) for n in used}
    OUT.write_text(json.dumps({
        "_leeme": "Fotos y vídeos nuevos por ejercicio, con su fuente y licencia (exercise_images.py, ADR 0056).",
        "ejercicios": result,
        "plantillas": report,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    by_source = {}
    for r in result.values():
        if "foto" in r:
            by_source[r["foto"]["fuente"]] = by_source.get(r["foto"]["fuente"], 0) + 1
    print(f"ejercicios con algo nuevo: {len(result)} · fotos por fuente: {by_source} · "
          f"vídeos: {sum(1 for r in result.values() if 'video' in r)}")
    print("plantillas:", {k: sum(1 for v in report.values() if v == k) for k in ("original", "nueva", "sin foto")})


if __name__ == "__main__":
    main()
