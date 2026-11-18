"""Escribe V1077: fotos y vídeos nuevos de los ejercicios y su crédito (fuente, licencia, autor), ADR 0056.

Lee data/imagenes_ejercicios.json después de upload_exercise_media.py (necesita la `url` de cada archivo).
- Solo rellena lo que está vacío: un ejercicio que ya tiene foto o vídeo (o que la administración cambió) no se toca.
- El crédito solo se guarda si la URL quedó puesta (así no se atribuye una foto que no se ve).
- SQL estándar (ADR 0012): sin ON CONFLICT; se evita el duplicado con NOT EXISTS.
- No sobrescribe una migración que ya existe (Flyway no arrancaría si cambia una aplicada): para añadir medios más
  adelante, se genera otra con la versión siguiente.

    py -I tools/exercises/build_media_migration.py                 # V1077 (solo si aún no existe)
    py -I tools/exercises/build_media_migration.py V1090 nombre     # una migración nueva
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = Path(__file__).resolve().parent / "data"
MIGRATIONS = ROOT / "backend/src/main/resources/db/migration/postgresql"
KINDS = {"foto": ("FOTO", "url_preview"), "video": ("VIDEO", "url_gif")}


def q(value):
    return "NULL" if value is None else "'" + str(value).replace("'", "''") + "'"


def main():
    version, name = (sys.argv[1], sys.argv[2]) if len(sys.argv) > 2 else ("V1077", "exercise_media_credits")
    out = MIGRATIONS / f"{version}__training_{name}.sql"
    if out.exists():
        raise SystemExit(f"{out.name} ya existe: una migración aplicada no se cambia. Genera otra con la versión "
                         "siguiente (py -I tools/exercises/build_media_migration.py V<n> <nombre>).")
    data = json.loads((DATA / "imagenes_ejercicios.json").read_text(encoding="utf-8"))["ejercicios"]
    lines = [
        "-- Fotos y vídeos nuevos de los ejercicios del catálogo que no tenían ninguno, con su crédito (ADR 0056).",
        "-- Generado por tools/exercises/build_media_migration.py desde tools/exercises/data/imagenes_ejercicios.json.",
        "-- Fuentes: wger (cada imagen o vídeo con su licencia y su autor) y free-exercise-db (Unlicense). Para retirar",
        "-- una fuente entera: vaciar url_preview/url_gif de los ejercicios con crédito de esa fuente y borrar sus filas.",
    ]
    # La tabla la crea V1077; una migración posterior solo añade medios.
    if version == "V1077":
        lines += [
        "CREATE TABLE creditos_medios_ejercicio (",
        "    ejercicio_id uuid NOT NULL REFERENCES ejercicios (id) ON DELETE CASCADE,",
        "    tipo varchar(10) NOT NULL CHECK (tipo IN ('FOTO', 'VIDEO')),",
        "    fuente varchar(40) NOT NULL,",
        "    licencia varchar(40) NOT NULL,",
        "    licencia_url varchar(200) NOT NULL,",
        "    autor varchar(160),",
        "    obra_url varchar(300),",
        "    PRIMARY KEY (ejercicio_id, tipo)",
        ");",
        "",
        ]
    count = {"FOTO": 0, "VIDEO": 0}
    for eid, entry in sorted(data.items()):
        for kind, (tipo, column) in KINDS.items():
            media = entry.get(kind)
            if not media:
                continue
            if not media.get("url"):
                raise SystemExit(f"Falta la URL subida de {eid} ({kind}): ejecuta antes upload_exercise_media.py")
            url = q(media["url"])
            lines.append(f"-- {entry['nombre']}")
            lines.append(f"UPDATE ejercicios SET {column} = {url} WHERE id = '{eid}' AND {column} IS NULL;")
            lines.append(
                "INSERT INTO creditos_medios_ejercicio (ejercicio_id, tipo, fuente, licencia, licencia_url, autor, "
                f"obra_url) SELECT id, '{tipo}', {q(media['fuente'])}, {q(media['licencia'])}, "
                f"{q(media['licencia_url'])}, {q(media['autor'])}, {q(media['obra_url'])} FROM ejercicios "
                f"WHERE id = '{eid}' AND {column} = {url} AND NOT EXISTS (SELECT 1 FROM creditos_medios_ejercicio c "
                f"WHERE c.ejercicio_id = '{eid}' AND c.tipo = '{tipo}');")
            count[tipo] += 1
    out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(f"{out.name}: {count['FOTO']} fotos y {count['VIDEO']} vídeos")


if __name__ == "__main__":
    main()
