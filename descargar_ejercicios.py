import requests
import json

def descargar_ejercicios():
    print("Iniciando descarga desde Wger API...")
    # El endpoint exerciseinfo trae la info completa, incluyendo imágenes. language=4 es Español.
    url = "https://wger.de/api/v2/exerciseinfo/?language=4&limit=100"
    ejercicios = []

    while url:
        print(f"Descargando lote: {url}")
        respuesta = requests.get(url)
        
        if respuesta.status_code != 200:
            print("Error al conectar con la API")
            break
            
        datos = respuesta.json()
        ejercicios.extend(datos['results'])
        url = datos.get('next') # Paginación: va a la siguiente página si existe

    # Guardar en un archivo JSON local
    with open('ejercicios_synaptixfit.json', 'w', encoding='utf-8') as f:
        json.dump(ejercicios, f, ensure_ascii=False, indent=4)
        
    print(f"¡Éxito! {len(ejercicios)} ejercicios guardados en ejercicios_synaptixfit.json")

if __name__ == "__main__":
    descargar_ejercicios()