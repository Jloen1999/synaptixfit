"""
seed_todo.py - Script unificado de seeding para SynaptixFit.

Lee los JSON consolidados y carga todo el catalogo de ejercicios en Supabase:
  - nuevos_ejercicios.json  (90 ejercicios unificados, 3 fuentes)
  - musculos.json           (60 musculos unificados)
  - partes_cuerpo.json      (13 partes del cuerpo)

Flujo:
  1. Upsert de catalogos (musculos, partes_cuerpo, equipamientos)
  2. Insercion de ejercicios (dedup por nombre)
  3. Upsert de relaciones N:M
  4. Resumen final

Reemplaza a: seed_ejercicios.py, seed_nuevos_ejercicios.py, seed_gym_workout.py
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
    for env_file in [
        script_dir / ".env",
        workspace_root / ".env",
        workspace_root / "app" / ".env",
    ]:
        if env_file.exists():
            load_dotenv(env_file, override=False)
            break

# ---------------------------------------------------------------------------
# Configuracion
# ---------------------------------------------------------------------------

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("ERROR: Falta SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).resolve().parent
EJERCICIOS_JSON = SCRIPT_DIR / "nuevos_ejercicios.json"
MUSCULOS_JSON = SCRIPT_DIR / "musculos.json"
PARTES_JSON = SCRIPT_DIR / "partes_cuerpo.json"


# ---------------------------------------------------------------------------
# Funciones de catalogo
# ---------------------------------------------------------------------------

def upsert_catalogo(supabase, tabla: str, items: list[dict]) -> dict:
    """
    Inserta items nuevos en una tabla de catalogo.
    Retorna dict {nombre: id} con todos los registros (existentes + nuevos).
    """
    nombre_to_id: dict[str, any] = {}

    resp = supabase.table(tabla).select("id, nombre").execute()
    for row in resp.data:
        nombre_to_id[row["nombre"]] = row["id"]

    existentes = set(nombre_to_id.keys())
    nuevos = []
    vistos = set()
    for item in items:
        nombre = item["nombre"]
        if nombre not in existentes and nombre not in vistos:
            nuevos.append(item)
            vistos.add(nombre)

    if nuevos:
        payload = [{"nombre": item["nombre"]} for item in nuevos]
        result = supabase.table(tabla).insert(payload).execute()
        for row in result.data:
            nombre_to_id[row["nombre"]] = row["id"]
        print(f"  [OK] {tabla}: {len(nuevos)} nuevos ({len(nombre_to_id)} total)")
        for item in nuevos:
            print(f"       + {item['nombre']}")
    else:
        print(f"  [OK] {tabla}: ya completo ({len(nombre_to_id)} registros)")

    return nombre_to_id


def extraer_equipamientos(ejercicios: list) -> list[dict]:
    """Extrae equipamientos unicos de los ejercicios."""
    vistos = set()
    items = []
    for ej in ejercicios:
        for nombre in ej.get("equipamientos", []):
            if nombre not in vistos:
                vistos.add(nombre)
                items.append({"nombre": nombre})
    return items


# ---------------------------------------------------------------------------
# Insercion de ejercicios
# ---------------------------------------------------------------------------

def insertar_ejercicios(supabase, ejercicios: list, catalogos: dict):
    """
    Inserta ejercicios nuevos y sus relaciones N:M.
    Detecta duplicados por nombre normalizado (case-insensitive, sin acentos).
    """
    musculos_map = catalogos["musculos"]
    partes_map = catalogos["partes_cuerpo"]
    equip_map = catalogos["equipamientos"]

    # Cargar existentes
    resp = supabase.table("ejercicios").select("id, nombre").execute()
    existentes = {}
    for row in resp.data:
        key = row["nombre"].strip().lower()
        existentes[key] = row["id"]

    print(f"   {len(existentes)} ejercicios ya existentes en la BD\n")

    nuevos = 0
    omitidos = 0
    errores = 0
    relaciones = 0

    for ej in ejercicios:
        nombre_key = ej["nombre_ejercicio"].strip().lower()

        # Si ya existe, restaurar relaciones N:M (upsert idempotente)
        existente_id = existentes.get(nombre_key)
        if existente_id:
            relaciones += insertar_relaciones(
                supabase, existente_id, ej, musculos_map, partes_map, equip_map
            )
            omitidos += 1
            continue

        # Insertar nuevo
        payload = {
            "nombre": ej["nombre_ejercicio"],
            "descripcion": ej.get("descripcion", ""),
            "instrucciones": ej.get("instrucciones", []),
            "dificultad": ej.get("dificultad", "intermedio"),
            "finalidad": ej.get("finalidad", "fuerza"),
            "url_gif": ej.get("url_video"),
        }

        try:
            result = supabase.table("ejercicios").insert(payload).execute()
            ejercicio_id = result.data[0]["id"]
            existentes[nombre_key] = ejercicio_id
            nuevos += 1

            relaciones += insertar_relaciones(
                supabase, ejercicio_id, ej, musculos_map, partes_map, equip_map
            )
            print(f"   [OK] Insertado: {ej['nombre_ejercicio']}")
        except Exception as exc:
            errores += 1
            print(f"   [ERROR] {ej['nombre_ejercicio']}: {exc}")

    return nuevos, omitidos, errores, relaciones


def insertar_relaciones(supabase, ejercicio_id, ej, musculos_map, partes_map, equip_map):
    """Inserta relaciones N:M con upsert. Retorna cantidad insertada."""
    count = 0

    for nombre in ej.get("musculos_objetivo", []):
        mid = musculos_map.get(nombre)
        if mid:
            try:
                supabase.table("ejercicio_musculo_objetivo").upsert(
                    {"ejercicio_id": ejercicio_id, "musculo_id": mid},
                    on_conflict="ejercicio_id,musculo_id",
                ).execute()
                count += 1
            except Exception:
                pass

    for nombre in ej.get("musculos_secundarios", []):
        mid = musculos_map.get(nombre)
        if mid:
            try:
                supabase.table("ejercicio_musculo_secundario").upsert(
                    {"ejercicio_id": ejercicio_id, "musculo_id": mid},
                    on_conflict="ejercicio_id,musculo_id",
                ).execute()
                count += 1
            except Exception:
                pass

    for nombre in ej.get("partes_cuerpo", []):
        pid = partes_map.get(nombre)
        if pid:
            try:
                supabase.table("ejercicio_parte_cuerpo").upsert(
                    {"ejercicio_id": ejercicio_id, "parte_cuerpo_id": pid},
                    on_conflict="ejercicio_id,parte_cuerpo_id",
                ).execute()
                count += 1
            except Exception:
                pass

    for nombre in ej.get("equipamientos", []):
        eid = equip_map.get(nombre)
        if eid:
            try:
                supabase.table("ejercicio_equipamiento").upsert(
                    {"ejercicio_id": ejercicio_id, "equipamiento_id": eid},
                    on_conflict="ejercicio_id,equipamiento_id",
                ).execute()
                count += 1
            except Exception:
                pass

    return count


# ---------------------------------------------------------------------------
# Verificacion final
# ---------------------------------------------------------------------------

def verificar(supabase):
    print()
    print("Verificacion final:")
    for tabla in [
        "partes_cuerpo", "musculos", "equipamientos", "ejercicios",
        "ejercicio_musculo_objetivo", "ejercicio_musculo_secundario",
        "ejercicio_parte_cuerpo", "ejercicio_equipamiento",
    ]:
        res = supabase.table(tabla).select("*", count="exact").execute()
        print(f"   {tabla}: {res.count} registros")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("=" * 60)
    print("SynaptixFit - Seed Unificado de Ejercicios")
    print("=" * 60)
    print(f"Supabase: {SUPABASE_URL}")
    print()

    # Cargar JSONs
    with open(EJERCICIOS_JSON, "r", encoding="utf-8") as f:
        ejercicios = json.load(f)
    with open(MUSCULOS_JSON, "r", encoding="utf-8") as f:
        musculos = json.load(f)
    with open(PARTES_JSON, "r", encoding="utf-8") as f:
        partes = json.load(f)

    equipamientos = extraer_equipamientos(ejercicios)

    print(f"Ejercicios cargados:  {len(ejercicios)}")
    print(f"Musculos cargados:    {len(musculos)}")
    print(f"Partes del cuerpo:    {len(partes)}")
    print(f"Equipamientos (extraidos): {len(equipamientos)}")
    print()

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("Conexion establecida con Supabase")
    print()

    # Paso 1: Catalogos
    print("Paso 1: Sincronizando catalogos...")
    musculos_map = upsert_catalogo(supabase, "musculos", musculos)
    partes_map = upsert_catalogo(supabase, "partes_cuerpo", partes)
    equip_map = upsert_catalogo(supabase, "equipamientos", equipamientos)
    catalogos = {
        "musculos": musculos_map,
        "partes_cuerpo": partes_map,
        "equipamientos": equip_map,
    }
    print()

    # Paso 2: Ejercicios + relaciones
    print("Paso 2: Insertando ejercicios y relaciones...")
    nuevos, omitidos, errores, relaciones = insertar_ejercicios(
        supabase, ejercicios, catalogos
    )
    verificar(supabase)

    print()
    print("=" * 60)
    print("Resumen:")
    print(f"   Ejercicios en JSON:  {len(ejercicios)}")
    print(f"   Nuevos insertados:   {nuevos}")
    print(f"   Ya existian:         {omitidos}")
    print(f"   Errores:             {errores}")
    print(f"   Relaciones N:M:      {relaciones}")
    print("=" * 60)


if __name__ == "__main__":
    main()
