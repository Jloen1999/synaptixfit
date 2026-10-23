"""Genera la migración Flyway que mejora y amplía el catálogo de ejercicios.

- Ejercicios actuales: descripción e instrucciones reescritas en español (de openGym si ya las traía en
  español; si no, redactadas con data/textos_ia.json), su categoría y su código externo.
- Ejercicios nuevos de openGym (sin variantes izquierda/derecha ni repetidos), con músculos, material y
  partes del cuerpo mapeados a nuestro vocabulario. Sin vídeo: la app muestra su icono.

Fuentes y licencias: data/FUENTES.md. Uso (desde la raíz): py -I tools/exercises/build_exercises_migration.py
"""
import json
import re
import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_lib import DATA, MIGRATIONS, current_exercises, new_exercises, norm, opengym, v2_rows  # noqa: E402

OUT = MIGRATIONS / "V850__training_exercise_catalog_expansion.sql"
NS = uuid.UUID("2f0c4a8e-6b7d-4c39-9e1a-5d3b8f7a1c64")

# --- Vocabulario de openGym → el nuestro (nombres exactos de musculos / equipamientos / partes_cuerpo).
TARGET = {
    "abs": "Recto abdominal", "glutes": "Glúteo mayor", "quads": "Cuádriceps", "delts": "Deltoides",
    "pectorals": "Pectoral mayor", "lats": "Dorsal ancho", "upper back": "Romboides", "triceps": "Tríceps braquial",
    "biceps": "Bíceps braquial", "calves": "Gemelos", "hamstrings": "Isquiotibiales", "spine": "Erectores espinales",
    "forearms": "Antebrazos", "abductors": "Abductores", "adductors": "Aductores", "traps": "Trapecio",
    "levator scapulae": "Elevador de la escápula", "serratus anterior": "Serrato anterior",
}
SECONDARY = {
    "core": "Core", "shoulders": "Hombros", "glutes": "Glúteo mayor", "hamstrings": "Isquiotibiales",
    "hip flexors": "Flexores de cadera", "triceps": "Tríceps braquial", "quadriceps": "Cuádriceps",
    "upper back": "Trapecio medio", "calves": "Gemelos", "lower back": "Erectores espinales", "obliques": "Oblicuos",
    "forearms": "Antebrazos", "biceps": "Bíceps braquial", "rhomboids": "Romboides",
    "rear deltoids": "Deltoides posterior", "trapezius": "Trapecio", "adductors": "Aductores",
    "chest": "Pectoral mayor", "upper chest": "Pectoral mayor (porción clavicular)",
    "grip muscles": "Flexores de los dedos", "lats": "Dorsal ancho", "lower abs": "Recto abdominal inferior",
    "rotator cuff": "Manguito rotador", "brachialis": "Braquial", "feet": "Músculos intrínsecos del pie",
    "soleus": "Sóleo", "wrist flexors": "Flexores de la muñeca", "shins": "Tibial anterior", "groin": "Aductores",
    "inner thighs": "Aductores", "wrist extensors": "Extensores de la muñeca",
    "sternocleidomastoid": "Esternocleidomastoideo", "hands": "Músculos intrínsecos de la mano",
    "traps": "Trapecio", "deltoids": "Deltoides", "back": "Dorsal ancho", "latissimus dorsi": "Dorsal ancho",
    "abdominals": "Recto abdominal",
}
EQUIPMENT = {
    "body weight": "Peso corporal", "dumbbell": "Mancuerna", "cable": "Polea", "barbell": "Barra",
    "olympic barbell": "Barra", "leverage machine": "Máquina de palanca", "band": "Banda elástica",
    "resistance band": "Banda de resistencia", "kettlebell": "Kettlebell", "suspension trainer": "Suspensión",
    "weighted": "Lastre", "smith machine": "Máquina smith", "roller": "Rodillo de espuma",
    "stability ball": "Fitball", "medicine ball": "Balón medicinal", "weight plate": "Disco",
    "ez barbell": "Barra ez", "assisted": "Asistencia", "landmine": "Landmine",
    "elliptical machine": "Máquina elíptica", "stationary bike": "Bicicleta estática",
    "stepmill machine": "Máquina escaladora",
    # Material que no existía en el catálogo: se crea.
    "rope": "Cuerda", "sled machine": "Trineo", "sandbag": "Saco de arena", "bosu ball": "Bosu",
    "trap bar": "Barra hexagonal", "wheel roller": "Rueda abdominal", "macebell": "Maza", "tire": "Neumático",
    "upper body ergometer": "Ergómetro de brazos", "skierg machine": "SkiErg", "hammer": "Mazo",
}
NEW_EQUIPMENT = ["Cuerda", "Trineo", "Saco de arena", "Bosu", "Barra hexagonal", "Rueda abdominal", "Maza",
                 "Neumático", "Ergómetro de brazos", "SkiErg", "Mazo"]
BODY_PART = {
    "upper legs": "Piernas", "lower legs": "Piernas", "back": "Espalda", "waist": "Zona media", "chest": "Pecho",
    "shoulders": "Hombros", "upper arms": "Brazos", "lower arms": "Antebrazos", "neck": "Cuello",
    "cardio": "Cuerpo completo", "full body": "Cuerpo completo",
}

# --- Categoría → modalidad, objetivos, medición y MET.
# MET: valores típicos del Compendio de Actividades Físicas 2024 (estiramientos ≈2,3; pilates ≈3;
# fuerza moderada ≈3,5; calistenia ≈3,8; halterofilia ≈6; cardio moderado ≈7; artes marciales ≈7,8;
# saltos y pliometría ≈8). Ver docs/01-architecture/formulas.md.
CATEGORY = {
    "strength": ("fuerza", ["Hipertrofia Muscular", "Fuerza Resistencia"], 3.5),
    "calisthenics": ("fuerza", ["Fuerza Resistencia", "Estabilidad y Control Motor"], 3.8),
    "olympic": ("fuerza", ["Potencia y Explosividad", "Fuerza Máxima"], 6.0),
    "isometric": ("fuerza", ["Estabilidad y Control Motor", "Fuerza Resistencia"], 3.0),
    "plyometrics": ("metabolica", ["Potencia y Explosividad"], 8.0),
    "cardio": ("aerobica", ["Acondicionamiento Metabólico"], 7.0),
    "combat": ("metabolica", ["Acondicionamiento Metabólico", "Potencia y Explosividad"], 7.8),
    "stretching": ("movilidad", ["Movilidad y Flexibilidad"], 2.3),
    "mobility": ("movilidad", ["Movilidad y Flexibilidad"], 2.5),
    "yoga": ("movilidad", ["Movilidad y Flexibilidad", "Estabilidad y Control Motor"], 2.5),
    "pilates": ("movilidad", ["Estabilidad y Control Motor", "Movilidad y Flexibilidad"], 3.0),
    "rehab": ("movilidad", ["Estabilidad y Control Motor", "Movilidad y Flexibilidad"], 2.3),
}
CATEGORY_DB = {"strength": "strength", "calisthenics": "calisthenics", "olympic": "olympic", "isometric": "isometric",
               "plyometrics": "plyometrics", "cardio": "cardio", "combat": "combat", "stretching": "stretching",
               "mobility": "mobility", "yoga": "yoga", "pilates": "pilates", "rehab": "rehab"}
TIMED = {"stretching", "mobility", "yoga", "isometric", "cardio"}
LOADED = {"dumbbell", "barbell", "olympic barbell", "cable", "leverage machine", "kettlebell", "smith machine",
          "ez barbell", "weighted", "weight plate", "sled machine", "trap bar", "landmine", "sandbag", "medicine ball"}
ADVANCED = re.compile(r"one arm (push|pull|chin)|pistol|muscle up|planche|human flag|handstand|front lever|back lever|"
                      r"dragon flag|snatch|clean and jerk|archer|typewriter|l-sit|v-sit|ring dip|nordic", re.I)
BEGINNER_EQ = {"leverage machine", "cable", "assisted", "band", "resistance band", "stationary bike",
               "elliptical machine", "stability ball", "roller"}


def q(v):
    return "NULL" if v is None else "'" + str(v).replace("'", "''") + "'"


def arr(values):
    return "ARRAY[" + ", ".join(q(v) for v in values) + "]::text[]" if values else "'{}'::text[]"


def difficulty(e):
    name, cat, eq = e["n"], e.get("cat") or "strength", e["eq"]
    if ADVANCED.search(name) or cat == "olympic":
        return "avanzado"
    if cat in ("stretching", "mobility", "rehab") or eq in BEGINNER_EQ:
        return "principiante"
    return "intermedio"


def measurement(cat, eq):
    if cat in TIMED:
        return ["tiempo"]
    return ["repeticiones", "peso"] if eq in LOADED else ["repeticiones"]


def existing_category(e, og_by_code):
    """Categoría de un ejercicio actual: la de openGym si es el mismo; si no, por nombre y modalidad."""
    og = og_by_code.get(e["code"] or "")
    if og and og.get("cat"):
        return CATEGORY_DB[og["cat"]]
    name = norm(e["name"])
    if name.startswith("estiramiento"):
        return "stretching"
    if name.startswith("postura"):
        return "yoga"
    return {"movilidad": "mobility", "metabolica": "plyometrics", "aerobica": "cardio"}.get(e["modality"], "strength")


def main():
    texts = json.loads((DATA / "textos_ia.json").read_text(encoding="utf-8"))
    catalog, es = opengym()
    og_by_code = {e["id"]: e for e in catalog}
    for table, names in (("musculos", set(TARGET.values()) | set(SECONDARY.values())),
                         ("partes_cuerpo", set(BODY_PART.values())),
                         ("equipamientos", set(EQUIPMENT.values()) - set(NEW_EQUIPMENT))):
        _, rows = v2_rows(table)
        missing = names - {r["nombre"] for r in rows}
        assert not missing, (table, missing)

    out = []
    w = out.append
    w("-- Catálogo de ejercicios mejorado y ampliado (generado por tools/exercises/build_exercises_migration.py;")
    w("-- no editar a mano). Fuentes y licencias: tools/exercises/data/FUENTES.md.\n")
    w("ALTER TABLE ejercicios ADD COLUMN categoria VARCHAR(20);")
    w("ALTER TABLE ejercicios ADD COLUMN codigo_externo VARCHAR(10);")
    w("CREATE INDEX idx_ejercicios_categoria ON ejercicios (categoria);\n")
    w("-- Material que no existía.")
    for name in NEW_EQUIPMENT:
        w(f"INSERT INTO equipamientos (nombre) SELECT {q(name)} WHERE NOT EXISTS "
          f"(SELECT 1 FROM equipamientos WHERE nombre = {q(name)});")

    current = current_exercises()
    w(f"\n-- Ejercicios actuales ({len(current)}): textos reescritos, categoría y código externo.")
    rewritten = 0
    for e in current:
        t = texts.get(e["id"], {})
        steps = (es.get(e["code"] or "") or {}).get("instructions") or t.get("instrucciones")
        sets = [f"categoria = {q(existing_category(e, og_by_code))}", f"codigo_externo = {q(e['code'])}"]
        if t.get("descripcion"):
            sets.append(f"descripcion = {q(t['descripcion'])}")
        if steps:
            sets.append(f"instrucciones = {arr(steps)}")
            rewritten += 1
        w(f"UPDATE ejercicios SET {', '.join(sets)}, actualizado_en = now() WHERE id = {q(e['id'])};")

    names_taken = {norm(e["name"]) for e in current}
    rows, links, skipped = [], {"eq": [], "tg": [], "sm": [], "bp": []}, 0
    for e in new_exercises():
        t = texts.get(e["id"], {})
        steps = e["instructions_es"] or t.get("instrucciones")
        if not steps or not t.get("descripcion"):
            skipped += 1
            continue
        name = t.get("nombre") or e["name_es"]
        if norm(name) in names_taken:
            name = e["name_es"]
        if norm(name) in names_taken:
            skipped += 1
            continue
        names_taken.add(norm(name))
        eid = str(uuid.uuid5(NS, "opengym:" + e["id"]))
        cat = e.get("cat") or "strength"
        modality, purposes, met = CATEGORY[cat]
        rows.append(f"({q(eid)}, {q(name[:1].upper() + name[1:])}, {arr(steps)}, {q(difficulty(e))}, "
                    f"{q(t['descripcion'])}, {arr(purposes)}, {q(modality)}, {arr(measurement(cat, e['eq']))}, "
                    f"false, true, {met}, {q(CATEGORY_DB[cat])}, {q(e['id'])})")
        if e["eq"] in EQUIPMENT:
            links["eq"].append((eid, EQUIPMENT[e["eq"]]))
        target = TARGET.get(e["tg"])
        if target:
            links["tg"].append((eid, target))
        for m in dict.fromkeys(SECONDARY[s] for s in (e.get("sm") or []) if s in SECONDARY):
            if m != target:
                links["sm"].append((eid, m))
        if e["bp"] in BODY_PART:
            links["bp"].append((eid, BODY_PART[e["bp"]]))

    w(f"\n-- Ejercicios nuevos ({len(rows)}), sin vídeo.")
    for i in range(0, len(rows), 300):
        w("INSERT INTO ejercicios (id, nombre, instrucciones, dificultad, descripcion, finalidad, "
          "modalidad_entrenamiento, tipo_medicion, es_circuito, activo, valor_met, categoria, codigo_externo) VALUES\n"
          + ",\n".join(rows[i:i + 300]) + ";")

    w("\n-- Relaciones de los ejercicios nuevos con músculos, material y partes del cuerpo (por nombre).")
    for key, table, col, vocab in (("eq", "ejercicio_equipamiento", "equipamiento_id", "equipamientos"),
                                   ("tg", "ejercicio_musculo_objetivo", "musculo_id", "musculos"),
                                   ("sm", "ejercicio_musculo_secundario", "musculo_id", "musculos"),
                                   ("bp", "ejercicio_parte_cuerpo", "parte_cuerpo_id", "partes_cuerpo")):
        pairs = links[key]
        for i in range(0, len(pairs), 1000):
            values = ",\n".join(f"({q(a)}, {q(b)})" for a, b in pairs[i:i + 1000])
            w(f"INSERT INTO {table} (ejercicio_id, {col})\nSELECT CAST(v.e AS uuid), c.id FROM (VALUES\n{values}\n"
              f") AS v(e, n) JOIN {vocab} c ON c.nombre = v.n;")

    OUT.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
    print(f"{OUT.name}: {len(current)} actuales ({rewritten} con instrucciones nuevas), {len(rows)} nuevos, "
          f"{skipped} omitidos sin textos o repetidos; {OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
