"""Datos comunes de las herramientas de ejercicios: el catálogo actual (V2 + nombres de V700) y
los ejercicios de openGym que faltan. Ver data/FUENTES.md."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = Path(__file__).resolve().parent / "data"
MIGRATIONS = ROOT / "backend/src/main/resources/db/migration/postgresql"
sys.path.insert(0, str(ROOT / "tools/catalog"))
from build_catalog_migration import V2, norm, v2_rows  # noqa: E402

# «(left)», «(right)» y «v. 2» son variantes del mismo movimiento: se queda una.
VARIANT = re.compile(r"\((left|right|izquierda|derecha)\)|\bv\.?\s*\d\b", re.I)


def variant_key(name):
    return re.sub(r"[^a-z0-9]+", " ", VARIANT.sub("", (name or "").lower())).strip()


def sentence(text):
    t = (text or "").strip()
    return t[:1].upper() + t[1:] if t else t


def current_exercises():
    """Ejercicios sembrados en V2 con el nombre vigente tras V700, sus músculos y su material."""
    _, rows = v2_rows("ejercicios")
    renames = {}
    v700 = (MIGRATIONS / "V700__training_exercise_names_es.sql").read_text(encoding="utf-8")
    for new, eid in re.findall(r"SET nombre = '((?:[^']|'')*)', actualizado_en = now\(\) WHERE id = '([^']+)'", v700):
        renames[eid] = new.replace("''", "'")
    names = {}
    for table in ("musculos", "equipamientos", "partes_cuerpo"):
        _, r = v2_rows(table)
        names.update({x["id"]: x["nombre"] for x in r})
    links = {}
    for table, col, key in (("ejercicio_musculo_objetivo", "musculo_id", "target"),
                            ("ejercicio_musculo_secundario", "musculo_id", "secondary"),
                            ("ejercicio_equipamiento", "equipamiento_id", "equipment")):
        _, r = v2_rows(table)
        for x in r:
            links.setdefault(x["ejercicio_id"], {}).setdefault(key, []).append(names.get(x[col], ""))
    out = []
    for e in rows:
        url = e.get("url_gif") or ""
        m = re.search(r"/(\d{4})\d{4}-([A-Za-z0-9-]+)_", url)
        out.append({
            "id": e["id"],
            "name": renames.get(e["id"], e["nombre"]),
            "code": m.group(1) if m else None,
            "name_en": m.group(2).replace("-", " ") if m else None,
            "modality": e["modalidad_entrenamiento"],
            **links.get(e["id"], {}),
        })
    return out


def opengym():
    catalog = json.loads((DATA / "opengym_catalogo.json").read_text(encoding="utf-8"))
    es = json.loads((DATA / "opengym_es.json").read_text(encoding="utf-8"))
    return catalog, es


def new_exercises():
    """Ejercicios de openGym que no están en el catálogo actual, sin variantes repetidas."""
    current = current_exercises()
    codes = {c["code"] for c in current if c["code"]}
    taken = {norm(c["name"]) for c in current}
    catalog, es = opengym()
    seen, out = set(), []
    for e in catalog:
        if e["id"] in codes:
            continue
        key = variant_key(e["n"])
        name_es = sentence(VARIANT.sub("", (es.get(e["id"]) or {}).get("name") or "").strip())
        if key in seen or not name_es or norm(name_es) in taken:
            continue
        seen.add(key)
        taken.add(norm(name_es))
        out.append({**e, "name_es": name_es, "instructions_es": (es.get(e["id"]) or {}).get("instructions") or []})
    return out
