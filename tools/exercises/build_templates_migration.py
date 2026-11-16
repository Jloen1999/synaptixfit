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
  - «3»: data/plantillas_rutina_3.json → V1073 (fase 3A, ADR 0054): retira las 24 anteriores (activa = false, las
    rutinas ya creadas no cambian) y crea las 12 nuevas con nombre de sesión por día, rango de repeticiones y
    cuántas deben sobrar, salidas a correr por semana (Couch to 5K) y el perfil de carga de cada ejercicio
    (cargas_iniciales_ejercicio: tipo de carga, fracción del peso corporal, kg por defecto, tope y tren inferior).

Uso (desde la raíz):  py -I tools/exercises/build_templates_migration.py [1|2|3]
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
RUN_CODES = {"START_WALK_RUN", "EASY_30", "INTERVALS_6X800", "PACE_CHANGES", "STEADY_20", "LONG_RUN",
             "C25K_W1", "C25K_W2", "C25K_W3", "C25K_W4", "C25K_W5_1", "C25K_W5_2", "C25K_W5_3", "C25K_W6_1",
             "C25K_W6_2", "C25K_W6_3", "C25K_W7", "C25K_W8", "C25K_W9"}
LOAD_TYPES = {"BARBELL", "DUMBBELL_PAIR", "DUMBBELL_SINGLE", "KETTLEBELL", "MACHINE", "CABLE", "BODYWEIGHT", "BAND"}


def q(text):
    return "'" + text.replace("'", "''") + "'"


def sql_num(value):
    return "NULL" if value is None else str(value)


def catalog_ids():
    catalog = {}
    for item in json.loads(CATALOG.read_text(encoding="utf-8")):
        catalog.setdefault(item["nombre"].lower(), item["id"])

    def exercise_id(name):
        found = catalog.get(name.lower())
        assert found, f"Ejercicio que no está en el catálogo: {name}"
        return found
    return exercise_id


def build_real():
    """Tanda 3 (ADR 0054): plantillas reales con nombres de sesión, rangos y perfiles de carga."""
    source = HERE / "data" / "plantillas_rutina_3.json"
    target = MIGRATIONS / "V1073__training_real_templates_data.sql"
    data = json.loads(source.read_text(encoding="utf-8"))
    exercise_id = catalog_ids()
    templates, texts, day_texts, exercises, runs = [], [], [], [], []
    for order, t in enumerate(data["plantillas"]):
        code = t["codigo"]
        tid = str(uuid.uuid5(NAMESPACE, code))
        home = "true" if t["lugar"] == "HOME" else "false"
        exams = "true" if t["examenes"] else "false"
        templates.append(f"({q(tid)}::uuid, {q(code)}, {q(t['objetivo'])}, {home}, {exams}, {t['minutos']}, "
                         f"{t['semanas']}, {order}, {q(t['lugar'])}, {q(t['nivel'])}, true)")
        for lang in LANGS:
            name, description = t[lang]
            assert len(name) <= 80 and len(description) <= 500, (code, lang)
            texts.append(f"({q(tid)}::uuid, {q(lang)}, {q(name)}, {q(description)})")
        strength_days = {day for day, _, _ in t["dias"]}
        for day, session, day_name in t["dias"]:
            names = {"es": day_name, **data["nombres_dia"][day_name]}
            for lang in LANGS:
                day_texts.append(f"({q(tid)}::uuid, {day}, {q(lang)}, {q(names[lang])})")
            for position, row in enumerate(data["sesiones"][session], start=1):
                name, sets, rep_min, rep_max, rest, reserve = row[:6]
                hold = row[6] if len(row) > 6 else None
                ranged = hold is None and (rep_min != rep_max or reserve is not None)
                low = rep_min if ranged else "NULL"
                high = rep_max if ranged else "NULL"
                rir = sql_num(reserve) if ranged else "NULL"
                exercises.append(f"({q(tid)}::uuid, {day}, {position}, {q(exercise_id(name))}::uuid, {sets}, "
                                 f"{1 if hold else rep_min}, {rest}, {sql_num(hold)}, {low}, {high}, {rir})")
        for week, day, run_code in t.get("carreras", []):
            assert run_code in RUN_CODES, f"Entreno de carrera desconocido: {run_code}"
            assert day not in strength_days, f"{code}: el día {day} ya es de fuerza"
            assert 1 <= week <= t["semanas"], f"{code}: semana {week} fuera del plan"
            runs.append(f"({q(tid)}::uuid, {week}, {day}, {q(run_code)})")
    names = [f"({q(run)}, {q(lang)}, {q(by_lang[lang])})"
             for run, by_lang in sorted(data["nombres_carrera"].items()) for lang in LANGS]
    loads = []
    for name, kind, fraction, default_kg, cap_kg, lower in data["cargas"]:
        assert kind in LOAD_TYPES, kind
        loads.append(f"({q(exercise_id(name))}::uuid, {q(kind)}, {sql_num(fraction)}, {sql_num(default_kg)}, "
                     f"{sql_num(cap_kg)}, {'true' if lower else 'false'})")
    retired = ", ".join(q(code) for code in data["retirar"])
    out = [
        "-- Plantillas reales (ADR 0054), generado por tools/exercises/build_templates_migration.py 3",
        f"-- desde tools/exercises/data/{source.name}; no editar a mano.",
        "",
        "-- Las 24 plantillas anteriores dejan de ofrecerse; las rutinas creadas con ellas son copias y no cambian.",
        f"UPDATE plantillas_rutina SET activa = false WHERE codigo IN ({retired});",
        "",
        "INSERT INTO plantillas_rutina (id, codigo, objetivo, en_casa, para_examenes, minutos, semanas, orden, lugar, nivel,",
        "                               activa)",
        "VALUES",
        ",\n".join(templates) + ";",
        "",
        "INSERT INTO plantillas_rutina_textos (plantilla_id, idioma, nombre, descripcion)",
        "VALUES",
        ",\n".join(texts) + ";",
        "",
        "-- Nombre de cada sesión, por idioma.",
        "INSERT INTO plantillas_rutina_dias_textos (plantilla_id, dia, idioma, nombre)",
        "VALUES",
        ",\n".join(day_texts) + ";",
        "",
        "-- Solo los ejercicios que existen en esta base de datos. «repeticiones» es el mínimo del rango.",
        "INSERT INTO plantillas_rutina_ejercicios (plantilla_id, dia, orden, ejercicio_id, series, repeticiones,",
        "                                          descanso_segundos, segundos_isometricos, rep_min, rep_max, rir_objetivo)",
        "SELECT v.plantilla_id, v.dia, v.orden, v.ejercicio_id, v.series, v.repeticiones, v.descanso_segundos,",
        "       v.segundos_isometricos, v.rep_min, v.rep_max, v.rir_objetivo",
        "FROM (VALUES",
        ",\n".join(exercises),
        ") AS v(plantilla_id, dia, orden, ejercicio_id, series, repeticiones, descanso_segundos, segundos_isometricos,",
        "       rep_min, rep_max, rir_objetivo)",
        "JOIN ejercicios e ON e.id = v.ejercicio_id;",
        "",
        "-- Salidas a correr de «Empieza a correr»: una por semana y día (Couch to 5K del NHS, 9 semanas).",
        "INSERT INTO plantillas_rutina_carreras (plantilla_id, semana, dia, codigo_entreno)",
        "VALUES",
        ",\n".join(runs) + ";",
        "",
        "-- Nombre de cada salida, en el idioma de la persona (el entreno creado se llama así).",
        "INSERT INTO nombres_entreno_carrera (codigo, idioma, nombre)",
        "VALUES",
        ",\n".join(names) + ";",
        "",
        "-- Cómo se carga cada ejercicio y su peso de partida (solo los que existen en esta base de datos).",
        "INSERT INTO cargas_iniciales_ejercicio (ejercicio_id, tipo_carga, fraccion_peso_corporal, kg_defecto, kg_tope,",
        "                                        tren_inferior)",
        "SELECT v.ejercicio_id, v.tipo_carga, v.fraccion, v.kg_defecto, v.kg_tope, v.tren_inferior",
        "FROM (VALUES",
        ",\n".join(loads),
        ") AS v(ejercicio_id, tipo_carga, fraccion, kg_defecto, kg_tope, tren_inferior)",
        "JOIN ejercicios e ON e.id = v.ejercicio_id;",
        "",
    ]
    target.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{target.name}: {len(templates)} plantillas, {len(exercises)} ejercicios, {len(runs)} salidas, "
          f"{len(loads)} perfiles de carga")


def main():
    batch = sys.argv[1] if len(sys.argv) > 1 else "1"
    if batch == "3":
        build_real()
        return
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
