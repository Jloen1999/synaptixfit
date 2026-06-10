"""
OBSOLETO: Reemplazado por seed_completo.py + generate_migration_0042.py.
Los datos correctos estan en supabase/dataset_final.json (corregido, 909 ejercicios).
Para re-seed completo: python supabase/seed_completo.py --force

seed_todo.py - Restaurador de relaciones N:M para SynaptixFit.

Los catalogos y ejercicios se insertan via migraciones SQL (0034-0038).
Este script unicamente restaura las relaciones N:M (musculos objetivo,
musculos secundarios, partes del cuerpo, equipamientos) a partir
del dataset final (dataset_final.json).

Flujo:
   1. Verifica que catalogos y ejercicios existan en la BD
   2. Inserta relaciones N:M para cada ejercicio
   3. Resumen final
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
EJERCICIOS_JSON = SCRIPT_DIR / "dataset_final.json"
MUSCULOS_JSON = SCRIPT_DIR / "musculos.json"
PARTES_JSON = SCRIPT_DIR / "partes_cuerpo.json"
EQUIP_JSON = SCRIPT_DIR / "equipamientos.json"


def cargar_catalogo(supabase, tabla: str, json_path: Path) -> dict:
    """Carga nombres del JSON y los mapea a IDs desde la BD."""
    with open(json_path, "r", encoding="utf-8") as f:
        items_json = json.load(f)
    nombres_json = {item["nombre"] for item in items_json}

    resp = supabase.table(tabla).select("id, nombre").execute()
    mapa = {}
    for row in resp.data:
        mapa[row["nombre"]] = row["id"]

    faltantes = nombres_json - set(mapa.keys())
    if faltantes:
        print(f"  [AVISO] {tabla}: {len(faltantes)} nombres faltantes en BD:")
        for n in sorted(faltantes):
            print(f"         - {n}")
    else:
        print(f"  [OK] {tabla}: {len(nombres_json)}/{len(items_json)} en BD")

    return mapa, len(nombres_json), len(faltantes)


# ---------------------------------------------------------------------------
# Insercion de relaciones N:M
# ---------------------------------------------------------------------------

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
    print("SynaptixFit - Restaurador de Relaciones N:M")
    print("=" * 60)
    print(f"Supabase: {SUPABASE_URL}")
    print()

    # Cargar JSONs
    with open(EJERCICIOS_JSON, "r", encoding="utf-8") as f:
        ejercicios = json.load(f)
    with open(MUSCULOS_JSON, "r", encoding="utf-8") as f:
        musculos_json = json.load(f)
    with open(PARTES_JSON, "r", encoding="utf-8") as f:
        partes_json = json.load(f)
    with open(EQUIP_JSON, "r", encoding="utf-8") as f:
        equip_json = json.load(f)

    print(f"Ejercicios en JSON:  {len(ejercicios)}")
    print(f"Musculos en JSON:    {len(musculos_json)}")
    print(f"Partes del cuerpo:   {len(partes_json)}")
    print(f"Equipamientos:       {len(equip_json)}")
    print()

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("Conexion establecida con Supabase")
    print()

    # Paso 1: Verificar catalogos
    print("Paso 1: Verificando catalogos (insertados por migraciones 0035-0037)...")
    musculos_map, total_m, falt_m = cargar_catalogo(supabase, "musculos", MUSCULOS_JSON)
    partes_map, total_p, falt_p = cargar_catalogo(supabase, "partes_cuerpo", PARTES_JSON)
    equip_map, total_e, falt_e = cargar_catalogo(supabase, "equipamientos", EQUIP_JSON)

    if falt_m or falt_p or falt_e:
        print("\n  [ERROR] Faltan catalogos. Ejecuta primero las migraciones 0034-0038.")
        sys.exit(1)
    print()

    # Paso 2: Verificar ejercicios existentes
    print("Paso 2: Verificando ejercicios (insertados por migracion 0038)...")
    resp = supabase.table("ejercicios").select("id, nombre").order("id").execute()
    bd_rows = resp.data

    if len(bd_rows) != len(ejercicios):
        print(f"  [ERROR] BD tiene {len(bd_rows)} ejercicios, JSON tiene {len(ejercicios)}.")
        print("   Re-ejecuta la migracion 0038.")
        sys.exit(1)
    else:
        print(f"  [OK] {len(bd_rows)}/{len(ejercicios)} ejercicios en BD")
    print()

    # Paso 3: Restaurar relaciones N:M (por orden de insercion)
    print("Paso 3: Restaurando relaciones N:M...")
    total_relaciones = 0
    for ej, row in zip(ejercicios, bd_rows):
        eid = row["id"]
        total_relaciones += insertar_relaciones(
            supabase, eid, ej, musculos_map, partes_map, equip_map
        )

    print(f"  [OK] {total_relaciones} relaciones insertadas/actualizadas")
    print()

    verificar(supabase)

    print()
    print("=" * 60)
    print("Resumen:")
    print(f"   Ejercicios en JSON:  {len(ejercicios)}")
    print(f"   Relaciones N:M:      {total_relaciones}")
    print("=" * 60)


if __name__ == "__main__":
    main()
