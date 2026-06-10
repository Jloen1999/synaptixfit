"""
seed_completo.py - Seed completo desde dataset_final.json.

REEJECUTABLE. Fuente unica de verdad: supabase/dataset_final.json.
Reemplazo definitivo de migracion 0038 + seed_todo.py.

Flujo:
  1. Construye mapas nombre->id de catalogos (con fallback case-insensitive)
  2. DELETE FROM ejercicios (cascade -> borra relaciones N:M)
  3. INSERT 909 ejercicios desde dataset_final.json
  4. INSERT todas las relaciones N:M
  5. Verificacion final
"""

import json, os, sys
from pathlib import Path

try:
    from supabase import create_client
except ImportError:
    print("Falta 'supabase'. pip install supabase")
    sys.exit(1)

try:
    from dotenv import load_dotenv
except ImportError:
    pass
else:
    script_dir = Path(__file__).resolve().parent
    for env_file in [
        script_dir / ".env",
        script_dir.parent / ".env",
        script_dir.parent / "app" / ".env",
    ]:
        if env_file.exists():
            load_dotenv(env_file, override=False)
            break

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
if not SUPABASE_URL or not SUPABASE_KEY:
    print("ERROR: SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY no configurados")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).resolve().parent
EJERCICIOS_JSON = SCRIPT_DIR / "dataset_final.json"
MUSCULOS_JSON = SCRIPT_DIR / "musculos.json"
PARTES_JSON = SCRIPT_DIR / "partes_cuerpo.json"
EQUIP_JSON = SCRIPT_DIR / "equipamientos.json"

BATCH_SIZE = 50


def load_json(path: Path, label: str):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    print(f"  {label}: {len(data)} registros")
    return data


def build_map(supabase, table: str, json_path: Path, label: str):
    """Build name->id map from DB catalog with case-insensitive fallback."""
    items = load_json(json_path, label)
    resp = supabase.table(table).select("id, nombre").execute()
    db_map = {row["nombre"]: row["id"] for row in resp.data}
    ci_map = {k.lower(): v for k, v in db_map.items()}

    json_names = {item["nombre"] for item in items}
    result = {}
    missing = []
    for name in json_names:
        if name in db_map:
            result[name] = db_map[name]
        elif name.lower() in ci_map:
            result[name] = ci_map[name.lower()]
        else:
            missing.append(name)

    if missing:
        print(f"  [ERROR] {label}: {len(missing)} nombres sin match:")
        for n in sorted(missing)[:10]:
            print(f"         - {n}")
    else:
        print(f"  [OK] {label}: {len(result)}/{len(items)} mapeados")
    return result, missing


def main():
    print("=" * 60)
    print("SynaptixFit - Seed completo desde dataset_final.json")
    print("=" * 60)

    if "--generate-migration" in sys.argv:
        print("Modo: generar migracion SQL (sin conectar a BD)")
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "generate_migration_0042",
            SCRIPT_DIR / "generate_migration_0042.py",
        )
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.generar_migracion()
        return

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print(f"Conectado a {SUPABASE_URL}\n")

    # Load all JSONs
    print("Cargando JSONs...")
    ejercicios = load_json(EJERCICIOS_JSON, "Ejercicios")
    print()

    # Build catalog maps
    print("Construyendo mapas de catalogo...")
    musculos_map, m_miss = build_map(supabase, "musculos", MUSCULOS_JSON, "Musculos")
    partes_map, p_miss = build_map(supabase, "partes_cuerpo", PARTES_JSON, "Partes cuerpo")
    equip_map, e_miss = build_map(supabase, "equipamientos", EQUIP_JSON, "Equipamientos")

    if m_miss or p_miss or e_miss:
        print("\n[ERROR] Hay nombres en dataset_final.json sin correspondencia en catalogos.")
        print("Corrige catalogos o JSON antes de continuar.")
        sys.exit(1)
    print()

    # Show current state
    print("Estado actual en BD:")
    cur = supabase.table("ejercicios").select("*", count="exact").execute()
    print(f"  ejercicios: {cur.count}")
    for t in ["ejercicio_musculo_objetivo", "ejercicio_musculo_secundario",
              "ejercicio_parte_cuerpo", "ejercicio_equipamiento"]:
        c = supabase.table(t).select("*", count="exact").execute()
        print(f"  {t}: {c.count}")

    # Confirm (skip prompt if --force passed)
    print()
    if "--force" not in sys.argv:
        confirm = input("Borrar todos los datos de ejercicios y reinsertar? (escribe SI): ")
        if confirm != "SI":
            print("Cancelado.")
            return
    print()

    # ---- DELETE via cascade ----
    print("Paso 1: Eliminando datos actuales...")
    try:
        supabase.table("seleccion_de_ejercicios").delete().neq(
            "id", "00000000-0000-0000-0000-000000000000"
        ).execute()
        print("  seleccion_de_ejercicios: limpiado")
    except Exception as e:
        print(f"  seleccion_de_ejercicios: {e}")
    try:
        supabase.table("ejercicios").delete().neq(
            "id", "00000000-0000-0000-0000-000000000000"
        ).execute()
        print("  [OK] Datos de ejercicios eliminados (cascade)")
    except Exception as e:
        print(f"  [ERROR] {e}")
        sys.exit(1)

    # ---- INSERT ejercicios ----
    print("\nPaso 2: Insertando ejercicios...")
    ejercicio_ids = []

    # Build insert rows
    rows = []
    for ej in ejercicios:
        rows.append({
            "nombre": ej["nombre_ejercicio"],
            "url_gif": ej.get("url_video", ""),
            "url_preview": ej.get("url_preview", ""),
            "instrucciones": ej.get("instrucciones", []),
            "dificultad": ej.get("dificultad", "principiante"),
            "descripcion": ej.get("descripcion", ""),
            "finalidad": ej.get("finalidad", []),
            "modalidad_entrenamiento": ej.get("modalidad_entrenamiento", "fuerza"),
            "tipo_medicion": ej.get("tipo_medicion", ["repeticiones"]),
            "es_circuito": ej.get("es_circuito", False),
        })

    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i:i + BATCH_SIZE]
        try:
            resp = supabase.table("ejercicios").insert(
                batch, returning="representation"
            ).execute()
            for r in resp.data:
                ejercicio_ids.append(r["id"])
        except Exception as e:
            print(f"  [ERROR] lote {i//BATCH_SIZE + 1}: {e}")
            # Fallback: one by one
            for j, row in enumerate(batch):
                try:
                    r = supabase.table("ejercicios").insert(
                        row, returning="representation"
                    ).execute()
                    ejercicio_ids.append(r.data[0]["id"])
                except Exception as e2:
                    print(f"    Error en [{i+j}] {row['nombre'][:30]}: {e2}")
        # Progress
        done = len(ejercicio_ids)
        if done % 100 == 0 or done == len(rows):
            print(f"  Insertados {done}/{len(rows)}")

    if len(ejercicio_ids) != len(ejercicios):
        print(f"\n[ERROR] Solo se insertaron {len(ejercicio_ids)}/{len(ejercicios)}. Abortando.")
        sys.exit(1)
    print(f"  [OK] {len(ejercicio_ids)} ejercicios insertados")

    # Build CI lookup helpers (dataset_final.json usa lowercase en equipamientos)
    musculos_ci = {k.lower(): v for k, v in musculos_map.items()}
    partes_ci = {k.lower(): v for k, v in partes_map.items()}
    equip_ci = {k.lower(): v for k, v in equip_map.items()}

    def _lookup(nombre, exact, ci):
        return exact.get(nombre) or ci.get(nombre.lower())

    print("\nPaso 3: Insertando relaciones N:M...")
    total_rel = 0

    for idx, (ej, eid) in enumerate(zip(ejercicios, ejercicio_ids)):
        for nombre in ej.get("musculos_objetivo", []):
            mid = _lookup(nombre, musculos_map, musculos_ci)
            if mid:
                try:
                    supabase.table("ejercicio_musculo_objetivo").insert(
                        {"ejercicio_id": eid, "musculo_id": mid}
                    ).execute()
                    total_rel += 1
                except Exception:
                    pass

        for nombre in ej.get("musculos_secundarios", []):
            mid = _lookup(nombre, musculos_map, musculos_ci)
            if mid:
                try:
                    supabase.table("ejercicio_musculo_secundario").insert(
                        {"ejercicio_id": eid, "musculo_id": mid}
                    ).execute()
                    total_rel += 1
                except Exception:
                    pass

        for nombre in ej.get("partes_cuerpo", []):
            pid = _lookup(nombre, partes_map, partes_ci)
            if pid:
                try:
                    supabase.table("ejercicio_parte_cuerpo").insert(
                        {"ejercicio_id": eid, "parte_cuerpo_id": pid}
                    ).execute()
                    total_rel += 1
                except Exception:
                    pass

        for nombre in ej.get("equipamientos", []):
            eid_e = _lookup(nombre, equip_map, equip_ci)
            if eid_e:
                try:
                    supabase.table("ejercicio_equipamiento").insert(
                        {"ejercicio_id": eid, "equipamiento_id": eid_e}
                    ).execute()
                    total_rel += 1
                except Exception:
                    pass

        if (idx + 1) % 100 == 0:
            print(f"  Procesados {idx + 1}/{len(ejercicios)} ({total_rel} relaciones)")

    print(f"  [OK] {total_rel} relaciones insertadas")

    # ---- Verify ----
    print("\nPaso 4: Verificacion...")
    for tabla in [
        "ejercicios",
        "ejercicio_musculo_objetivo",
        "ejercicio_musculo_secundario",
        "ejercicio_parte_cuerpo",
        "ejercicio_equipamiento",
    ]:
        c = supabase.table(tabla).select("*", count="exact").execute()
        print(f"  {tabla}: {c.count}")

    # Check Aperturas con mancuerna
    print("\nVerificando equipamiento de 'Aperturas con mancuerna'...")
    resp = supabase.table("v_ejercicios_completos").select(
        "nombre, equipamientos"
    ).eq("nombre", "Aperturas con mancuerna").limit(3).execute()
    for row in resp.data:
        eq_names = row["equipamientos"]
        print(f"  '{row['nombre'][:40]}' -> equip: {eq_names}")
        if not eq_names:
            print("  [WARNING] Sin equipamiento!")

    print("\n" + "=" * 60)
    print("Seed completado!")
    print("=" * 60)


if __name__ == "__main__":
    main()
