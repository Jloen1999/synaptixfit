"""Genera la migración que corrige los músculos mal etiquetados del catálogo (ADR 0054).

Al sembrar V2, cientos de ejercicios recibieron un juego de músculos «por defecto» elegido por una palabra del nombre
en inglés: «leg press» → press de pecho (pectoral, deltoides anterior, tríceps), «leg curl» → curl de bíceps, «leg
extension» → extensión de tríceps, «calf raise» → elevación lateral (deltoides medio)… La generación automática de
rutinas elige ejercicios por su músculo principal, así que esos errores la desvían.

Este script lee los músculos de V2 y, solo en los ejercicios que tienen exactamente uno de esos juegos por defecto,
aplica la primera regla cuyo patrón encaja con el nombre (vigente tras V700). Los que no encajan con ninguna regla se
quedan como estaban (el juego por defecto acierta en muchos: un press de banca sí trabaja el pectoral). La migración
borra y vuelve a insertar los músculos de cada ejercicio corregido, buscando cada músculo por su nombre.

Uso (desde la raíz):  py -I tools/exercises/build_muscle_fix_migration.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MIGRATIONS = ROOT / "backend/src/main/resources/db/migration/postgresql"
TARGET = MIGRATIONS / "V1075__training_exercise_muscles_fix.sql"

# Juegos por defecto del sembrado (músculo principal, secundarios).
CORE_DEFAULT = (["Recto abdominal", "Oblicuos"], ["Transverso abdominal", "Erectores espinales"])
CORE_MUSCLES = {"Recto abdominal", "Oblicuos", "Transverso abdominal"}
DEFAULTS = [
    (["Pectoral mayor"], ["Deltoides anterior", "Tríceps braquial"]),
    (["Deltoides medio"], ["Trapecio superior", "Tríceps braquial"]),
    (["Bíceps braquial"], ["Braquial", "Braquiorradial"]),
    (["Tríceps braquial"], ["Braquial", "Braquiorradial"]),
    (["Dorsal ancho", "Romboides"], ["Trapecio medio", "Erectores espinales"]),
    (["Recto abdominal", "Oblicuos"], ["Transverso abdominal", "Erectores espinales"]),
    (["Deltoides anterior"], ["Trapecio superior", "Tríceps braquial"]),
]

CALF = (["Gastrocnemio", "Sóleo"], [])
CALF_SEATED = (["Sóleo"], ["Gastrocnemio"])
HAMSTRING = (["Isquiotibiales"], ["Gastrocnemio"])
QUAD = (["Cuádriceps"], [])
LEG_PRESS = (["Cuádriceps", "Glúteo mayor"], ["Isquiotibiales", "Aductores"])
SHOULDER_PRESS = (["Deltoides anterior", "Deltoides medio"], ["Tríceps braquial", "Trapecio superior"])
LATERAL = (["Deltoides medio"], ["Trapecio superior"])
REAR_DELT = (["Deltoides posterior"], ["Romboides", "Trapecio medio"])
LEG_RAISE = (["Recto abdominal"], ["Iliopsoas"])
TRICEPS = (["Tríceps braquial"], ["Deltoides posterior"])
DIPS = (["Tríceps braquial"], ["Pectoral mayor", "Deltoides anterior"])
PLANK = (["Recto abdominal", "Transverso abdominal"], ["Deltoides anterior", "Glúteo mayor"])

# (patrón sobre el nombre en minúsculas, (principales, secundarios)). Gana la primera que encaja.
RULES = [
    (r"gemelos sentado|sentado.*gemelos|prensa de gemelos sentado", CALF_SEATED),
    (r"tibial anterior|tibiales con pie", (["Tibial anterior"], [])),
    (r"gemelos", CALF),
    (r"inversión de pie", (["Tibial posterior"], ["Tibial anterior"])),
    (r"elevación de glúteo e isquiotibiales", (["Isquiotibiales", "Glúteo mayor"], ["Gastrocnemio", "Erectores espinales"])),
    (r"curl femoral|curl nórdico|puente de isquiotibiales", HAMSTRING),
    (r"extensión de cuádriceps", QUAD),
    (r"prensa de piernas", LEG_PRESS),
    (r"sentadilla y press", (["Cuádriceps", "Glúteo mayor", "Deltoides anterior"], ["Tríceps braquial"])),
    (r"sentadilla frontal", (["Cuádriceps", "Glúteo mayor"], ["Erectores espinales", "Recto abdominal"])),
    (r"zancada y curl", (["Cuádriceps", "Glúteo mayor"], ["Bíceps braquial"])),
    (r"peso muerto y curl", (["Isquiotibiales", "Glúteo mayor"], ["Bíceps braquial", "Erectores espinales"])),
    (r"hiperextensión inversa", (["Glúteo mayor", "Isquiotibiales"], ["Erectores espinales"])),
    (r"hiperextensión", (["Erectores espinales"], ["Glúteo mayor", "Isquiotibiales"])),
    (r"elevación de cadera tumbado", (["Glúteo mayor"], ["Isquiotibiales"])),
    (r"arrancada|cargada|dos tiempos|envión", (["Glúteo mayor", "Isquiotibiales"], ["Deltoides anterior", "Trapecio superior"])),
    (r"crunch oblicuo con elevación de piernas", (["Oblicuos", "Recto abdominal"], ["Iliopsoas"])),
    (r"elevación de piernas.*giro|elevación de piernas con giro", (["Recto abdominal", "Oblicuos"], ["Iliopsoas"])),
    (r"elevación de piernas|elevación de una pierna", LEG_RAISE),
    (r"press militar (con giro ruso|isométrico|sentado en el suelo)", (["Deltoides anterior"], ["Tríceps braquial", "Recto abdominal", "Oblicuos"])),
    (r"press de hombros|press militar|press arnold|press z\b|press estricto|press por encima de la cabeza|press sentado con|press con impulso|press alterno con kettlebell|press cubano|press lateral alterno|flexión en pino|flexión en pica", SHOULDER_PRESS),
    (r"elevación lateral", LATERAL),
    (r"remo para deltoides posterior|tirón de deltoides posterior|aperturas inversas|deltoides posterior con peso corporal", REAR_DELT),
    (r"remo kayak", (["Dorsal ancho"], ["Oblicuos", "Bíceps braquial"])),
    (r"jalón de pie con cuerda", (["Dorsal ancho"], ["Redondo mayor", "Tríceps braquial"])),
    (r"patada de tríceps", TRICEPS),
    (r"fondos de tríceps|press jm|press diamante", DIPS),
    (r"abdominal completo y press", (["Recto abdominal"], ["Oblicuos", "Deltoides anterior"])),
    (r"press abdominal", (["Recto abdominal"], ["Oblicuos"])),
    (r"press pallof", (["Oblicuos", "Transverso abdominal"], ["Recto abdominal"])),
    (r"plancha (con extensión de pierna|frontal con elevación)", PLANK),
    (r"rotación de tronco en máquina|elevación de tronco con rotación", (["Oblicuos"], ["Recto abdominal"])),
    (r"superman", (["Erectores espinales"], ["Glúteo mayor"])),
    (r"giro de cadera 90/90", (["Glúteo medio", "Glúteo mayor"], ["Flexores de cadera"])),
    (r"rotación interna de hombro", (["Manguito rotador"], [])),
    (r"extensión cervical", (["Trapecio superior"], ["Elevador de la escápula"])),
    (r"full planche|planche en rana", (["Deltoides anterior", "Pectoral mayor"], ["Recto abdominal", "Tríceps braquial"])),
]


def sections():
    lines = (MIGRATIONS / "V2__seed_catalog.sql").read_text(encoding="utf-8").splitlines()
    out, current = {}, None
    for line in lines:
        if line.startswith("INSERT INTO"):
            current = line.split()[2]
            out.setdefault(current, [])
        elif current:
            out[current].append(line)
    return out


def main():
    t = sections()
    muscles = {}
    for line in t["musculos"]:
        m = re.match(r"\s*\((\d+), '([^']*)'", line)
        if m:
            muscles[m.group(1)] = m.group(2)
    names = {}
    for line in t["ejercicios"]:
        m = re.match(r"\s*\('([0-9a-f-]{36})', '((?:[^']|'')*)'", line)
        if m:
            names[m.group(1)] = m.group(2).replace("''", "'")
    v700 = (MIGRATIONS / "V700__training_exercise_names_es.sql").read_text(encoding="utf-8")
    for new, eid in re.findall(r"SET nombre = '((?:[^']|'')*)', actualizado_en = now\(\) WHERE id = '([^']+)'", v700):
        names[eid] = new.replace("''", "'")

    def relation(table):
        out = {}
        for line in t[table]:
            m = re.match(r"\s*\('([0-9a-f-]{36})', (\d+)\)", line)
            if m:
                out.setdefault(m.group(1), []).append(muscles[m.group(2)])
        return out

    target, secondary = relation("ejercicio_musculo_objetivo"), relation("ejercicio_musculo_secundario")
    known = set(muscles.values())
    fixes = []
    for eid, name in sorted(names.items(), key=lambda x: x[1]):
        current = (sorted(target.get(eid, [])), sorted(secondary.get(eid, [])))
        if not any(current == (sorted(a), sorted(b)) for a, b in DEFAULTS):
            continue
        lowered = name.lower()
        for pattern, (main_muscles, extra) in RULES:
            if re.search(pattern, lowered):
                # El juego por defecto de abdomen acierta en los ejercicios de abdomen: solo se corrige si la regla
                # lleva el ejercicio a otra parte del cuerpo.
                core_ok = current == (sorted(CORE_DEFAULT[0]), sorted(CORE_DEFAULT[1])) and set(main_muscles) <= CORE_MUSCLES
                if not core_ok and (sorted(main_muscles), sorted(extra)) != current:
                    for muscle in main_muscles + extra:
                        assert muscle in known, f"Músculo que no está en el catálogo: {muscle}"
                    fixes.append((eid, name, main_muscles, extra))
                break

    def q(text):
        return "'" + text.replace("'", "''") + "'"

    ids = ",\n".join(f"({q(eid)}::uuid)" for eid, *_ in fixes)
    main_rows = ",\n".join(f"({q(eid)}::uuid, {q(m)})" for eid, _, ms, _ in fixes for m in ms)
    extra_rows = ",\n".join(f"({q(eid)}::uuid, {q(m)})" for eid, _, _, xs in fixes for m in xs)
    listing = "\n".join(f"--   {name}: {', '.join(ms)} (+ {', '.join(xs) or '—'})" for _, name, ms, xs in fixes)
    out = [
        "-- Músculos mal etiquetados del catálogo (ADR 0054), generado por tools/exercises/build_muscle_fix_migration.py;",
        "-- no editar a mano. Solo ejercicios sembrados con un juego de músculos por defecto que no les corresponde.",
        f"-- {len(fixes)} ejercicios:",
        listing,
        "",
        "CREATE TEMPORARY TABLE musculos_corregidos (ejercicio_id uuid PRIMARY KEY) ON COMMIT DROP;",
        "INSERT INTO musculos_corregidos (ejercicio_id)",
        "SELECT v.id FROM (VALUES",
        ids,
        ") AS v(id) JOIN ejercicios e ON e.id = v.id;",
        "",
        "DELETE FROM ejercicio_musculo_objetivo WHERE ejercicio_id IN (SELECT ejercicio_id FROM musculos_corregidos);",
        "DELETE FROM ejercicio_musculo_secundario WHERE ejercicio_id IN (SELECT ejercicio_id FROM musculos_corregidos);",
        "",
        "INSERT INTO ejercicio_musculo_objetivo (ejercicio_id, musculo_id)",
        "SELECT DISTINCT v.ejercicio_id, m.id FROM (VALUES",
        main_rows,
        ") AS v(ejercicio_id, nombre)",
        "JOIN musculos_corregidos c ON c.ejercicio_id = v.ejercicio_id",
        "JOIN musculos m ON m.nombre = v.nombre;",
        "",
    ]
    if extra_rows:
        out += [
            "INSERT INTO ejercicio_musculo_secundario (ejercicio_id, musculo_id)",
            "SELECT DISTINCT v.ejercicio_id, m.id FROM (VALUES",
            extra_rows,
            ") AS v(ejercicio_id, nombre)",
            "JOIN musculos_corregidos c ON c.ejercicio_id = v.ejercicio_id",
            "JOIN musculos m ON m.nombre = v.nombre;",
            "",
        ]
    TARGET.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{TARGET.name}: {len(fixes)} ejercicios corregidos")


if __name__ == "__main__":
    main()
