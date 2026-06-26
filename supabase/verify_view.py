import os, sys
from dotenv import load_dotenv
from supabase import create_client

for p in [
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "app", ".env"),
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
]:
    if os.path.exists(p):
        load_dotenv(p)

c = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_SERVICE_ROLE_KEY"))

# Verificar que la vista incluye valor_met
r = c.table("v_ejercicios_completos").select("nombre, valor_met").limit(3).execute()
print("v_ejercicios_completos (primeros 3):")
for row in r.data:
    print(f"  {row['nombre'][:50]:50s} | MET={row.get('valor_met', 'NO EXISTE')}")

# Verificar que la migracion se aplico
r2 = c.table("ejercicios").select("valor_met").limit(1).execute()
print("\nColumna valor_met en ejercicios:", "valor_met" in (r2.data[0] if r2.data else {}))
