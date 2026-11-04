"""Genera V1033__training_exercise_tips.sql con «Las claves» y «Errores comunes» de los ejercicios
(ADR 0031) en español, inglés, francés y portugués de Portugal.

Entrada: data/consejos_ejercicios.json. Cada familia de movimiento (press de banca, sentadilla, remo…)
lleva un patrón sobre el nombre en español del catálogo y otro de exclusión para las variantes en las que
sus consejos no valdrían (p. ej. «Remo al mentón» no es un remo). La migración asigna los consejos a los
ejercicios que encajan en el momento de aplicarla; un ejercicio solo recibe los de una familia.
Una migración aplicada no se edita: si cambian los datos, se genera una nueva con otro número.

Uso (desde la raíz):  py -I tools/exercises/build_tips_migration.py
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SOURCE = HERE / "data" / "consejos_ejercicios.json"
TARGET = ROOT / "backend/src/main/resources/db/migration/postgresql/V1033__training_exercise_tips.sql"
LANGS = ("es", "en", "fr", "pt")


def q(text):
    return "'" + text.replace("'", "''") + "'"


def array(lines):
    return "ARRAY[" + ", ".join(q(line) for line in lines) + "]::text[]"


def main():
    families = json.loads(SOURCE.read_text(encoding="utf-8"))
    rows = []
    for order, family in enumerate(families):
        for lang in LANGS:
            texts = family[lang]
            assert len(texts["claves"]) >= 2 and len(texts["errores"]) >= 2, family["familia"]
            exclude = "NULL" if family["excluir"] is None else q(family["excluir"])
            rows.append(f"({order}, {q(family['familia'])}, {q(family['patron'])}, {exclude}, {q(lang)}, "
                        f"{array(texts['claves'])}, {array(texts['errores'])})")
    out = [
        "-- «Las claves» y «Errores comunes» por familia de movimiento (ADR 0031), generado por",
        "-- tools/exercises/build_tips_migration.py desde tools/exercises/data/consejos_ejercicios.json; no editar a mano.",
        "-- Se asignan a los ejercicios cuyo nombre en español encaja con el patrón de la familia y no con su",
        "-- exclusión. Si un ejercicio encajara en dos familias, se queda con la primera de la lista.",
        "-- ~* y !~* (expresiones regulares sin distinguir mayúsculas) son propios de PostgreSQL",
        "-- (docs/06-ops/database_portability.md).",
        "INSERT INTO consejos_ejercicio (ejercicio_id, idioma, claves, errores)",
        "SELECT DISTINCT ON (e.id, f.idioma) e.id, f.idioma, f.claves, f.errores",
        "FROM ejercicios e",
        "JOIN (VALUES",
        ",\n".join(rows),
        ") AS f(orden, familia, patron, excluir, idioma, claves, errores)",
        "  ON e.nombre ~* f.patron AND (f.excluir IS NULL OR e.nombre !~* f.excluir)",
        "ORDER BY e.id, f.idioma, f.orden;",
        "",
    ]
    TARGET.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{TARGET.name}: {len(families)} familias, {len(rows)} filas")


if __name__ == "__main__":
    main()
