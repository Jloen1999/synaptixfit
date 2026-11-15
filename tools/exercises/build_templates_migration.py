"""Genera las migraciones con las plantillas de rutina listas para usar.

Entrada: un JSON de data/ (sesiones con nombres del catálogo en español y plantillas con sus textos en es, en,
fr y pt) y data/ejercicios_bd.json (catálogo con ids fijos). Cada ejercicio se busca por su nombre exacto; si
falta, el script falla para no publicar una plantilla incompleta. La migración solo inserta las filas cuyo
ejercicio existe en la base de datos (las bases de pruebas sin catálogo quedan con las plantillas sin ejercicios).
Una migración aplicada no se edita: si cambian los datos, se genera otra con otro número.

Tandas:
  - «1»: data/plantillas_rutina.json → V1035 (10 plantillas, ADR 0032).
  - «2»: data/plantillas_rutina_2.json → V1061 (14 plantillas con lugar, nivel y días de carrera, ADR 0043).
    Los días de carrera apuntan a un código de RunWorkoutTemplates; su nombre por idioma va en
    «nombres_carrera» (el mismo texto que la app, para que el entreno creado se llame igual).

Uso (desde la raíz):  py -I tools/exercises/build_templates_migration.py [1|2]
"""
import json
import sys
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
MIGRATIONS = ROOT / "backend/src/main/resources/db/migration/postgresql"
BATCHES = {
    "1": (HERE / "data" / "plantillas_rutina.json", MIGRATIONS / "V1035__training_routine_templates_data.sql", 0),
    "2": (HERE / "data" / "plantillas_rutina_2.json", MIGRATIONS / "V1061__training_routine_templates_more_data.sql",
          10),
}
CATALOG = HERE / "data" / "ejercicios_bd.json"
LANGS = ("es", "en", "fr", "pt")
NAMESPACE = uuid.UUID("6f1d3c52-8a0e-4c1b-9d7e-3a5b2c4d6e7f")
RUN_CODES = {"START_WALK_RUN", "EASY_30", "INTERVALS_6X800", "PACE_CHANGES", "STEADY_20", "LONG_RUN"}


def q(text):
    return "'" + text.replace("'", "''") + "'"


def main():
    batch = sys.argv[1] if len(sys.argv) > 1 else "1"
    source, target, order_offset = BATCHES[batch]
    data = json.loads(source.read_text(encoding="utf-8"))
    catalog = {}
    for item in json.loads(CATALOG.read_text(encoding="utf-8")):
        catalog.setdefault(item["nombre"].lower(), item["id"])

    def exercise_id(name):
        found = catalog.get(name.lower())
        assert found, f"Ejercicio que no está en el catálogo: {name}"
        return found

    extended = batch != "1"
    templates, texts, exercises, runs = [], [], [], []
    for order, t in enumerate(data["plantillas"], start=order_offset):
        tid = str(uuid.uuid5(NAMESPACE, t["codigo"]))
        head = (f"({q(tid)}::uuid, {q(t['codigo'])}, {q(t['objetivo'])}, "
                f"{'true' if t['en_casa'] else 'false'}, {'true' if t['examenes'] else 'false'}, "
                f"{t['minutos']}, {t['semanas']}, {order}")
        if extended:
            head += f", {q(t['lugar'])}, {q(t['nivel'])}"
        templates.append(head + ")")
        for lang in LANGS:
            name, description = t[lang]
            texts.append(f"({q(tid)}::uuid, {q(lang)}, {q(name)}, {q(description)})")
        strength_days = {day for day, _ in t["dias"]}
        for day, session in t["dias"]:
            for position, row in enumerate(data["sesiones"][session], start=1):
                name, sets, reps, rest = row[:4]
                hold = row[4] if len(row) > 4 else None
                exercises.append(f"({q(tid)}::uuid, {day}, {position}, {q(exercise_id(name))}::uuid, {sets}, "
                                 f"{reps}, {rest}, {'NULL' if hold is None else hold})")
        for day, code in t.get("carreras", []):
            assert code in RUN_CODES, f"Entreno de carrera desconocido: {code}"
            assert day not in strength_days, f"{t['codigo']}: el día {day} ya es de fuerza"
            runs.append(f"({q(tid)}::uuid, {day}, {q(code)})")

    columns = "id, codigo, objetivo, en_casa, para_examenes, minutos, semanas, orden"
    if extended:
        columns += ", lugar, nivel"
    out = [
        "-- Plantillas de rutina listas para usar, generado por tools/exercises/build_templates_migration.py",
        f"-- desde tools/exercises/data/{source.name}; no editar a mano.",
        f"INSERT INTO plantillas_rutina ({columns})",
        "VALUES",
        ",\n".join(templates) + ";",
        "",
        "INSERT INTO plantillas_rutina_textos (plantilla_id, idioma, nombre, descripcion)",
        "VALUES",
        ",\n".join(texts) + ";",
        "",
        "-- Solo los ejercicios que existen en esta base de datos.",
        "INSERT INTO plantillas_rutina_ejercicios (plantilla_id, dia, orden, ejercicio_id, series, repeticiones,",
        "                                          descanso_segundos, segundos_isometricos)",
        "SELECT v.plantilla_id, v.dia, v.orden, v.ejercicio_id, v.series, v.repeticiones, v.descanso_segundos,",
        "       v.segundos_isometricos",
        "FROM (VALUES",
        ",\n".join(exercises),
        ") AS v(plantilla_id, dia, orden, ejercicio_id, series, repeticiones, descanso_segundos, segundos_isometricos)",
        "JOIN ejercicios e ON e.id = v.ejercicio_id;",
        "",
    ]
    if runs:
        out += [
            "-- Días de carrera: se hacen en Entreno › Correr con el entreno de ese código.",
            "INSERT INTO plantillas_rutina_carreras (plantilla_id, dia, codigo_entreno)",
            "VALUES",
            ",\n".join(runs) + ";",
            "",
        ]
    names = data.get("nombres_carrera", {})
    if names:
        rows = [f"({q(code)}, {q(lang)}, {q(by_lang[lang])})"
                for code, by_lang in sorted(names.items()) for lang in LANGS]
        out += [
            "-- Nombre del entreno de carrera que crea una plantilla, en el idioma de la persona (como en la app).",
            "INSERT INTO nombres_entreno_carrera (codigo, idioma, nombre)",
            "VALUES",
            ",\n".join(rows) + ";",
            "",
        ]
    target.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{target.name}: {len(templates)} plantillas, {len(exercises)} ejercicios, {len(runs)} días de carrera")


if __name__ == "__main__":
    main()
