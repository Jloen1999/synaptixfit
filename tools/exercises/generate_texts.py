"""Redacta con DeepSeek los textos en español de los ejercicios: nombre natural (solo los nuevos),
descripción breve e instrucciones paso a paso (si no hay ya unas en español).

Guarda el resultado en data/textos_ia.json (id → textos) después de cada lote, así que se puede
interrumpir y volver a lanzar: solo pide lo que falta. La clave se lee de backend/.env y nunca se
imprime. Los textos generados se revisan por muestreo antes de generar la migración.

Uso (desde la raíz):  py -I tools/exercises/generate_texts.py [--limit N] [--workers 6]
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

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_lib import ROOT, DATA, current_exercises, new_exercises, opengym  # noqa: E402

OUT = DATA / "textos_ia.json"
BATCH = 15
CATEGORY_ES = {
    "strength": "fuerza", "calisthenics": "calistenia", "stretching": "estiramiento", "mobility": "movilidad",
    "plyometrics": "pliometría", "isometric": "isométrico", "cardio": "cardio", "yoga": "yoga",
    "olympic": "halterofilia", "pilates": "pilates", "rehab": "readaptación", "combat": "combate",
}
PROMPT = """Eres entrenador personal titulado y redactas fichas de ejercicios para una app de estudiantes universitarios, en español de España.
Para cada ejercicio del JSON de entrada devuelve un objeto con su "id" y:
- "nombre": SOLO si el campo "pedir_nombre" es true. Nombre natural, como lo diría un entrenador en un gimnasio español, en formato frase (solo la primera letra en mayúscula), sin «Ejercicio de» delante salvo que haga falta, sin lado (izquierda/derecha). Usa términos habituales: press, curl, remo, sentadilla, zancada, plancha, dominada, fondos, elevación, jalón, peso muerto, puente de glúteo, estiramiento de…, postura de… (yoga). Si el nombre en español ya suena natural, déjalo igual.
- "descripcion": una frase de 12 a 25 palabras: qué trabaja y para qué sirve (sin repetir el nombre).
- "instrucciones": SOLO si el campo "pedir_instrucciones" es true. De 3 a 5 pasos en imperativo (tú), concretos y seguros: posición inicial, movimiento, respiración o tempo si importa, y un error común que evitar. Cada paso es una frase, sin numerar.
No inventes material que no esté en "material". Responde SOLO con JSON: {"ejercicios": [ ... ]}"""


def api_key():
    for line in (ROOT / "backend/.env").read_text(encoding="utf-8").splitlines():
        if line.startswith("DEEPSEEK_API_KEY="):
            return line.split("=", 1)[1].strip().strip('"')
    sys.exit("Falta DEEPSEEK_API_KEY en backend/.env")


def pending_items(done):
    _, es = opengym()
    items = []
    for e in current_exercises():
        if e["id"] in done:
            continue
        has_es = bool(e["code"] and (es.get(e["code"]) or {}).get("instructions"))
        items.append({"id": e["id"], "nombre_es": e["name"], "nombre_en": e.get("name_en"),
                      "material": e.get("equipment") or [], "musculo_principal": e.get("target") or [],
                      "musculos_secundarios": e.get("secondary") or [], "tipo": e["modality"],
                      "pedir_nombre": False, "pedir_instrucciones": not has_es})
    for e in new_exercises():
        if e["id"] in done:
            continue
        items.append({"id": e["id"], "nombre_es": e["name_es"], "nombre_en": e["n"], "material": [e["eq"]],
                      "musculo_principal": [e["tg"]], "musculos_secundarios": e.get("sm") or [],
                      "tipo": CATEGORY_ES.get(e.get("cat"), "fuerza"),
                      "pedir_nombre": True, "pedir_instrucciones": not e["instructions_es"]})
    return items


def call(key, batch):
    body = {
        "model": "deepseek-chat",
        "messages": [{"role": "system", "content": PROMPT},
                     {"role": "user", "content": json.dumps(batch, ensure_ascii=False)}],
        "temperature": 0.3, "max_tokens": 8192, "response_format": {"type": "json_object"},
    }
    req = urllib.request.Request("https://api.deepseek.com/chat/completions", data=json.dumps(body).encode(),
                                 headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=240) as r:
                content = json.load(r)["choices"][0]["message"]["content"]
            return {str(x["id"]): x for x in json.loads(content).get("ejercicios", []) if "id" in x}
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError) as ex:
            if attempt == 3:
                print("lote fallido:", type(ex).__name__, flush=True)
                return {}
            time.sleep(5 * (attempt + 1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=0, help="solo los N primeros pendientes (prueba)")
    ap.add_argument("--workers", type=int, default=6)
    args = ap.parse_args()
    done = json.loads(OUT.read_text(encoding="utf-8")) if OUT.exists() else {}
    items = pending_items(done)
    if args.limit:
        items = items[:args.limit]
    batches = [items[i:i + BATCH] for i in range(0, len(items), BATCH)]
    print(f"pendientes: {len(items)} en {len(batches)} lotes", flush=True)
    key, lock, progress = api_key(), threading.Lock(), [0]

    def run(batch):
        result = call(key, batch)
        with lock:
            for item in batch:
                r = result.get(item["id"])
                if r and r.get("descripcion") and (not item["pedir_instrucciones"] or r.get("instrucciones")):
                    done[item["id"]] = {k: r[k] for k in ("nombre", "descripcion", "instrucciones") if r.get(k)}
            OUT.write_text(json.dumps(done, ensure_ascii=False, indent=0), encoding="utf-8")
            progress[0] += 1
            if progress[0] % 10 == 0 or progress[0] == len(batches):
                print(f"lotes {progress[0]}/{len(batches)} · textos {len(done)}", flush=True)

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        list(pool.map(run, batches))
    print("listo:", len(done), "ejercicios con textos", flush=True)


if __name__ == "__main__":
    main()
