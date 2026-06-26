#!/usr/bin/env python3
"""
Sincroniza la columna valor_met en la tabla ejercicios de Supabase
con los valores calculados en dataset_final.json.

Hace match por nombre exacto del ejercicio (case-insensitive).
Los ejercicios sin match conservan el default 6.0.
"""

import json
import os
import sys

try:
    from dotenv import load_dotenv
    from supabase import create_client
except ImportError:
    print("ERROR: pip install python-dotenv supabase")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
JSON_PATH = os.path.join(SCRIPT_DIR, "dataset_final.json")

for p in [
    os.path.join(PROJECT_ROOT, "app", ".env"),
    os.path.join(PROJECT_ROOT, ".env"),
]:
    if os.path.exists(p):
        load_dotenv(p)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("ERROR: Definir SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en .env")
    sys.exit(1)

client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Cargar JSON
with open(JSON_PATH, "r", encoding="utf-8") as f:
    dataset = json.load(f)

met_map: dict[str, float] = {}
for ej in dataset:
    nombre = ej["nombre_ejercicio"].strip()
    met_map[nombre.lower()] = ej.get("valor_met", 6.0)

print(f"Cargados {len(met_map)} ejercicios del JSON con MET")

# Obtener todos los ejercicios de la BD
db_ejercicios = (
    client.table("ejercicios")
    .select("id, nombre, valor_met")
    .limit(1000)
    .execute()
)
total = len(db_ejercicios.data)
print(f"Ejercicios en BD: {total}")

actualizados = 0
sin_match = 0

for row in db_ejercicios.data:
    nombre_db = (row.get("nombre") or "").strip().lower()
    met_json = met_map.get(nombre_db)
    if met_json is not None:
        met_actual = (row.get("valor_met") or 6.0)
        if abs(met_actual - met_json) > 0.01:
            client.table("ejercicios").update({"valor_met": met_json}).eq(
                "id", row["id"]
            ).execute()
            actualizados += 1
    else:
        sin_match += 1

print(f"Actualizados:  {actualizados}")
print(f"Sin match:     {sin_match} (conservan default 6.0)")
print(f"Sin cambios:   {total - actualizados - sin_match}")
