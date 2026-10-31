"""Nombres técnicos de los ejercicios (y de músculos, material y partes del cuerpo) en inglés,
francés y portugués de Portugal, con DeepSeek.

Por cada ejercicio la IA recibe el nombre en español (revisado), el nombre técnico en inglés de
openGym (fuente original) y las traducciones literales de openGym en francés y portugués de Brasil
como pista, y devuelve el nombre que usaría un entrenador en cada idioma. Guarda en
data/nombres_i18n.json después de cada lote: se puede interrumpir y relanzar (solo pide lo que falta).
La clave se lee de backend/.env y nunca se imprime.

Entrada: data/ejercicios_bd.json y data/vocabulario_bd.json (exportados de una BD con todas las
migraciones aplicadas; ver FUENTES.md).

Uso (desde la raíz):  py -I tools/exercises/translate_names.py [--limit N] [--workers 6]
"""
import argparse
import json
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DATA = HERE / "data"
OUT = DATA / "nombres_i18n.json"
OUT_VOCAB = DATA / "vocabulario_i18n.json"
BATCH = 40

PROMPT = """You are a certified strength & conditioning coach and a professional translator of fitness apps.
For each exercise in the input JSON return the name a coach would use in a gym in each language:
- "en": English (US), the standard technical name (e.g. "Barbell bench press", "Romanian deadlift", "Dumbbell lateral raise", "Child's pose").
- "fr": French (France), the usual gym terminology (e.g. "Développé couché à la barre", "Soulevé de terre roumain", "Élévations latérales aux haltères", "Fente arrière", "Gainage", "Posture de l'enfant").
- "pt": European Portuguese (Portugal), the usual gym terminology (e.g. "Supino reto com barra", "Peso morto romeno", "Elevação lateral com halteres", "Afundo", "Prancha", "Postura da criança"). Prefer Portugal usage over Brazil when they differ.
Rules:
- Sentence case (only the first letter and proper nouns capitalized). No side (left/right), no "v. 2", no quotes.
- Keep the meaning of the Spanish name ("es"), which is the reviewed one; use "en_source" (original technical name) to choose the exact standard term; "fr_hint" and "pt_hint" are literal machine translations: only hints.
- Keep equipment and variations that matter (grip, stance, bench angle, unilateral). Use the equipment terms of each language (barbell / barre / barra, dumbbell / haltère / halter, kettlebell, cable / poulie / cabo, resistance band / élastique / elástico).
- Keep established loanwords when coaches use them (press, curl, kettlebell, burpee, crunch, pilates and yoga pose names).
Return ONLY JSON: {"ejercicios": [{"id": "...", "en": "...", "fr": "...", "pt": "..."}]}"""

VOCAB_PROMPT = """Translate these Spanish anatomy and gym vocabulary terms (muscles, equipment, body parts) used as filters in a fitness app into English (US), French (France) and European Portuguese (Portugal), using the standard terminology of each language (anatomy terms as a coach would say them). Sentence case.
Return ONLY JSON: {"terminos": [{"es": "...", "en": "...", "fr": "...", "pt": "..."}]} with every input term exactly once and "es" copied unchanged."""


def api_key():
    for line in (ROOT / "backend/.env").read_text(encoding="utf-8").splitlines():
        if line.startswith("DEEPSEEK_API_KEY="):
            return line.split("=", 1)[1].strip().strip('"')
    sys.exit("Falta DEEPSEEK_API_KEY en backend/.env")


def call(key, system, payload, root):
    body = {
        "model": "deepseek-chat",
        "messages": [{"role": "system", "content": system},
                     {"role": "user", "content": json.dumps(payload, ensure_ascii=False)}],
        "temperature": 0.2, "max_tokens": 8192, "response_format": {"type": "json_object"},
    }
    req = urllib.request.Request("https://api.deepseek.com/chat/completions", data=json.dumps(body).encode(),
                                 headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=240) as r:
                content = json.load(r)["choices"][0]["message"]["content"]
            return json.loads(content).get(root, [])
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError) as ex:
            print(f"  reintento {attempt + 1}: {type(ex).__name__}", flush=True)
            time.sleep(5 * (attempt + 1))
    return []


def clean(name):
    name = " ".join(str(name or "").split()).strip(" .\"'«»")
    return name[:1].upper() + name[1:] if name else ""


def exercise_items(done):
    exercises = json.loads((DATA / "ejercicios_bd.json").read_text(encoding="utf-8"))
    catalog = {e["id"]: e for e in json.loads((DATA / "opengym_catalogo.json").read_text(encoding="utf-8"))}
    fr = json.loads((DATA / "opengym_fr.json").read_text(encoding="utf-8"))
    pt = json.loads((DATA / "opengym_pt-BR.json").read_text(encoding="utf-8"))
    items = []
    for e in exercises:
        if e["id"] in done:
            continue
        code = e.get("code")
        items.append({
            "id": e["id"], "es": e["nombre"], "category": e.get("cat"), "equipment": e.get("material"),
            "en_source": (catalog.get(code) or {}).get("n"),
            "fr_hint": (fr.get(code) or {}).get("name"),
            "pt_hint": (pt.get(code) or {}).get("name"),
        })
    return items


def translate_vocabulary(key):
    vocab = json.loads((DATA / "vocabulario_bd.json").read_text(encoding="utf-8"))
    terms = sorted({t for group in vocab.values() for t in group})
    result = json.loads(OUT_VOCAB.read_text(encoding="utf-8")) if OUT_VOCAB.exists() else {}
    if all(t in result for t in terms):
        return
    # Varias pasadas en lotes pequeños: la IA a veces omite términos de un lote largo.
    for _ in range(4):
        missing = [t for t in terms if t not in result]
        for i in range(0, len(missing), 25):
            for x in call(key, VOCAB_PROMPT, missing[i:i + 25], "terminos"):
                if x.get("es") in terms and all(x.get(k) for k in ("en", "fr", "pt")):
                    result[x["es"]] = {k: clean(x[k]) for k in ("en", "fr", "pt")}
    missing = [t for t in terms if t not in result]
    print(f"vocabulario: {len(result)} términos, faltan {len(missing)}", flush=True)
    OUT_VOCAB.write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--workers", type=int, default=6)
    args = parser.parse_args()
    key = api_key()
    translate_vocabulary(key)
    done = json.loads(OUT.read_text(encoding="utf-8")) if OUT.exists() else {}
    items = exercise_items(done)
    if args.limit:
        items = items[:args.limit]
    batches = [items[i:i + BATCH] for i in range(0, len(items), BATCH)]
    print(f"ejercicios pendientes: {len(items)} en {len(batches)} lotes", flush=True)
    lock = threading.Lock()

    def run(batch):
        wanted = {x["id"] for x in batch}
        got = call(key, PROMPT, batch, "ejercicios")
        ok = {x["id"]: {k: clean(x.get(k)) for k in ("en", "fr", "pt")}
              for x in got if x.get("id") in wanted and all(x.get(k) for k in ("en", "fr", "pt"))}
        with lock:
            done.update(ok)
            OUT.write_text(json.dumps(done, ensure_ascii=False, indent=1), encoding="utf-8")
            print(f"  lote: {len(ok)}/{len(batch)} · total {len(done)}", flush=True)

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        list(pool.map(run, batches))
    print(f"hecho: {len(done)} ejercicios traducidos", flush=True)


if __name__ == "__main__":
    main()
