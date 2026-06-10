# Ejercicios Lyfta — Dataset

Dataset estructurado de ejercicios físicos extraídos de [lyfta.com](https://lyfta.com). Contiene videos, previsualizaciones y metadatos (nombre en español, descripción, instrucciones, dificultad, músculos, equipamiento).

---

## Pipeline completo

```
scraping/                              lyfta/
│                                      │
scrape_exercise_images.py              │
  └─ Playwright + stealth              │
  └─ Navega my.lyfta.app/exercises     │
  └─ Categorías → scroll infinito      │
  └─ Extrae URLs de imágenes           │
  └─ Salida: exercise_images.json      │
       │                               │
       ▼                               │
clean_images_json.py                   │
  └─ Filtra solo GymvisualPNG          │
  └─ Convierte _next/image → CDN       │
  └─ Elimina perfiles, duplicados      │
  └─ Salida: exercise_images_clean.json│
       │                               │
       ▼                               │
build_video_json.py                    │
  └─ Deriva URLs de video:             │
  └─ CDN PNG → MP4                     │
  └─ 101 → 201                         │
  └─ _small.png → _.mp4                │
  └─ Salida: exercise_videos.json      │
       │                               │
       ▼                               ▼
       └──── Descarga (.mp4, .png) ────┘
                      │
                      ▼
              video/ + preview/         generate_exercises_json.ps1
                      │                    └─ video_list.txt → ejercicios.json
                      ▼
              polish_exercises_names.ps1
              polish_exercises_names_pass2.ps1
                      │
                      ▼
              dataset_final.json
                      │
                      ▼
              process_videos.ps1
                 └─ preview/ → images/
```

---

## 1. Scraping con Playwright

**Script:** `C:\Users\JLOel\Desktop\scraping\scrape_exercise_images.py`

Obtiene todas las URLs de imágenes de ejercicios desde `my.lyfta.app/exercises` usando Playwright con anti-detección.

```powershell
python scrape_exercise_images.py
```

Cómo funciona:
- Abre un navegador (Chrome/Chromium) con `playwright-stealth` para evitar bloqueos.
- Escanea la zona superior de la página para detectar los botones de categorías por grupo muscular (Chest, Shoulders, Waist, etc.) analizando posición, tamaño y contenido de cada elemento.
- Por cada categoría, hace clic y ejecuta un scroll vertical infinito (hasta 80 pasos) para activar la carga lazy de imágenes.
- En cada paso extrae imágenes de `<img>`, `<picture>`, `srcset`, `data-src`, y `background-image` mediante JavaScript inyectado en la página.
- Soporta autenticación manual (si la página requiere login) y guarda la sesión en `.playwright_session/` para reutilizar.
- Progreso: guarda `exercise_images.json` después de cada categoría.

Parámetros adicionales:

```powershell
python scrape_exercise_images.py --headless          # Sin ventana (requiere sesión guardada)
python scrape_exercise_images.py --max-categories 3   # Solo 3 categorías
python scrape_exercise_images.py --reset-auth         # Borrar sesión guardada
python scrape_exercise_images.py --cookies cookies.txt # Importar cookies
```

Las URLs crudas pasan por un proxy de Next.js (`/next/image?url=...&w=1200&q=75`), no son las URLs directas del CDN.

---

## 2. Limpiar el JSON de imágenes

**Script:** `C:\Users\JLOel\Desktop\scraping\clean_images_json.py`

Toma el JSON crudo del scraper y lo limpia:

```powershell
python clean_images_json.py
```

Qué hace:
- Convierte las URLs del proxy de Next.js a URLs directas del CDN (`apilyfta.com/static/GymvisualPNG/...`).
- Filtra solo imágenes de tipo `GymvisualPNG` (ejercicios).
- Descarta fotos de perfil (`profilePic`), iconos SVG de músculos y duplicados por resolución (conserva w=1200, descarta w=640).
- Extrae el nombre legible del ejercicio desde el nombre del archivo.

Salida: `exercise_images_clean.json` con URLs CDN directas.

---

## 3. Derivar las URLs de los videos

**Script:** `C:\Users\JLOel\Desktop\scraping\build_video_json.py`

Convierte cada URL de imagen en su URL de video correspondiente:

```powershell
python build_video_json.py
```

Reglas de transformación:

| | Imagen | Video |
|---|---|---|
| CDN | `apilyfta.com/static/GymvisualPNG/` | `apilyfta.com/static/GymvisualMP4/` |
| ID | `{XXXX}101-` | `{XXXX}201-` |
| Sufijo | `_small.png` | `_.mp4` |

Ejemplo:
```
Imagen: https://apilyfta.com/static/GymvisualPNG/00251101-Barbell-Bench-Press_Chest-FIX2_small.png
Video:  https://apilyfta.com/static/GymvisualMP4/00251201-Barbell-Bench-Press_Chest-FIX2_.mp4
```

Salida: `exercise_videos.json` con las URLs de video, nombre del ejercicio y categoría.

---

## 4. Descarga de archivos

Con las URLs de `exercise_images_clean.json` y `exercise_videos.json` se descargaron todos los archivos:

```powershell
# Descarga de imágenes (preview/)
$images = Get-Content .\exercise_images_clean.json | ConvertFrom-Json
$images | ForEach-Object {
    $filename = $_.url.Split('/')[-1]
    Invoke-WebRequest -Uri $_.url -OutFile "D:\Dataset\Deporte\lyfta\preview\$filename"
}

# Descarga de videos
$videos = Get-Content .\exercise_videos.json | ConvertFrom-Json
$videos | ForEach-Object {
    $filename = $_.url.Split('/')[-1]
    Invoke-WebRequest -Uri $_.url -OutFile "D:\Dataset\Deporte\lyfta\video\$filename"
}
```

Resultado:
- `video/` → 682 archivos `.mp4`
- `preview/` → 3661+ archivos `.png`

---

## 5. Generar la lista numerada de videos

Con los videos descargados, se generó `video_list.txt`:

```powershell
$videos = Get-ChildItem D:\Dataset\Deporte\lyfta\video -Filter "*.mp4" | Sort-Object Name
$i = 1
$lines = foreach ($v in $videos) {
    "$i. $([System.IO.Path]::GetFileNameWithoutExtension($v.Name))"
    $i++
}
$lines | Out-File D:\Dataset\Deporte\lyfta\video_list.txt -Encoding utf8
```

Salida (`video_list.txt`):
```
1. 00161201-Assisted-Prone-Hamstring_Thighs_
2. 00251201-Barbell-Bench-Press_Chest-FIX2_
3. 00331201-Barbell-Decline-Bench-Press_Chest-FIX_
...
```

---

## 6. Generar el dataset JSON

**Script:** `D:\Dataset\Deporte\lyfta\generate_exercises_json.ps1`

```powershell
.\generate_exercises_json.ps1
```

Toma `video_list.txt` y produce `ejercicios.json`. Para cada línea:
1. Extrae el slug del ejercicio.
2. Limpia tokens de ruido: `(female)`, `(male)`, `-FIX`, `VERSION-*`, `WRONG-RIGHT`.
3. Detecta el equipamiento principal (barra, mancuerna, polea, kettlebell, etc.) mediante `$EquipmentMap`.
4. Traduce el nombre del inglés al español usando mapas de equipamiento, modificadores y posición.
5. Asigna categoría, partes del cuerpo, músculos objetivo/secundarios, dificultad y finalidad según reglas sobre el slug.
6. Genera las URLs apuntando a Cloudflare R2.

---

## 7. Pulir los nombres en español

Dos scripts de refinamiento:

### Primera pasada — `polish_exercises_names.ps1`

```powershell
.\polish_exercises_names.ps1
```

- Traduce `grip` → `agarre`, `squeeze` → `apretón`, `weighted` → `con lastre`
- Reordena `Sentado ... press` → `Press sentado ...`
- Normaliza mayúsculas y acrónimos (EZ, V, Z)

### Segunda pasada — `polish_exercises_names_pass2.ps1`

```powershell
.\polish_exercises_names_pass2.ps1
```

- Traduce `push-up` → `flexión`, `bench dips` → `fondos en banco`, `stiff leg deadlift` → `peso muerto piernas rígidas`
- Reordena `Sentado por encima de la cabeza <mov>` → `<Mov> sentado por encima de la cabeza`
- Corrige términos en inglés residuales

Resultado: `dataset_final.json` (~28.6k líneas, 682 ejercicios).

---

## 8. Mover previsualizaciones coincidentes

**Script:** `D:\Dataset\Deporte\lyfta\process_videos.ps1`

```powershell
.\process_videos.ps1
```

Busca en `preview/` las imágenes cuyo nombre descriptivo coincide con algún video de `video/` (normalizando prefijos numéricos y sufijos como `_small`) y las mueve a `images/`.

De 3661+ previsualizaciones, movió 686. Hay 4 ejercicios con 2 previsualizaciones cada uno (distinto ID numérico pero mismo nombre descriptivo).

---

## Formato de salida (`dataset_final.json`)

```json
{
  "fuente": "lyfta",
  "nombre_ejercicio": "Press de banca con barra",
  "descripcion": "Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.",
  "instrucciones": [
    "Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.",
    "Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.",
    "Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio."
  ],
  "dificultad": "intermedio",
  "finalidad": ["Fuerza", "Hipertrofia"],
  "partes_cuerpo": ["Tren superior", "Pecho"],
  "musculos_objetivo": ["Pectoral mayor"],
  "musculos_secundarios": ["Deltoides anterior", "Tríceps braquial"],
  "equipamientos": ["barra"],
  "url_video": "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00251201-Barbell-Bench-Press_Chest-FIX2_.mp4",
  "url_preview": "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00251201-Barbell-Bench-Press_Chest-FIX2_.webp"
}
```

## Archivos del proyecto

| Archivo / Carpeta | Propósito |
|---|---|
| `C:\Users\JLOel\Desktop\scraping\scrape_exercise_images.py` | Scraper con Playwright para my.lyfta.app |
| `C:\Users\JLOel\Desktop\scraping\clean_images_json.py` | Limpia y normaliza las URLs de imágenes |
| `C:\Users\JLOel\Desktop\scraping\build_video_json.py` | Deriva URLs de video desde las de imagen |
| `video/` | Videos `.mp4` originales (682) |
| `preview/` | Previsualizaciones `.png` originales |
| `images/` | Previsualizaciones que coinciden con algún video (686) |
| `video_list.txt` | Lista numerada de los 682 videos |
| `ejercicios.json` | JSON intermedio generado desde `video_list.txt` |
| `dataset_final.json` | JSON final con nombres pulidos |
| `process_videos.ps1` | Mueve previsualizaciones coincidentes |
| `generate_exercises_json.ps1` | Genera el dataset estructurado |
| `polish_exercises_names.ps1` | Primera pasada de limpieza de nombres |
| `polish_exercises_names_pass2.ps1` | Segunda pasada de limpieza de nombres |
