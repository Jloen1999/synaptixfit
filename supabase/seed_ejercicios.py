#!/usr/bin/env python3
"""
seed_ejercicios.py - Puebla la BD de SynaptixFit con los datos de ExerciseDB en español.

Uso:
    1. Instalar dependencias: python -m pip install supabase python-dotenv
  2. Configurar variables de entorno (o archivo .env):
     - SUPABASE_URL
     - SUPABASE_SERVICE_ROLE_KEY
     - CLOUDFLARE_R2_BASE_URL (opcional, default usa endpoint del bucket)
  3. Ejecutar: python seed_ejercicios.py

Nota: Este script es IDEMPOTENTE (puede ejecutarse múltiples veces sin duplicar datos).
"""

import json
import os
import sys
from pathlib import Path

try:
    from supabase import create_client, Client
except ImportError:
    print("❌ Falta la librería 'supabase'. Instala con: python -m pip install supabase")
    sys.exit(1)

try:
    from dotenv import load_dotenv
except ImportError:
    pass  # dotenv es opcional
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

# ─────────────────────────────────────────────────────────────────────────────
# Configuración
# ─────────────────────────────────────────────────────────────────────────────

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
R2_BASE_URL = os.getenv(
    "CLOUDFLARE_R2_BASE_URL",
    "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev"
)
R2_BUCKET = "synaptixfit"
GIF_RESOLUTION = "360"  # Carpeta de resolución: 360x360

# Directorio donde viven los JSON de ejercicios
EXERCISEDB_DIR = Path(__file__).parent.parent / "exercisedb"

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Falta SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en las variables de entorno.")
    print("   Configura un archivo .env o exporta las variables antes de ejecutar.")
    sys.exit(1)


def load_json(filename: str) -> list:
    """Carga un archivo JSON desde el directorio de ExerciseDB."""
    filepath = EXERCISEDB_DIR / filename
    if not filepath.exists():
        print(f"⚠️  Archivo no encontrado: {filepath}")
        return []
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def build_gif_url(exercise_db_id: str) -> str:
    """Construye la URL pública del GIF en Cloudflare R2."""
    return f"{R2_BASE_URL}/{R2_BUCKET}/ejercicios/{GIF_RESOLUTION}/{exercise_db_id}.gif"


def upsert_catalogo(supabase: Client, tabla: str, items: list[dict]) -> dict[str, int]:
    """
    Inserta o actualiza items de catálogo. Retorna un mapeo nombre -> id.
    """
    nombre_to_id = {}

    # Primero obtener los que ya existen
    response = supabase.table(tabla).select("id, nombre").execute()
    for row in response.data:
        nombre_to_id[row["nombre"]] = row["id"]

    # Insertar los que faltan
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
        print(f"  ✅ {tabla}: {len(nuevos)} nuevos, {len(nombre_to_id)} total")
    else:
        print(f"  ✅ {tabla}: ya completo ({len(nombre_to_id)} registros)")

    return nombre_to_id


def seed_ejercicios(supabase: Client, ejercicios_data: list, catalogos: dict):
    """Inserta los ejercicios y sus relaciones N:M."""
    musculos_map = catalogos["musculos"]
    partes_map = catalogos["partes_cuerpo"]
    equip_map = catalogos["equipamientos"]

    # Obtener ejercicios existentes por exercise_db_id
    response = supabase.table("ejercicios").select("id, exercise_db_id").execute()
    existentes = {row["exercise_db_id"]: row["id"] for row in response.data}

    nuevos_ejercicios = 0
    relaciones_insertadas = 0

    for ej in ejercicios_data:
        db_id = ej["exerciseId"]

        if db_id in existentes:
            ejercicio_uuid = existentes[db_id]
        else:
            # Insertar ejercicio nuevo
            payload = {
                "exercise_db_id": db_id,
                "nombre": ej["name"],
                "url_gif": build_gif_url(db_id),
                "instrucciones": ej.get("instructions", []),
                "dificultad": "medio",  # Default, se puede ajustar después
                "descripcion": _generar_descripcion(ej),
            }
            result = supabase.table("ejercicios").insert(payload).execute()
            ejercicio_uuid = result.data[0]["id"]
            existentes[db_id] = ejercicio_uuid
            nuevos_ejercicios += 1

        # Insertar relaciones N:M (upsert con on_conflict ignore)
        relaciones_insertadas += _insert_relaciones(
            supabase, ejercicio_uuid, ej, musculos_map, partes_map, equip_map
        )

    print(f"  ✅ ejercicios: {nuevos_ejercicios} nuevos, {len(existentes)} total")
    print(f"  ✅ relaciones N:M: {relaciones_insertadas} insertadas")


def _generar_descripcion(ej: dict) -> str:
    """Genera una descripción textual a partir de los datos del ejercicio."""
    musculos = ", ".join(ej.get("targetMuscles", []))
    partes = ", ".join(ej.get("bodyParts", []))
    equips = ", ".join(ej.get("equipments", []))
    return f"Ejercicio para {musculos}. Zona: {partes}. Equipo: {equips}."


def _insert_relaciones(
    supabase: Client,
    ejercicio_uuid: str,
    ej: dict,
    musculos_map: dict,
    partes_map: dict,
    equip_map: dict,
) -> int:
    """Inserta relaciones N:M para un ejercicio. Retorna cantidad insertada."""
    count = 0

    # Músculos objetivo
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
                pass  # Ya existe, ignorar

    # Músculos secundarios
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

    # Partes del cuerpo
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

    # Equipamientos
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


def main():
    print("=" * 60)
    print("🏋️ SynaptixFit - Seed de Ejercicios (ExerciseDB español)")
    print("=" * 60)
    print(f"📡 Supabase: {SUPABASE_URL}")
    print(f"☁️  R2 Base:  {R2_BASE_URL}/{R2_BUCKET}/ejercicios/{GIF_RESOLUTION}/")
    print()

    # Conectar a Supabase
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("🔌 Conexión establecida con Supabase")
    print()

    # Cargar datos JSON
    print("📂 Cargando archivos JSON...")
    partes_cuerpo = load_json("synaptix_partesCuerpo_es.json")
    musculos = load_json("synaptix_musculos_es.json")
    equipamientos = load_json("synaptix_equipamientos_es.json")
    ejercicios = load_json("synaptix_exercisedb_es.json")

    print(f"   Partes del cuerpo: {len(partes_cuerpo)}")
    print(f"   Músculos: {len(musculos)}")
    print(f"   Equipamientos: {len(equipamientos)}")
    print(f"   Ejercicios: {len(ejercicios)}")
    print()

    # Paso 1: Poblar catálogos
    print("📋 Paso 1: Insertando catálogos...")
    catalogos = {
        "partes_cuerpo": upsert_catalogo(supabase, "partes_cuerpo", partes_cuerpo),
        "musculos": upsert_catalogo(supabase, "musculos", musculos),
        "equipamientos": upsert_catalogo(supabase, "equipamientos", equipamientos),
    }
    print()

    # Paso 2: Poblar ejercicios y relaciones
    print("🏋️ Paso 2: Insertando ejercicios y relaciones...")
    seed_ejercicios(supabase, ejercicios, catalogos)
    print()

    # Verificación final
    print("🔍 Verificación final:")
    for tabla in [
        "partes_cuerpo", "musculos", "equipamientos", "ejercicios",
        "ejercicio_musculo_objetivo", "ejercicio_musculo_secundario",
        "ejercicio_parte_cuerpo", "ejercicio_equipamiento",
    ]:
        res = supabase.table(tabla).select("*", count="exact").execute()
        print(f"   {tabla}: {res.count} registros")

    print()
    print("✅ ¡Seed completado exitosamente!")
    print("=" * 60)


if __name__ == "__main__":
    main()
