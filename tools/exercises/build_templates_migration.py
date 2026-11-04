"""Genera V1035__training_routine_templates_data.sql con las plantillas de rutina listas para usar.

Entrada: data/plantillas_rutina.json (sesiones con nombres del catálogo en español y plantillas con sus
textos en es, en, fr y pt) y data/ejercicios_bd.json (catálogo con ids fijos). Cada ejercicio se busca por
su nombre exacto; si falta, el script falla para no publicar una plantilla incompleta. La migración solo
inserta las filas cuyo ejercicio existe en la base de datos (las bases de pruebas sin catálogo quedan con
las plantillas sin ejercicios).
Una migración aplicada no se edita: si cambian los datos, se genera otra con otro número.

Uso (desde la raíz):  py -I tools/exercises/build_templates_migration.py
"""
import json
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SOURCE = HERE / "data" / "plantillas_rutina.json"
CATALOG = HERE / "data" / "ejercicios_bd.json"
TARGET = ROOT / "backend/src/main/resources/db/migration/postgresql/V1035__training_routine_templates_data.sql"
LANGS = ("es", "en", "fr", "pt")
NAMESPACE = uuid.UUID("6f1d3c52-8a0e-4c1b-9d7e-3a5b2c4d6e7f")


def q(text):
    return "'" + text.replace("'", "''") + "'"


def main():
    data = json.loads(SOURCE.read_text(encoding="utf-8"))
    catalog = {}
    for item in json.loads(CATALOG.read_text(encoding="utf-8")):
        catalog.setdefault(item["nombre"].lower(), item["id"])

    def exercise_id(name):
        found = catalog.get(name.lower())
        assert found, f"Ejercicio que no está en el catálogo: {name}"
        return found

    templates, texts, exercises = [], [], []
    for order, t in enumerate(data["plantillas"]):
        tid = str(uuid.uuid5(NAMESPACE, t["codigo"]))
        templates.append(f"({q(tid)}::uuid, {q(t['codigo'])}, {q(t['objetivo'])}, "
                         f"{'true' if t['en_casa'] else 'false'}, {'true' if t['examenes'] else 'false'}, "
                         f"{t['minutos']}, {t['semanas']}, {order})")
        for lang in LANGS:
            name, description = t[lang]
            texts.append(f"({q(tid)}::uuid, {q(lang)}, {q(name)}, {q(description)})")
        for day, session in t["dias"]:
            for position, row in enumerate(data["sesiones"][session], start=1):
                name, sets, reps, rest = row[:4]
                hold = row[4] if len(row) > 4 else None
                exercises.append(f"({q(tid)}::uuid, {day}, {position}, {q(exercise_id(name))}::uuid, {sets}, "
                                 f"{reps}, {rest}, {'NULL' if hold is None else hold})")

    out = [
        "-- Plantillas de rutina listas para usar, generado por tools/exercises/build_templates_migration.py",
        "-- desde tools/exercises/data/plantillas_rutina.json; no editar a mano.",
        "INSERT INTO plantillas_rutina (id, codigo, objetivo, en_casa, para_examenes, minutos, semanas, orden)",
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
    TARGET.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{TARGET.name}: {len(templates)} plantillas, {len(exercises)} ejercicios")


if __name__ == "__main__":
    main()
