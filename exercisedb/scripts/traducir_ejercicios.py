import json
import time
from deep_translator import GoogleTranslator

ARCHIVO_ENTRADA = "exercises.json" # Cambia esto si tu archivo se llama distinto
ARCHIVO_SALIDA = "synaptix_exercisedb_es.json"

print("--- INICIANDO PIPELINE DE TRADUCCIÓN DE EXERCISEDB ---")

# 1. Cargar el JSON original
try:
    with open(ARCHIVO_ENTRADA, "r", encoding="utf-8") as f:
        ejercicios = json.load(f)
except FileNotFoundError:
    print(f"Error: No se encuentra el archivo {ARCHIVO_ENTRADA}.")
    exit()

traductor = GoogleTranslator(source='en', target='es')
ejercicios_traducidos = 0

print(f"Se detectaron {len(ejercicios)} ejercicios. Esto tomará unos minutos...")

# 2. Recorrer y traducir cada ejercicio
for ej in ejercicios:
    print(f"Traduciendo: {ej.get('name', 'Unknown')} (ID: {ej.get('exerciseId', '')})...")
    
    try:
        # A) Traducir el nombre principal
        if "name" in ej and ej["name"]:
            ej["name"] = traductor.translate(ej["name"])
        
        # B) Traducir las listas cortas (músculos, partes del cuerpo, equipamiento)
        campos_lista = ["targetMuscles", "bodyParts", "equipments", "secondaryMuscles"]
        for campo in campos_lista:
            if campo in ej and isinstance(ej[campo], list):
                # Recorremos cada palabra dentro de la lista y la traducimos
                ej[campo] = [traductor.translate(item) for item in ej[campo]]
                
        # C) Traducir las instrucciones paso a paso
        if "instructions" in ej and isinstance(ej["instructions"], list):
            instrucciones_trad = []
            for paso in ej["instructions"]:
                instrucciones_trad.append(traductor.translate(paso))
            ej["instructions"] = instrucciones_trad

        ejercicios_traducidos += 1
        
        # Pausa de seguridad de 0.5s para no saturar los servidores de Google Translate
        time.sleep(0.5)
        
    except Exception as e:
        print(f"  -> Error al traducir el ejercicio {ej.get('exerciseId')}: {e}")

# 3. Guardar el nuevo JSON completamente en español
with open(ARCHIVO_SALIDA, "w", encoding="utf-8") as f:
    json.dump(ejercicios, f, ensure_ascii=False, indent=4)

print(f"\n¡Proceso completado! Se han traducido {ejercicios_traducidos} ejercicios.")
print(f"Tu base de datos 100% en español te espera en el archivo: {ARCHIVO_SALIDA}")