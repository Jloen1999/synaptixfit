"""Genera V930__training_exercise_names_i18n.sql con los nombres de los ejercicios y del vocabulario
(músculos, material y partes del cuerpo) en inglés, francés y portugués de Portugal.

Entrada: data/nombres_i18n.json y data/vocabulario_i18n.json (translate_names.py y fix_portuguese.py).
Una migración aplicada no se edita: si cambian los datos, se genera una nueva con otro número.

Uso (desde la raíz):  py -I tools/exercises/build_names_migration.py
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
DATA = HERE / "data"
ROOT = HERE.parent.parent
TARGET = ROOT / "backend/src/main/resources/db/migration/postgresql/V930__training_exercise_names_i18n.sql"
LANGS = ("en", "fr", "pt")
CHUNK = 500

# Términos que la IA no devolvió en lotes: traducidos a mano.
MANUAL_TERMS = {
    "Tibial anterior": {"en": "Tibialis anterior", "fr": "Tibial antérieur", "pt": "Tibial anterior"},
    "Tibial posterior": {"en": "Tibialis posterior", "fr": "Tibial postérieur", "pt": "Tibial posterior"},
    "Tríceps": {"en": "Triceps", "fr": "Triceps", "pt": "Tríceps"},
    "Trineo": {"en": "Sled", "fr": "Traîneau", "pt": "Trenó"},
    "Tren superior": {"en": "Upper body", "fr": "Haut du corps", "pt": "Parte superior do corpo"},
}


def q(text):
    return "'" + text.replace("'", "''") + "'"


def main():
    names = json.loads((DATA / "nombres_i18n.json").read_text(encoding="utf-8"))
    vocab = json.loads((DATA / "vocabulario_i18n.json").read_text(encoding="utf-8"))
    vocab.update({k: v for k, v in MANUAL_TERMS.items() if k not in vocab})
    out = [
        "-- Nombres del catálogo de entrenamiento en inglés, francés y portugués de Portugal (generado por",
        "-- tools/exercises/build_names_migration.py; no editar a mano). Fuentes: tools/exercises/data/FUENTES.md.",
        "-- El español sigue siendo el canónico (ejercicios.nombre y las tablas de vocabulario): las reglas",
        "-- usan ese; estas tablas solo cambian lo que se muestra según el idioma de la app (ADR 0017).",
        "CREATE TABLE ejercicio_nombres (",
        "    ejercicio_id UUID NOT NULL REFERENCES ejercicios (id) ON DELETE CASCADE,",
        "    idioma VARCHAR(5) NOT NULL,",
        "    nombre VARCHAR(255) NOT NULL,",
        "    PRIMARY KEY (ejercicio_id, idioma)",
        ");",
        "",
        "-- Músculos, material y partes del cuerpo, por su nombre en español.",
        "CREATE TABLE vocabulario_nombres (",
        "    termino VARCHAR(120) NOT NULL,",
        "    idioma VARCHAR(5) NOT NULL,",
        "    nombre VARCHAR(160) NOT NULL,",
        "    PRIMARY KEY (termino, idioma)",
        ");",
        "",
    ]
    rows = [(eid, lang, names[eid][lang][:255]) for eid in sorted(names) for lang in LANGS if names[eid].get(lang)]
    for i in range(0, len(rows), CHUNK):
        values = ",\n".join(f"({q(e)}, {q(l)}, {q(n)})" for e, l, n in rows[i:i + CHUNK])
        out.append("INSERT INTO ejercicio_nombres (ejercicio_id, idioma, nombre)\n"
                   "SELECT CAST(v.e AS uuid), v.l, v.n FROM (VALUES\n" + values + "\n) AS v (e, l, n)\n"
                   "WHERE EXISTS (SELECT 1 FROM ejercicios x WHERE x.id = CAST(v.e AS uuid));\n")
    terms = [(t, lang, vocab[t][lang][:160]) for t in sorted(vocab) for lang in LANGS if vocab[t].get(lang)]
    values = ",\n".join(f"({q(t)}, {q(l)}, {q(n)})" for t, l, n in terms)
    out.append("INSERT INTO vocabulario_nombres (termino, idioma, nombre) VALUES\n" + values + ";\n")
    TARGET.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{TARGET.name}: {len(rows)} nombres de ejercicios y {len(terms)} términos")


if __name__ == "__main__":
    main()
