#!/usr/bin/env python3
"""Aplica migraciones pendientes a BD local (Docker) y remota (Supabase)."""
import os, sys

try:
    import psycopg2
    from dotenv import load_dotenv
except ImportError:
    print("ERROR: pip install psycopg2-binary python-dotenv")
    sys.exit(1)

load_dotenv(dotenv_path='app/.env')

MIGRATIONS = [
    "supabase/migrations/202606120050_dependencias_retos.sql",
    "supabase/migrations/202606140001_v_analitica_semanal.sql",
]

LOCAL_DSN = "dbname=postgres user=postgres password=postgres host=127.0.0.1 port=54322"

project_ref = "bimivpacrelltwfwrdnq"
db_password = os.getenv("SUPABASE_DB_PASSWORD", "").strip().rstrip('.')
REMOTE_DSN = f"dbname=postgres user=postgres password={db_password} host=db.{project_ref}.supabase.co port=5432 sslmode=require"

results = {}


def apply(dsn, label):
    print(f"\n--- {label} ---")
    try:
        conn = psycopg2.connect(dsn)
        conn.autocommit = True
        print("  Conectado OK")
    except Exception as e:
        print(f"  ERROR conexion: {e}")
        return False

    ok = True
    for mig_file in MIGRATIONS:
        name = os.path.basename(mig_file)
        try:
            with open(mig_file, 'r', encoding='utf-8') as f:
                sql = f.read()
            with conn.cursor() as cur:
                cur.execute(sql)
            print(f"  Aplicada: {name}")
        except Exception as e:
            msg = str(e)
            if "already exists" in msg.lower() or "already exists" in str(getattr(e, 'diag', type('', (), {})).__dict__.get('message_primary', '')):
                print(f"  Ya existe (idempotente): {name}")
            else:
                print(f"  ERROR en {name}: {msg}")
                ok = False
                break

    conn.close()
    results[label] = ok
    return ok


print("=== SynaptixFit — Aplicar migraciones ===\n")

apply(LOCAL_DSN, "LOCAL (Docker)")

apply(REMOTE_DSN, "REMOTO (bimivpacrelltwfwrdnq)")

print("\n=== RESUMEN ===")
for label, ok in results.items():
    print(f"  {label}: {'OK' if ok else 'FALLOS'}")
