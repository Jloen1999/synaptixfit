import json
import time
from deep_translator import GoogleTranslator

# Cámbialo por el nombre real de tu archivo descargado (ej. muscles.json o bodyParts.json)
ARCHIVO_ENTRADA = "bodyParts.json" 
ARCHIVO_SALIDA = "synaptix_partesCuerpo_es.json"

print("--- INICIANDO TRADUCCIÓN DE CATÁLOGO DE PARTES DEL CUERPO ---")

# 1. Cargar el JSON original
try:
    with open(ARCHIVO_ENTRADA, "r", encoding="utf-8") as f:
        partesCuerpo = json.load(f)
except FileNotFoundError:
    print(f"Error: No se encuentra el archivo '{ARCHIVO_ENTRADA}'.")
    exit()

traductor = GoogleTranslator(source='en', target='es')
elementos_traducidos = 0

print(f"Se detectaron {len(partesCuerpo)} elementos. Iniciando traducción...\n")

# 2. Recorrer y traducir cada elemento
for item in partesCuerpo:
    if "name" in item and item["name"]:
        nombre_original = item["name"]
        
        try:
            # Traducimos el valor de la clave "name"
            item["name"] = traductor.translate(nombre_original).lower() # Lo pasamos a minúsculas por consistencia
            print(f"  -> {nombre_original} traducido a: {item['name']}")
            elementos_traducidos += 1
            
            # Pausa de seguridad de 0.3s (al ser textos cortos, podemos ir un poco más rápido)
            time.sleep(0.3)
            
        except Exception as e:
            print(f"  -> Error al traducir '{nombre_original}': {e}")

# 3. Guardar el nuevo JSON completamente en español
with open(ARCHIVO_SALIDA, "w", encoding="utf-8") as f:
    json.dump(partesCuerpo, f, ensure_ascii=False, indent=4)

print(f"\n¡Proceso completado! Se han traducido {elementos_traducidos} elementos.")
print(f"Tu catálogo en español te espera en el archivo: {ARCHIVO_SALIDA}")