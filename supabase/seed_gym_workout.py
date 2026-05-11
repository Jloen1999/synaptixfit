#!/usr/bin/env python3
"""
seed_gym_workout.py - Inserta los 15 nuevos ejercicios de Gym Workout en la BD de SynaptixFit.

Este script es NO destructivo: solo inserta ejercicios nuevos sin eliminar los existentes.
Las relaciones N:M se crean mediante upsert para evitar duplicados.

Uso:
    1. Asegurar que SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY estan configurados
    2. Ejecutar: python seed_gym_workout.py
"""

import json
import os
import sys
from pathlib import Path

try:
    from supabase import create_client
except ImportError:
    print("Falta la libreria 'supabase'. Instala con: python -m pip install supabase")
    sys.exit(1)

try:
    from dotenv import load_dotenv
except ImportError:
    pass
else:
    script_dir = Path(__file__).resolve().parent
    workspace_root = script_dir.parent
    candidate_env_files = [
        script_dir / ".env",
        workspace_root / ".env",
        workspace_root / "app" / ".env",
    ]
    for env_file in candidate_env_files:
        if env_file.exists():
            load_dotenv(env_file, override=False)
            break
    else:
        load_dotenv(override=False)

# ---------------------------------------------------------------------------
# Configuracion
# ---------------------------------------------------------------------------

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
R2_BASE_URL = os.getenv(
    "CLOUDFLARE_R2_BASE_URL",
    "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev"
)
GIF_RESOLUTION = "360"

EXERCISEDB_DIR = Path(__file__).parent.parent / "exercisedb"

if not SUPABASE_URL or not SUPABASE_KEY:
    print("Falta SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en las variables de entorno.")
    sys.exit(1)

# IDs de los 15 ejercicios nuevos de Gym Workout
GYM_WORKOUT_IDS = {
    "1bcUrlB", "1bncPrs", "1chFlyM", "1dedLft", "1dcBenc",
    "1hmCurl", "1ltPuld", "1lgExtn", "1lgRais", "1plankX",
    "1pshUpX", "1rsTwst", "1squatB", "1tbRowX", "1trPshD",
}


def load_json(filename: str) -> list:
    filepath = EXERCISEDB_DIR / filename
    if not filepath.exists():
        print(f"  Archivo no encontrado: {filepath}")
        return []
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def construir_url_gif(gif_url: str) -> str:
    """Construye la URL publica del video en Cloudflare R2.
    Soporta archivos .gif (legacy) y .mp4 (Gym Workout)."""
    return f"{R2_BASE_URL}/ejercicios/{GIF_RESOLUTION}/{gif_url}"


def filtrar_ejercicios_nuevos(todos: list) -> list:
    """Filtra solo los ejercicios de Gym Workout por su exerciseId."""
    return [ej for ej in todos if ej["exerciseId"] in GYM_WORKOUT_IDS]


def upsert_catalogo(supabase, tabla: str, items: list) -> dict:
    """Inserta items de catalogo que no existan. Retorna mapeo nombre -> id."""
    nombre_to_id = {}

    response = supabase.table(tabla).select("id, nombre").execute()
    for row in response.data:
        nombre_to_id[row["nombre"]] = row["id"]

    nuevos = []
    vistos = set()
    for item in items:
        if item["name"] not in nombre_to_id and item["name"] not in vistos:
            nuevos.append(item)
            vistos.add(item["name"])

    if nuevos:
        payload = [{"nombre": item["name"]} for item in nuevos]
        result = supabase.table(tabla).insert(payload).execute()
        for row in result.data:
            nombre_to_id[row["nombre"]] = row["id"]
        print(f"  {tabla}: {len(nuevos)} nuevos insertados, {len(nombre_to_id)} total")
    else:
        print(f"  {tabla}: ya completo ({len(nombre_to_id)} registros)")

    return nombre_to_id


def insertar_ejercicios(supabase, ejercicios: list, catalogos: dict):
    """Inserta los ejercicios nuevos y sus relaciones N:M."""
    musculos_map = catalogos["musculos"]
    partes_map = catalogos["partes_cuerpo"]
    equip_map = catalogos["equipamientos"]

    response = supabase.table("ejercicios").select("id, exercise_db_id").execute()
    existentes = {row["exercise_db_id"]: row["id"] for row in response.data}

    nuevos_count = 0
    saltados_count = 0
    relaciones_count = 0

    for ej in ejercicios:
        db_id = ej["exerciseId"]

        if db_id in existentes:
            saltados_count += 1
            continue

        gif_url = ej.get("gifUrl", "")
        url_completa = construir_url_gif(gif_url)
        descripcion = generar_descripcion(ej)

        payload = {
            "exercise_db_id": db_id,
            "nombre": ej["name"],
            "url_gif": url_completa,
            "instrucciones": ej.get("instructions", []),
            "dificultad": "medio",
            "descripcion": descripcion,
        }

        result = supabase.table("ejercicios").insert(payload).execute()
        ejercicio_uuid = result.data[0]["id"]
        existentes[db_id] = ejercicio_uuid
        nuevos_count += 1

        relaciones_count += insertar_relaciones(
            supabase, ejercicio_uuid, ej, musculos_map, partes_map, equip_map
        )

    print(f"  ejercicios: {nuevos_count} insertados, {saltados_count} saltados (ya existian)")
    print(f"  relaciones N:M: {relaciones_count} upsert realizados")


def generar_descripcion(ej: dict) -> str:
    musculos = ", ".join(ej.get("targetMuscles", []))
    partes = ", ".join(ej.get("bodyParts", []))
    equips = ", ".join(ej.get("equipments", []))
    return f"Ejercicio para {musculos}. Zona: {partes}. Equipo: {equips}."


def insertar_relaciones(supabase, ejercicio_uuid: str, ej: dict,
                        musculos_map: dict, partes_map: dict,
                        equip_map: dict) -> int:
    count = 0

    for nombre in ej.get("targetMuscles", []):
        mid = musculos_map.get(nombre)
        if mid:
            try:
                supabase.table("ejercicio_musculo_objetivo").upsert(
                    {"ejercicio_id": ejercicio_uuid, "musculo_id": mid},
                    on_conflict="ejercicio_id,musculo_id",
                ).execute()
                count += 1
            except Exception:
                pass

    for nombre in ej.get("secondaryMuscles", []):
        mid = musculos_map.get(nombre)
        if mid:
            try:
                supabase.table("ejercicio_musculo_secundario").upsert(
                    {"ejercicio_id": ejercicio_uuid, "musculo_id": mid},
                    on_conflict="ejercicio_id,musculo_id",
                ).execute()
                count += 1
            except Exception:
                pass

    for nombre in ej.get("bodyParts", []):
        pid = partes_map.get(nombre)
        if pid:
            try:
                supabase.table("ejercicio_parte_cuerpo").upsert(
                    {"ejercicio_id": ejercicio_uuid, "parte_cuerpo_id": pid},
                    on_conflict="ejercicio_id,parte_cuerpo_id",
                ).execute()
                count += 1
            except Exception:
                pass

    for nombre in ej.get("equipments", []):
        eid = equip_map.get(nombre)
        if eid:
            try:
                supabase.table("ejercicio_equipamiento").upsert(
                    {"ejercicio_id": ejercicio_uuid, "equipamiento_id": eid},
                    on_conflict="ejercicio_id,equipamiento_id",
                ).execute()
                count += 1
            except Exception:
                pass

    return count


def verificar_final(supabase):
    """Muestra el conteo final de registros en las tablas de ejercicios."""
    print()
    print("  Verificacion final:")
    for tabla in [
        "partes_cuerpo", "musculos", "equipamientos", "ejercicios",
        "ejercicio_musculo_objetivo", "ejercicio_musculo_secundario",
        "ejercicio_parte_cuerpo", "ejercicio_equipamiento",
    ]:
        res = supabase.table(tabla).select("*", count="exact").execute()
        print(f"    {tabla}: {res.count} registros")


def main():
    print("=" * 60)
    print("  SynaptixFit - Seed de Ejercicios Gym Workout (15 ejercicios)")
    print("=" * 60)
    print(f"  Supabase: {SUPABASE_URL}")
    print(f"  R2 Base:  {R2_BASE_URL}/ejercicios/{GIF_RESOLUTION}/")
    print()

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("  Conexion establecida con Supabase")
    print()

    partes_cuerpo = load_json("synaptix_bodyParts_es.json")
    musculos = load_json("synaptix_muscles_es.json")
    equipamientos = load_json("synaptix_equipments_es.json")
    ejercicios = load_json("synaptix_exercises_es.json")

    gym_workout = filtrar_ejercicios_nuevos(ejercicios)

    print(f"  Ejercicios Gym Workout detectados: {len(gym_workout)} (de {len(ejercicios)} totales)")
    print()

    print("  Paso 1: Insertando catalogos nuevos si es necesario...")
    catalogos = {
        "partes_cuerpo": upsert_catalogo(supabase, "partes_cuerpo", partes_cuerpo),
        "musculos": upsert_catalogo(supabase, "musculos", musculos),
        "equipamientos": upsert_catalogo(supabase, "equipamientos", equipamientos),
    }
    print()

    print("  Paso 2: Insertando ejercicios Gym Workout y relaciones...")
    insertar_ejercicios(supabase, gym_workout, catalogos)
    verificar_final(supabase)

    print()
    print("  Seed Gym Workout completado!")
    print("  Videos a subir a Cloudflare R2 en: ejercicios/360/<UUID>.mp4")
    print("=" * 60)


if __name__ == "__main__":
    main()
