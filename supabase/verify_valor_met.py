import json, os, sys
from dotenv import load_dotenv
from supabase import create_client

for p in [
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "app", ".env"),
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
]:
    if os.path.exists(p):
        load_dotenv(p)

c = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_SERVICE_ROLE_KEY"))

# Muestra distribucion de MET en BD
r = c.table("ejercicios").select("valor_met, modalidad_entrenamiento, es_circuito").limit(1000).execute()
dist = {}
for row in r.data:
    met = row["valor_met"]
    dist[met] = dist.get(met, 0) + 1

print("Distribucion MET en BD:")
for k in sorted(dist):
    print(f"  MET {k:4.1f} -> {dist[k]:4d}")

print()

# Muestra ejemplos de cada valor MET
for met_val in sorted(dist):
    r2 = c.table("ejercicios").select("nombre, modalidad_entrenamiento, es_circuito").eq("valor_met", met_val).limit(2).execute()
    print(f"--- MET {met_val} ---")
    for row in r2.data:
        print(f"  {row['nombre'][:55]:55s} | {row['modalidad_entrenamiento']:12s} | circ={row['es_circuito']}")
    print()
