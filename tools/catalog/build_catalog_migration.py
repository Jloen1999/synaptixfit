"""Genera la migración Flyway que amplía el catálogo académico con datos oficiales.

Fuentes (ver data/FUENTES.md): universidades y grados del RUCT (Ministerio), asignaturas de
la Universidad de Extremadura y de la Universidad de Cantabria (datos abiertos).

Cruza los CSV con lo que ya sembró V2__seed_catalog.sql (identificadores fijos) para no
duplicar: lo que ya existe se completa (código oficial, rama…) y lo nuevo se inserta con
UUID deterministas (uuid5), así que volver a generar el archivo da el mismo resultado.

Uso (desde la raíz del repositorio):
    py -I tools/catalog/build_catalog_migration.py
"""
import csv
import re
import unicodedata
import uuid
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = Path(__file__).resolve().parent / "data"
MIGRATIONS = ROOT / "backend/src/main/resources/db/migration/postgresql"
V2 = MIGRATIONS / "V2__seed_catalog.sql"
OUT = MIGRATIONS / "V800__catalog_spain_universities_degrees.sql"
NS = uuid.UUID("5a6e2c1e-3b1f-4f7e-9d2a-8c0b7f6e4d21")

# Universidades del seed que son españolas → su código RUCT.
EXISTING_RUCT = {
    "acebdf1d-c914-4e5c-8282-3fd4643402e4": "008",  # Granada
    "506c5f63-f07d-43a0-9795-e0aea1a8e12e": "029",  # Alcalá
    "07026440-07cf-4cff-99b3-701576eb66e3": "044",  # Lleida
    "65c87bc5-d68c-4c05-b29b-e08eb7e135c7": "064",  # Politécnica de Cartagena
    "9c4beece-a781-4bb4-b067-b31e4394a1c5": "002",  # Extremadura
}
# UTEC (Uruguay) estaba dos veces: se queda la primera y se le pasan los centros de la otra.
UTEC_KEEP = "01e67399-ef12-4f0a-9441-fa8114dfa70d"
UTEC_DROP = "1c61e330-71f9-4052-8155-0a41a01297c4"
UTEC_NAME = "Universidad Tecnológica del Uruguay (UTEC)"
# Universidades con asignaturas en datos abiertos → su CSV.
SUBJECT_SOURCES = {"002": "asignaturas_uex.csv", "016": "asignaturas_uc.csv"}
GENERIC_CENTER = "Varios centros"
# La Universidad de Cantabria publica los centros sin tildes.
ACCENTS = {
    "Economicas": "Económicas", "Tecnica": "Técnica", "Tecnico": "Técnico", "Telecomunicacion": "Telecomunicación",
    "Politecnica": "Politécnica", "Educacion": "Educación", "Ingenieria": "Ingeniería", "Energia": "Energía",
    "Nautica": "Náutica", "Enfermeria": "Enfermería", "Filosofia": "Filosofía", "Maritima": "Marítima",
    "Fisica": "Física", "Quimica": "Química", "Matematicas": "Matemáticas", "Geografia": "Geografía",
    "Psicologia": "Psicología", "Comunicacion": "Comunicación", "Informatica": "Informática",
    "Gestion": "Gestión", "Administracion": "Administración", "Tecnologia": "Tecnología",
}
ROMAN = re.compile(r"^(?=[IVXLC]+$)M*(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$")


def norm(text):
    """Clave para comparar nombres: sin tildes, minúsculas, sin «Grado en» ni signos."""
    t = unicodedata.normalize("NFD", text or "")
    t = "".join(c for c in t if unicodedata.category(c) != "Mn").lower()
    t = re.sub(r"\(.*?\)", " ", t)
    t = re.sub(r"^\s*(grado|graduado|graduada)\s+(en|de)\s+", "", t)
    t = re.sub(r"[^a-z0-9]+", " ", t)
    return t.strip()


def sentence(text):
    """«GEOTECNIA DE OBRAS II» → «Geotecnia de obras II»; deja igual lo que ya no está en mayúsculas."""
    t = (text or "").strip()
    if not t or t != t.upper():
        return t
    words = t.lower().split(" ")
    out = []
    for i, w in enumerate(words):
        if ROMAN.match(w.upper()) and len(w) <= 4 and w not in ("di", "mi", "vi", "li", "ci", "dc"):
            out.append(w.upper())
        elif i == 0:
            out.append(w[:1].upper() + w[1:])
        else:
            out.append(w)
    return " ".join(out)


def fix_accents(text):
    return " ".join(ACCENTS.get(w, w) for w in (text or "").split(" "))


def q(value):
    if value is None or value == "":
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def num(value, kind=int):
    try:
        return str(kind(value)) if value not in (None, "") else "NULL"
    except ValueError:
        return "NULL"


def uid(*parts):
    return str(uuid.uuid5(NS, ":".join(parts)))


def v2_rows(table):
    """Filas de un INSERT de V2 como listas de valores (texto, sin comillas)."""
    src = V2.read_text(encoding="utf-8")
    m = re.search(r"INSERT INTO " + table + r" \(([^)]*)\) VALUES\n(.*?);\n", src, re.S)
    cols = [c.strip() for c in m.group(1).split(",")]
    body, rows, i = m.group(2), [], 0
    while True:
        i = body.find("\t(", i)
        if i < 0:
            return cols, rows
        i += 2
        vals, cur, inq, raw = [], "", False, False
        while True:
            c = body[i]
            if inq:
                if c == "'":
                    if body[i + 1] == "'":
                        cur += "'"
                        i += 2
                        continue
                    inq = False
                    i += 1
                    continue
                cur += c
                i += 1
                continue
            if c == "'":
                inq, raw = True, True
                i += 1
                continue
            if c in ",)":
                vals.append(cur.strip() if raw or cur.strip() != "NULL" else None)
                cur, raw = "", False
                i += 1
                if c == ")":
                    break
                continue
            cur += c
            i += 1
        rows.append(dict(zip(cols, vals)))


def read_csv(name):
    with open(DATA / name, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def main():
    _, centers_v2 = v2_rows("centros")
    _, degrees_v2 = v2_rows("carreras")
    _, subjects_v2 = v2_rows("asignaturas_catalogo")
    univ_of_center = {c["id"]: c["universidad_id"] for c in centers_v2}
    ruct_of_univ_id = dict(EXISTING_RUCT)
    univ_id_of_ruct = {v: k for k, v in ruct_of_univ_id.items()}

    universities = read_csv("universidades.csv")
    degrees = read_csv("grados.csv")
    out = []
    w = out.append
    w("-- Catálogo académico ampliado con datos oficiales (generado por tools/catalog/build_catalog_migration.py;")
    w("-- no editar a mano). Fuentes y licencias: tools/catalog/data/FUENTES.md.")
    w("-- Lo que ya sembró V2 se completa (código oficial, rama…) y no se duplica; lo nuevo lleva UUID fijos.\n")
    w("ALTER TABLE universidades ADD COLUMN codigo_ruct VARCHAR(10);")
    w("ALTER TABLE universidades ADD COLUMN tipo VARCHAR(10);")
    w("ALTER TABLE universidades ADD COLUMN comunidad VARCHAR(100);")
    w("ALTER TABLE universidades ADD COLUMN web VARCHAR(300);")
    w("CREATE UNIQUE INDEX ux_universidades_codigo_ruct ON universidades (codigo_ruct);")
    w("ALTER TABLE carreras ADD COLUMN codigo_ruct VARCHAR(10);")
    w("ALTER TABLE carreras ADD COLUMN rama VARCHAR(100);")
    w("ALTER TABLE asignaturas_catalogo ADD COLUMN codigo VARCHAR(20);")
    w("CREATE INDEX idx_asignaturas_catalogo_codigo ON asignaturas_catalogo (codigo);\n")

    w("-- UTEC (Uruguay) estaba repetida: una sola universidad con todos sus centros. Un centro que ya")
    w("-- existe en la que se queda (mismo nombre salvo el paréntesis) recibe las carreras del repetido.")
    kept_centers = {norm(c["nombre"]): c["id"] for c in centers_v2 if c["universidad_id"] == UTEC_KEEP}
    for c in centers_v2:
        if c["universidad_id"] != UTEC_DROP:
            continue
        twin = kept_centers.get(norm(c["nombre"]))
        if twin:
            w(f"UPDATE carreras SET centro_id = {q(twin)} WHERE centro_id = {q(c['id'])};")
            w(f"DELETE FROM centros WHERE id = {q(c['id'])};")
        else:
            w(f"UPDATE centros SET universidad_id = {q(UTEC_KEEP)} WHERE id = {q(c['id'])};")
    w(f"DELETE FROM universidades WHERE id = {q(UTEC_DROP)};")
    w(f"UPDATE universidades SET nombre = {q(UTEC_NAME)} WHERE id = {q(UTEC_KEEP)};\n")

    w("-- Universidades españolas (RUCT).")
    inserted_univ = 0
    for u in universities:
        code = u["codigo_ruct"]
        if code in univ_id_of_ruct:
            w(f"UPDATE universidades SET nombre = {q(u['nombre'])}, codigo_ruct = {q(code)}, tipo = {q(u['tipo'])}, "
              f"comunidad = {q(u['comunidad'])}, web = {q(u['web'])} WHERE id = {q(univ_id_of_ruct[code])};")
        else:
            univ_id_of_ruct[code] = uid("univ", code)
            inserted_univ += 1
            w("INSERT INTO universidades (id, nombre, codigo_ruct, tipo, comunidad, web) VALUES "
              f"({q(univ_id_of_ruct[code])}, {q(u['nombre'])}, {q(code)}, {q(u['tipo'])}, {q(u['comunidad'])}, "
              f"{q(u['web'])});")

    # Centros existentes por universidad (nombre normalizado → id) y carreras existentes.
    centers = defaultdict(dict)
    for c in centers_v2:
        univ = UTEC_KEEP if c["universidad_id"] == UTEC_DROP else c["universidad_id"]
        centers[univ][norm(c["nombre"])] = c["id"]
    existing_degrees = defaultdict(list)  # univ_id → [(norm nombre, centro_id, id)]
    for d in degrees_v2:
        existing_degrees[univ_of_center.get(d["centro_id"])].append((norm(d["nombre"]), d["centro_id"], d["id"]))
    new_centers = []

    def center_id(univ_id, ruct, name):
        key = norm(name)
        if key not in centers[univ_id]:
            centers[univ_id][key] = uid("center", ruct, key)
            new_centers.append((centers[univ_id][key], univ_id, name))
        return centers[univ_id][key]

    degree_rows, degree_updates = [], []
    degree_names = defaultdict(set)  # centro → nombres exactos ya usados
    for d in degrees_v2:
        degree_names[d["centro_id"]].add(d["nombre"])

    def unique_degree_name(cid, name, code):
        """Dos grados con el mismo nombre en el mismo centro se distinguen por su código."""
        final = name if name not in degree_names[cid] else f"{name} ({code})"
        degree_names[cid].add(final)
        return final
    degree_of_titulacion = {}  # (ruct univ, codigo_titulacion) → carrera id
    used_existing = set()

    def take_existing(univ_id, name, center=None):
        key = norm(name)
        for n, c, i in existing_degrees.get(univ_id, []):
            if n == key and i not in used_existing and (center is None or c == center):
                used_existing.add(i)
                return i
        return None

    ruct_by_univ = defaultdict(list)
    for d in degrees:
        ruct_by_univ[d["codigo_universidad"]].append(d)

    for ruct, univ_id in univ_id_of_ruct.items():
        official = {norm(d["nombre"]): d for d in ruct_by_univ.get(ruct, [])}
        matched = set()
        if ruct in SUBJECT_SOURCES:
            titulaciones = {}
            for s in read_csv(SUBJECT_SOURCES[ruct]):
                titulaciones.setdefault(s["codigo_titulacion"], s)
            for tcode, s in sorted(titulaciones.items()):
                center_name = fix_accents(s["centro"]) if s["centro"] else GENERIC_CENTER
                cid = center_id(univ_id, ruct, center_name)
                ref = official.get(norm(s["titulacion"]))
                if ref:
                    matched.add(norm(s["titulacion"]))
                existing = take_existing(univ_id, s["titulacion"], cid) or take_existing(univ_id, s["titulacion"])
                if existing:
                    degree_of_titulacion[(ruct, tcode)] = existing
                    degree_updates.append((existing, ref))
                else:
                    did = uid("degree", ruct, "tit", tcode)
                    degree_of_titulacion[(ruct, tcode)] = did
                    degree_rows.append((did, cid, unique_degree_name(cid, s["titulacion"], tcode), ref))
        for key, d in official.items():
            if key in matched:
                continue
            existing = take_existing(univ_id, d["nombre"])
            if existing:
                degree_updates.append((existing, d))
            else:
                cid = center_id(univ_id, ruct, GENERIC_CENTER)
                degree_rows.append((uid("degree", ruct, d["codigo_titulo"]), cid,
                                    unique_degree_name(cid, d["nombre"], d["codigo_titulo"]), d))

    w(f"\n-- Centros nuevos ({len(new_centers)}); «{GENERIC_CENTER}» agrupa los grados cuyo centro no publica el RUCT.")
    for cid, univ_id, name in new_centers:
        w(f"INSERT INTO centros (id, universidad_id, nombre) VALUES ({q(cid)}, {q(univ_id)}, {q(name)});")

    w(f"\n-- Grados que ya existían: código oficial y rama ({len(degree_updates)}).")
    for did, ref in degree_updates:
        if ref:
            w(f"UPDATE carreras SET codigo_ruct = {q(ref['codigo_titulo'])}, rama = {q(ref['rama'])} WHERE id = {q(did)};")
    w(f"\n-- Grados nuevos ({len(degree_rows)}).")
    for did, cid, name, ref in degree_rows:
        w("INSERT INTO carreras (id, centro_id, nombre, codigo_ruct, rama) VALUES "
          f"({q(did)}, {q(cid)}, {q(name)}, {q(ref['codigo_titulo'] if ref else None)}, "
          f"{q(ref['rama'] if ref else None)});")

    # Asignaturas: las del seed se completan con su código; el resto se inserta.
    existing_subjects = defaultdict(dict)  # carrera → norm nombre → id
    subject_names = defaultdict(set)  # carrera → nombres exactos ya usados (tras corregir mayúsculas)
    for s in subjects_v2:
        existing_subjects[s["carrera_id"]][norm(s["nombre"])] = s["id"]
        subject_names[s["carrera_id"]].add(sentence(s["nombre"]))
    subject_inserts, subject_updates = [], []
    for ruct, source in SUBJECT_SOURCES.items():
        seen = set()
        for s in read_csv(source):
            did = degree_of_titulacion.get((ruct, s["codigo_titulacion"]))
            key = (did, s["codigo_asignatura"])
            if not did or key in seen:
                continue
            seen.add(key)
            existing = existing_subjects[did].get(norm(s["nombre"]))
            if existing:
                subject_updates.append((existing, s["codigo_asignatura"]))
                continue
            semester = s["semestre"] if s["semestre"] in ("1", "2") else None
            # Optativas distintas con el mismo nombre en una carrera: se distinguen por su código.
            name = sentence(s["nombre"])
            if name in subject_names[did]:
                name = f"{name} ({s['codigo_asignatura']})"
            subject_names[did].add(name)
            subject_inserts.append(
                f"({q(uid('subject', ruct, s['codigo_titulacion'], s['codigo_asignatura']))}, {q(did)}, "
                f"{q(name)}, {q(s['codigo_asignatura'])}, {num(s['curso'])}, {num(semester)}, "
                f"{q(s['caracter'])}, {num(s['creditos'], float)}, {q(s['url_plan_docente'])})")
    w(f"\n-- Asignaturas que ya existían: su código oficial ({len(subject_updates)}).")
    for sid, code in subject_updates:
        w(f"UPDATE asignaturas_catalogo SET codigo = {q(code)} WHERE id = {q(sid)};")
    w(f"\n-- Asignaturas nuevas de la UEx y la Universidad de Cantabria ({len(subject_inserts)}).")
    for i in range(0, len(subject_inserts), 500):
        w("INSERT INTO asignaturas_catalogo (id, carrera_id, nombre, codigo, curso, semestre, caracter, creditos, "
          "url_guia_docente) VALUES\n" + ",\n".join(subject_inserts[i:i + 500]) + ";")

    w("\n-- Nombres que el seed guardó en mayúsculas («GEOTECNIA» → «Geotecnia»).")
    fixes = 0
    for s in subjects_v2:
        fixed = sentence(s["nombre"])
        character = sentence(s["caracter"]) if s.get("caracter") else None
        if fixed != s["nombre"] or (character and character != s["caracter"]):
            fixes += 1
            w(f"UPDATE asignaturas_catalogo SET nombre = {q(fixed)}"
              + (f", caracter = {q(character)}" if character else "") + f" WHERE id = {q(s['id'])};")

    OUT.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
    print(f"{OUT.name}: {inserted_univ} universidades nuevas, {len(new_centers)} centros, "
          f"{len(degree_rows)} grados nuevos, {len(degree_updates)} grados completados, "
          f"{len(subject_inserts)} asignaturas nuevas, {len(subject_updates)} completadas, "
          f"{fixes} nombres corregidos; {OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
