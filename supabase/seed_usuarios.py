#!/usr/bin/env python3
"""
seed_usuarios.py - Crea usuarios mock (Estudiantes) en SynaptixFit para propósitos de prueba.
"""

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

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY", "")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Falta SUPABASE_URL o SUPABASE_ANON_KEY en las variables de entorno.")
    sys.exit(1)

def main():
    print("=" * 60)
    print("🎓 SynaptixFit - Seed de Usuarios Mock (Estudiantes)")
    print("=" * 60)

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("🔌 Conexión establecida con Supabase")
    print()

    estudiantes_mock = [
        {
            "email": "carlos.estudiante@universidad.edu",
            "password": "Password123!",
            "full_name": "Carlos Mendoza",
            "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Carlos"
        },
        {
            "email": "ana.estudiante@universidad.edu",
            "password": "Password123!",
            "full_name": "Ana Sofia Ramirez",
            "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Ana"
        },
        {
            "email": "miguel.estudiante@universidad.edu",
            "password": "Password123!",
            "full_name": "Miguel Angel Torres",
            "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Miguel"
        },
        {
            "email": "laura.estudiante@universidad.edu",
            "password": "Password123!",
            "full_name": "Laura Gomez",
            "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Laura"
        },
        {
            "email": "diego.estudiante@universidad.edu",
            "password": "Password123!",
            "full_name": "Diego Fernandez",
            "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Diego"
        }
    ]

    print("🧑‍🎓 Creando usuarios en auth.users (el trigger los pasará a public.usuarios)...")
    for est in estudiantes_mock:
        try:
            # Check if user already exists in public.usuarios
            res = supabase.table("usuarios").select("email").eq("email", est["email"]).execute()
            if len(res.data) > 0:
                print(f"  ⚠️  Usuario ya existe en BD: {est['email']}")
            else:
                user = supabase.auth.sign_up({
                    "email": est["email"],
                    "password": est["password"],
                    "options": {
                        "data": {
                            "full_name": est["full_name"],
                            "avatar_url": est["avatar_url"],
                            "role": "Estudiante"
                        }
                    }
                })
                print(f"  ✅ Usuario creado: {est['full_name']} ({est['email']})")
                
        except Exception as e:
            print(f"  ❌ Error creando {est['email']}: {e}")

    print()
    
    # Verificar en public.usuarios
    print("🔍 Verificando en public.usuarios:")
    res = supabase.table("usuarios").select("nombre_completo, email").execute()
    for row in res.data:
        print(f"   - {row['nombre_completo']} ({row['email']})")

    print()
    print("✅ ¡Seed de usuarios completado exitosamente!")
    print("=" * 60)

if __name__ == "__main__":
    main()
