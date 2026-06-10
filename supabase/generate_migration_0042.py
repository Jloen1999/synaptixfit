"""
generate_migration_0042.py — Fase 2: Genera migracion SQL autocontenida desde dataset_final.json.

La migracion resultante NO depende de ningun script externo:
  1. DROP + CREATE v_ejercicios_completos
  2. DELETE FROM ejercicios (cascade)
  3. 909 INSERT INTO ejercicios
  4. ~5040 INSERT INTO ejercicio_* (N:M) usando subqueries por url_gif/url_preview
  5. CREATE OR REPLACE VIEW v_ejercicios_completos (LATERAL joins)
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
EJERCICIOS_JSON = SCRIPT_DIR / "dataset_final.json"
MIGRATIONS_DIR = SCRIPT_DIR / "migrations"

COLUMNAS_EJERCICIO = [
    "nombre", "url_gif", "url_preview", "instrucciones",
    "dificultad", "descripcion", "finalidad",
    "modalidad_entrenamiento", "tipo_medicion", "es_circuito",
]

# Relacion: (tabla_junction, fk_col, tabla_catalogo, id_catalogo_col)
RELACIONES = [
    ("ejercicio_musculo_objetivo", "musculo_id", "musculos"),
    ("ejercicio_musculo_secundario", "musculo_id", "musculos"),
    ("ejercicio_parte_cuerpo", "parte_cuerpo_id", "partes_cuerpo"),
    ("ejercicio_equipamiento", "equipamiento_id", "equipamientos"),
]

JSON_REL_KEY = {
    "ejercicio_musculo_objetivo": "musculos_objetivo",
    "ejercicio_musculo_secundario": "musculos_secundarios",
    "ejercicio_parte_cuerpo": "partes_cuerpo",
    "ejercicio_equipamiento": "equipamientos",
}


def escapar_sql(texto: str) -> str:
    """Escapa comillas simples para SQL."""
    return texto.replace("'", "''")


def escapar_array(textos: list[str]) -> str:
    """Convierte lista de strings a ARRAY['...','...']::text[] de SQL."""
    if not textos:
        return "ARRAY[]::text[]"
    items = ", ".join(f"'{escapar_sql(t)}'" for t in textos)
    return f"ARRAY[{items}]::text[]"


def clausula_match(ej: dict) -> str:
    """
    Retorna clausula WHERE para localizar un ejercicio insertado.
    Prefiere url_gif; si esta vacio, usa url_preview.
    """
    url_video = ej.get("url_video", "")
    url_preview = ej.get("url_preview", "")
    if url_video and url_video.strip():
        return f"e.url_gif = '{escapar_sql(url_video)}'"
    else:
        return f"e.url_preview = '{escapar_sql(url_preview)}'"


def generar_migracion():
    print("=" * 60)
    print("Fase 2: Generando migracion SQL autocontenida")
    print("=" * 60)

    # Load corrected dataset
    with open(EJERCICIOS_JSON, "r", encoding="utf-8") as f:
        ejercicios = json.load(f)
    print(f"Cargados {len(ejercicios)} ejercicios")

    # Migration filename
    hoy = datetime.now(timezone.utc).strftime("%Y%m%d")
    mig_name = f"{hoy}_0042_seed_completo_desde_json.sql"
    mig_path = MIGRATIONS_DIR / mig_name

    # Build sections
    lines: list[str] = []

    # ============ HEADER ============
    lines.append(f"-- Migration: 0042_seed_completo_desde_json")
    lines.append(f"-- Generado: {datetime.now(timezone.utc).isoformat()}")
    lines.append(f"-- Fuente: supabase/dataset_final.json (corregido, {len(ejercicios)} ejercicios)")
    lines.append("--")
    lines.append("-- Autocontenido: reemplaza a 0038 + seed_todo.py.")
    lines.append("-- Ejecutar con: supabase db push")
    lines.append("-- NOTA: Los catalogos (musculos, partes_cuerpo, equipamientos)")
    lines.append("--       deben existir previamente (migraciones 0035-0037).")
    lines.append("")

    # ============ CLEANUP ============
    lines.append("-- ============================================================")
    lines.append("-- CLEANUP")
    lines.append("-- ============================================================")
    lines.append("")
    lines.append("drop view if exists public.v_ejercicios_completos cascade;")
    lines.append("delete from public.seleccion_de_ejercicios;")
    lines.append("delete from public.ejercicios;")
    lines.append("")

    # ============ INSERT EJERCICIOS ============
    lines.append("-- ============================================================")
    lines.append("-- INSERT EJERCICIOS (909)")
    lines.append("-- ============================================================")
    lines.append("")

    col_str = ", ".join(COLUMNAS_EJERCICIO)
    lines.append(f"insert into public.ejercicios ({col_str})")
    lines.append("values")

    valores = []
    for ej in ejercicios:
        nombre = escapar_sql(ej["nombre_ejercicio"])
        url_video = escapar_sql(ej.get("url_video", ""))
        url_preview = escapar_sql(ej.get("url_preview", ""))
        instrucciones = escapar_array(ej.get("instrucciones", []))
        dificultad = ej.get("dificultad", "principiante")
        descripcion = escapar_sql(ej.get("descripcion", ""))
        finalidad = escapar_array(ej.get("finalidad", []))
        modalidad = escapar_sql(ej.get("modalidad_entrenamiento", "fuerza"))
        tipo_med = escapar_array(ej.get("tipo_medicion", ["repeticiones"]))
        es_circ = "true" if ej.get("es_circuito", False) else "false"

        val = (
            f"  ('{nombre}', '{url_video}', '{url_preview}', "
            f"{instrucciones}, '{dificultad}', "
            f"'{descripcion}', {finalidad}, "
            f"'{modalidad}', {tipo_med}, {es_circ})"
        )
        valores.append(val)

    lines.append(",\n".join(valores) + ";")
    lines.append("")

    # ============ INSERT RELACIONES N:M ============
    lines.append("-- ============================================================")
    lines.append("-- INSERT RELACIONES N:M")
    lines.append("-- ============================================================")
    lines.append("")

    for tabla_junc, fk_col, tabla_cat in RELACIONES:
        json_key = JSON_REL_KEY[tabla_junc]
        lines.append(f"-- --- {tabla_junc} ---")
        lines.append("")

        for idx, ej in enumerate(ejercicios):
            nombres = ej.get(json_key, [])
            if not nombres:
                continue

            match_clause = clausula_match(ej)

            for nombre_cat in nombres:
                nombre_cat_esc = escapar_sql(nombre_cat)
                lines.append(
                    f"insert into public.{tabla_junc} "
                    f"(ejercicio_id, {fk_col}) "
                    f"select e.id, cat.id "
                    f"from public.ejercicios e, "
                    f"public.{tabla_cat} cat "
                    f"where {match_clause} "
                    f"and lower(cat.nombre) = lower('{nombre_cat_esc}');"
                )
            # Gap cada 50 ejercicios
            if (idx + 1) % 50 == 0:
                lines.append("")

    # ============ RECREATE VIEW ============
    lines.append("-- ============================================================")
    lines.append("-- RECREATE VIEW (LATERAL joins, migracion 0039)")
    lines.append("-- ============================================================")
    lines.append("")
    lines.append("create or replace view public.v_ejercicios_completos")
    lines.append("  with (security_invoker=true) as")
    lines.append("select")
    lines.append("  e.id,")
    lines.append("  e.nombre,")
    lines.append("  e.url_gif,")
    lines.append("  e.url_preview,")
    lines.append("  e.instrucciones,")
    lines.append("  e.dificultad,")
    lines.append("  e.descripcion,")
    lines.append("  e.finalidad,")
    lines.append("  e.modalidad_entrenamiento,")
    lines.append("  e.tipo_medicion,")
    lines.append("  e.es_circuito,")
    lines.append("  e.creado_en,")
    lines.append("  coalesce(mo.arr, '[]'::jsonb) as musculos_objetivo,")
    lines.append("  coalesce(ms.arr, '[]'::jsonb) as musculos_secundarios,")
    lines.append("  coalesce(pc.arr, '[]'::jsonb) as partes_cuerpo,")
    lines.append("  coalesce(eq.arr, '[]'::jsonb) as equipamientos")
    lines.append("from ejercicios e")
    lines.append("left join lateral (")
    lines.append("  select jsonb_agg(distinct m.nombre) as arr")
    lines.append("  from ejercicio_musculo_objetivo emo")
    lines.append("  join musculos m on m.id = emo.musculo_id")
    lines.append("  where emo.ejercicio_id = e.id")
    lines.append(") mo on true")
    lines.append("left join lateral (")
    lines.append("  select jsonb_agg(distinct m.nombre) as arr")
    lines.append("  from ejercicio_musculo_secundario ems")
    lines.append("  join musculos m on m.id = ems.musculo_id")
    lines.append("  where ems.ejercicio_id = e.id")
    lines.append(") ms on true")
    lines.append("left join lateral (")
    lines.append("  select jsonb_agg(distinct pc.nombre) as arr")
    lines.append("  from ejercicio_parte_cuerpo epc")
    lines.append("  join partes_cuerpo pc on pc.id = epc.parte_cuerpo_id")
    lines.append("  where epc.ejercicio_id = e.id")
    lines.append(") pc on true")
    lines.append("left join lateral (")
    lines.append("  select jsonb_agg(distinct eq.nombre) as arr")
    lines.append("  from ejercicio_equipamiento eeq")
    lines.append("  join equipamientos eq on eq.id = eeq.equipamiento_id")
    lines.append("  where eeq.ejercicio_id = e.id")
    lines.append(") eq on true;")
    lines.append("")

    # ============ WRITE ============
    content = "\n".join(lines)

    os.makedirs(MIGRATIONS_DIR, exist_ok=True)
    with open(mig_path, "w", encoding="utf-8") as f:
        f.write(content)

    size_kb = len(content) / 1024
    num_lines = len(lines)
    print(f"\nMigracion generada: {mig_name}")
    print(f"  Lineas: {num_lines}")
    print(f"  Tamano: {size_kb:.0f} KB")

    # Count N:M inserts
    nm_count = sum(1 for l in lines if l.strip().startswith("insert into public.ejercicio_"))
    print(f"  Inserts N:M: ~{nm_count}")

    print(f"\n[OK] Migracion lista en: {mig_path}")
    print("\n" + "=" * 60)
    print("Para aplicar: supabase db push")
    print("=" * 60)


if __name__ == "__main__":
    generar_migracion()
