#!/usr/bin/env python3
"""
Migra los datos de la base de datos de Supabase (esquema heredado) a la base de datos del
backend propio (esquema Flyway).

Uso:
    pip install "psycopg[binary]"
    python tools/migrate_from_supabase.py \
        --source "postgresql://postgres:<pwd>@db.<ref>.supabase.co:5432/postgres" \
        --target "postgresql://synaptixfit:synaptixfit@localhost:5432/synaptixfit" \
        [--dry-run]

Requisitos: el destino debe estar recién migrado por Flyway (arranca el backend una vez o
ejecuta `./mvnw flyway:migrate`). El catálogo (V2) ya está cargado: aquí se copian datos de
usuarios y, para el catálogo, solo las filas que falten.

Qué hace:
- Copia tabla a tabla en orden de dependencias, solo las columnas que existen en ambos esquemas
  (las columnas generadas se omiten). Filas ya existentes se ignoran (ON CONFLICT DO NOTHING),
  así que se puede relanzar.
- Usuarios: toma el hash BCrypt de `auth.users.encrypted_password` (compatible con el backend) y
  el `google_sub` de `auth.identities`. Las cuentas sin contraseña ni Google quedan con una
  credencial inutilizable y se listan al final (deberán restablecer la contraseña).
- Normaliza valores heredados (ver docs/01-architecture/data_model.md).
Detalle: docs/04-guides/data_migration.md
"""
import argparse
import sys

try:
    import psycopg
    from psycopg import sql
    from psycopg.types.json import Jsonb
except ImportError:
    sys.exit('Falta psycopg: pip install "psycopg[binary]"')

# Orden de copia: padres antes que hijos.
TABLES = [
    "usuarios",
    "universidades", "centros", "carreras", "asignaturas_catalogo", "bibliografia_asignatura",
    "criterios_evaluacion", "prerrequisitos_asignatura", "profesores_asignatura",
    "equipamientos", "musculos", "partes_cuerpo", "ejercicios", "ejercicio_equipamiento",
    "ejercicio_musculo_objetivo", "ejercicio_musculo_secundario", "ejercicio_parte_cuerpo",
    "insignias",
    "perfil_bienestar_usuario", "perfil_academico_usuario", "historial_peso", "historial_objetivos",
    "usuario_carreras", "preferencias_notificacion",
    "asignaturas", "asignaturas_usuario_semestre", "apuntes", "archivos_asignatura", "documentos_ia",
    "materiales_estudio", "registros_repaso_srs", "bancos_preguntas", "preguntas", "intentos_pregunta",
    "test_sessions",
    "rutinas", "semanas_rutina", "dias_rutina", "seleccion_de_ejercicios",
    "planes_estudio", "entregas_examenes", "retos", "hitos_de_reto", "horarios_academicos",
    "progreso_de_reto", "sesiones_registradas", "series_sesion", "registros_carga_fisica",
    "plan_entrenamiento_semanal", "estado_diario_usuario", "recomendaciones_pendientes",
    "carga_academica_semanal", "sesiones_focus",
    "usuario_insignias",
    "actividades_sociales", "interacciones_sociales", "comentarios_feed", "amistades", "notificaciones",
    "estado_cognitivo_usuario", "estado_regulacion_cruzada",
    "admin_auditoria",
]

PRIVACY = {"publico": "public", "privado": "private", "amigos": "friends", "solo_amigos": "friends",
           "public": "public", "private": "private", "friends": "friends"}
UNUSABLE_PASSWORD = "!migrated-without-credentials"


def columns(conn, table, generated=False):
    rows = conn.execute(
        """select column_name, is_generated, data_type from information_schema.columns
           where table_schema = 'public' and table_name = %s order by ordinal_position""",
        (table,)).fetchall()
    return {name: dtype for name, gen, dtype in rows if generated or gen != "ALWAYS"}


def transform(table, row):
    """Adapta una fila del esquema heredado. Devuelve None para descartarla."""
    if table == "usuarios":
        row["nivel_privacidad"] = PRIVACY.get(row.get("nivel_privacidad"), "private")
        if "xp_total" in row:
            row["xp_nivel_actual"] = row.pop("xp_total")
    elif table == "apuntes" and row.get("visibilidad") is not None:
        row["visibilidad"] = PRIVACY.get(row["visibilidad"], "private")
    elif table in ("rutinas", "retos", "planes_estudio") and row.get("visibilidad") is not None:
        row["visibilidad"] = PRIVACY.get(row["visibilidad"], "private")
    elif table == "interacciones_sociales" and row.get("tipo_interaccion") != "like":
        return None
    elif table == "ejercicios" and row.get("dificultad") == "medio":
        row["dificultad"] = "intermedio"
    elif table == "entregas_examenes" and row.get("tipo") not in ("examen", "entrega", "presentacion", "otro"):
        row["tipo"] = "otro"
    return row


def source_rows(src, table):
    if table == "usuarios":
        query = """
            select u.*, a.encrypted_password as password_hash,
                   (select i.provider_id from auth.identities i
                     where i.user_id = u.id and i.provider = 'google' limit 1) as google_sub
            from public.usuarios u join auth.users a on a.id = u.id"""
    else:
        query = sql.SQL("select * from public.{}").format(sql.Identifier(table))
    cur = src.execute(query)
    names = [d.name for d in cur.description]
    for record in cur:
        yield dict(zip(names, record))


def adapt_value(value, dtype):
    if dtype == "jsonb" and value is not None and not isinstance(value, Jsonb):
        return Jsonb(value)
    return value


def copy_table(src, dst, table, dry_run):
    src_exists = src.execute(
        "select 1 from information_schema.tables where table_schema='public' and table_name=%s",
        (table,)).fetchone()
    if not src_exists:
        print(f"  {table}: no existe en origen, se omite")
        return 0, 0
    target_cols = columns(dst, table)
    copied = skipped = 0
    without_credentials = []
    for raw in source_rows(src, table):
        row = transform(table, raw)
        if row is None:
            skipped += 1
            continue
        if table == "usuarios":
            if not row.get("password_hash") and not row.get("google_sub"):
                row["password_hash"] = UNUSABLE_PASSWORD
                without_credentials.append(row.get("email"))
            elif not row.get("password_hash"):
                row["password_hash"] = None
        cols = [c for c in row if c in target_cols]
        if dry_run:
            copied += 1
            continue
        statement = sql.SQL("insert into {} ({}) values ({}) on conflict do nothing").format(
            sql.Identifier(table),
            sql.SQL(", ").join(map(sql.Identifier, cols)),
            sql.SQL(", ").join(sql.Placeholder() * len(cols)))
        result = dst.execute(statement, [adapt_value(row[c], target_cols[c]) for c in cols])
        copied += result.rowcount
    if without_credentials:
        print(f"  ! {len(without_credentials)} cuentas sin contraseña ni Google (deberán restablecerla): "
              + ", ".join(e or "?" for e in without_credentials))
    return copied, skipped


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", required=True, help="URL de conexión de Supabase (Postgres)")
    parser.add_argument("--target", required=True, help="URL de conexión de la BD del backend")
    parser.add_argument("--dry-run", action="store_true", help="Cuenta filas sin escribir")
    args = parser.parse_args()

    with psycopg.connect(args.source) as src, psycopg.connect(args.target) as dst:
        for table in TABLES:
            copied, skipped = copy_table(src, dst, table, args.dry_run)
            extra = f", {skipped} descartadas" if skipped else ""
            print(f"  {table}: {copied} filas{extra}")
        for seq in ("equipamientos", "musculos", "partes_cuerpo"):
            dst.execute(sql.SQL("select setval({}, (select coalesce(max(id), 1) from {}))").format(
                sql.Literal(f"{seq}_id_seq"), sql.Identifier(seq)))
        if args.dry_run:
            dst.rollback()
            print("Simulación terminada: no se ha escrito nada.")
        else:
            dst.commit()
            print("Migración completada.")


if __name__ == "__main__":
    main()
