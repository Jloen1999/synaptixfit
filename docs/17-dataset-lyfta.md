# 17 - Dataset Lyfta (Ejercicios con Video)

**Proyecto:** SynaptixFit  
**Versión:** 1.0  
**Fecha:** 05-06-2026  
**Fuente:** [lyfta.com](https://lyfta.com) (my.lyfta.app)  
**Referencia:** [04-data-model.md](04-data-model.md), [13-maintenance.md](13-maintenance.md)

---

## 1. Descripción General

Dataset estructurado de **682 ejercicios físicos** en español, extraídos de la plataforma Lyfta mediante scraping automatizado y procesados a través de un pipeline de 8 etapas. Cada ejercicio incluye video MP4, previsualización y metadatos completos: nombre, descripción, instrucciones (3 pasos), dificultad, finalidad, partes del cuerpo, músculos (objetivo y secundarios), equipamientos y URLs alojadas en Cloudflare R2.

El dataset está incorporado en la migración base `202606060049_esquema_base.sql` (~12K líneas) que carga directamente los 909 ejercicios en Supabase. El script histórico `supabase/seed_ejercicios.py` fue eliminado en la Fase 0 del Plan Maestro.

---

## 2. Pipeline de Procesamiento (8 Etapas)

```
scraping/                           lyfta/
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

### 2.1 Etapa 1 — Scraping con Playwright

**Script:** `lyfta/scraping/scrape_exercise_images.py`

Obtiene todas las URLs de imágenes de ejercicios desde `my.lyfta.app/exercises` usando Playwright con anti-detección.

| Característica | Detalle |
|----------------|---------|
| Navegador | Chrome/Chromium con `playwright-stealth` |
| Autenticación | Manual (soporta guardar sesión en `.playwright_session/`) |
| Categorías | Detectadas automáticamente por grupo muscular |
| Scroll | Infinito hasta 80 pasos por categoría |
| Extracción | `<img>`, `<picture>`, `srcset`, `data-src`, `background-image` |
| Progreso | Guarda `exercise_images.json` después de cada categoría |
| Salida | URLs de proxy Next.js (`/next/image?url=...&w=1200&q=75`) |

**Parámetros opcionales:**

```bash
python scrape_exercise_images.py --headless          # Sin ventana (requiere sesión guardada)
python scrape_exercise_images.py --max-categories 3   # Solo 3 categorías
python scrape_exercise_images.py --reset-auth         # Borrar sesión guardada
python scrape_exercise_images.py --cookies cookies.txt # Importar cookies
```

### 2.2 Etapa 2 — Limpieza de URLs

**Script:** `lyfta/scraping/clean_images_json.py`

Toma el JSON crudo del scraper y lo normaliza:

| Acción | Detalle |
|--------|---------|
| Conversión de URL | Proxy Next.js → CDN directo (`apilyfta.com/static/GymvisualPNG/...`) |
| Filtro de tipo | Solo imágenes `GymvisualPNG` (ejercicios, no perfiles ni iconos) |
| Deduplicación | Descarta `profilePic`, iconos SVG de músculos, y duplicados por resolución |
| Resolución conservada | `w=1200` (descarta `w=640`) |
| Extracción de nombre | Nombre legible del ejercicio desde el nombre del archivo |

Salida: `exercise_images_clean.json` con URLs CDN directas.

### 2.3 Etapa 3 — Derivación de URLs de Video

**Script:** `lyfta/scraping/build_video_json.py`

Convierte cada URL de imagen en su URL de video correspondiente mediante reglas de transformación:

| Aspecto | Imagen | Video |
|---------|--------|-------|
| CDN | `apilyfta.com/static/GymvisualPNG/` | `apilyfta.com/static/GymvisualMP4/` |
| ID numérico | `{XXXX}101-` | `{XXXX}201-` |
| Sufijo | `_small.png` | `_.mp4` |

**Ejemplo de transformación:**
```
Imagen: https://apilyfta.com/static/GymvisualPNG/00251101-Barbell-Bench-Press_Chest-FIX2_small.png
Video:  https://apilyfta.com/static/GymvisualMP4/00251201-Barbell-Bench-Press_Chest-FIX2_.mp4
```

Salida: `exercise_videos.json` con URLs de video, nombre y categoría.

### 2.4 Etapa 4 — Descarga de Archivos

Con las URLs de las etapas 2 y 3, se descargan todos los archivos multimedia:

```bash
# Descarga de imágenes (preview/) — Linux / WSL / macOS
mkdir -p preview
while IFS= read -r url; do
    filename=$(basename "$url")
    curl -L -o "preview/$filename" "$url"
done < <(jq -r '.[].url' exercise_images_clean.json)

# Descarga de videos
mkdir -p video
while IFS= read -r url; do
    filename=$(basename "$url")
    curl -L -o "video/$filename" "$url"
done < <(jq -r '.[].url' exercise_videos.json)
```

<details>
<summary>Alternativa original en Windows (PowerShell)</summary>

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

</details>

Resultado:
- `video/` → **682 archivos `.mp4`**
- `preview/` → **3661+ archivos `.png`**

### 2.5 Etapa 5 — Lista Numerada de Videos

**Script:** `lyfta/generate_exercises_json.ps1` (primer paso)

```bash
# Linux / WSL / macOS
i=1
for f in video/*.mp4; do
    basename=$(basename "$f" .mp4)
    echo "$i. $basename"
    ((i++))
done > video_list.txt
```

<details>
<summary>Alternativa original en Windows (PowerShell)</summary>

```powershell
$videos = Get-ChildItem D:\Dataset\Deporte\lyfta\video -Filter "*.mp4" | Sort-Object Name
$i = 1
$lines = foreach ($v in $videos) {
    "$i. $([System.IO.Path]::GetFileNameWithoutExtension($v.Name))"
    $i++
}
$lines | Out-File D:\Dataset\Deporte\lyfta\video_list.txt -Encoding utf8
```

</details>

Salida (`video_list.txt`):
```
1. 00161201-Assisted-Prone-Hamstring_Thighs_
2. 00251201-Barbell-Bench-Press_Chest-FIX2_
3. 00331201-Barbell-Decline-Bench-Press_Chest-FIX_
...
```

### 2.6 Etapa 6 — Generación del Dataset JSON

**Script:** `lyfta/generate_exercises_json.ps1`

Toma `video_list.txt` y produce `ejercicios.json`. Para cada línea:

| Paso | Acción |
|------|--------|
| 1 | Extrae el slug del ejercicio |
| 2 | Limpia tokens de ruido: `(female)`, `(male)`, `-FIX`, `VERSION-*`, `WRONG-RIGHT` |
| 3 | Detecta equipamiento principal (barra, mancuerna, polea, kettlebell, etc.) mediante `$EquipmentMap` |
| 4 | Traduce el nombre del inglés al español usando mapas de equipamiento, modificadores y posición |
| 5 | Asigna categoría, partes del cuerpo, músculos objetivo/secundarios, dificultad y finalidad según reglas sobre el slug |
| 6 | Genera las URLs apuntando a Cloudflare R2 |

### 2.7 Etapa 7 — Pulido de Nombres en Español

Dos scripts de refinamiento secuencial:

#### Primera pasada — `polish_exercises_names.ps1`

```bash
# Linux / WSL / macOS (requiere PowerShell instalado: sudo apt install powershell)
pwsh polish_exercises_names.ps1
```

| Acción | Ejemplos |
|--------|----------|
| Traducción de términos | `grip` → `agarre`, `squeeze` → `apretón`, `weighted` → `con lastre` |
| Reordenamiento sintáctico | `Sentado ... press` → `Press sentado ...` |
| Normalización | Mayúsculas y acrónimos (EZ, V, Z) |

#### Segunda pasada — `polish_exercises_names_pass2.ps1`

```bash
# Linux / WSL / macOS (requiere PowerShell instalado: sudo apt install powershell)
pwsh polish_exercises_names_pass2.ps1
```

| Acción | Ejemplos |
|--------|----------|
| Traducción de movimientos | `push-up` → `flexión`, `bench dips` → `fondos en banco`, `stiff leg deadlift` → `peso muerto piernas rígidas` |
| Reordenamiento avanzado | `Sentado por encima de la cabeza <mov>` → `<Mov> sentado por encima de la cabeza` |
| Corrección residual | Términos en inglés que sobrevivieron a la primera pasada |

Resultado: `dataset_final.json` (~28.6k líneas, **682 ejercicios**).

### 2.8 Etapa 8 — Procesamiento de Previsualizaciones

**Script:** `lyfta/process_videos.ps1`

```bash
# Linux / WSL / macOS (requiere PowerShell instalado: sudo apt install powershell)
pwsh process_videos.ps1
```

Busca en `preview/` las imágenes cuyo nombre descriptivo coincide con algún video de `video/` (normalizando prefijos numéricos y sufijos como `_small`) y las mueve a `images/`.

| Métrica | Valor |
|---------|-------|
| Previsualizaciones totales (preview/) | 3661+ |
| Previsualizaciones movidas (images/) | 686 |
| Ejercicios con 2 previsualizaciones | 4 (distinto ID numérico pero mismo nombre descriptivo) |

---

## 3. Formato de Salida (`dataset_final.json`)

Cada ejercicio se representa con el siguiente esquema:

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

### 3.1 Campos del Esquema

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `fuente` | `string` | Origen del dataset: `"lyfta"` |
| `nombre_ejercicio` | `string` | Nombre del ejercicio en español (terminología profesional) |
| `descripcion` | `string` | Descripción breve del ejercicio y sus beneficios |
| `instrucciones` | `string[]` | 3 pasos de ejecución en español |
| `dificultad` | `string` | `"principiante"`, `"intermedio"` o `"avanzado"` |
| `finalidad` | `string[]` | Tipos de esfuerzo: `"Fuerza"`, `"Hipertrofia"`, `"Cardio"`, `"Isométrico"`, `"Resistencia"`, `"Movilidad"` |
| `partes_cuerpo` | `string[]` | Partes del cuerpo trabajadas (ej: `"Tren superior"`, `"Pecho"`) |
| `musculos_objetivo` | `string[]` | Músculos principales trabajados |
| `musculos_secundarios` | `string[]` | Músculos secundarios activados |
| `equipamientos` | `string[]` | Equipamiento requerido (ej: `"barra"`, `"mancuerna"`, `"peso_corporal"`) |
| `url_video` | `string` | URL del video MP4 en Cloudflare R2 |
| `url_preview` | `string` | URL de la imagen de previsualización en Cloudflare R2 |

---

## 4. Archivos del Proyecto

| Archivo / Carpeta | Propósito | Ubicación |
|---|---|---|
| `scrape_exercise_images.py` | Scraper con Playwright para my.lyfta.app | `lyfta/scraping/` |
| `clean_images_json.py` | Limpia y normaliza las URLs de imágenes | `lyfta/scraping/` |
| `build_video_json.py` | Deriva URLs de video desde las de imagen | `lyfta/scraping/` |
| `video/` | Videos `.mp4` originales (682) | `D:\Dataset\Deporte\lyfta\video\` |
| `preview/` | Previsualizaciones `.png` originales | `D:\Dataset\Deporte\lyfta\preview\` |
| `images/` | Previsualizaciones que coinciden con algún video (686) | `D:\Dataset\Deporte\lyfta\images\` |
| `video_list.txt` | Lista numerada de los 682 videos | `lyfta/` |
| `ejercicios.json` | JSON intermedio generado desde `video_list.txt` | `D:\Dataset\Deporte\lyfta\` |
| `dataset_final.json` | JSON final con nombres pulidos (~28.6k líneas) | `D:\Dataset\Deporte\lyfta\` |
| `generate_exercises_json.ps1` | Genera el dataset estructurado | `lyfta/` |
| `polish_exercises_names.ps1` | Primera pasada de limpieza de nombres | `lyfta/` |
| `polish_exercises_names_pass2.ps1` | Segunda pasada de limpieza de nombres | `lyfta/` |
| `process_videos.ps1` | Mueve previsualizaciones coincidentes | `lyfta/` |
| `README.md` | Documentación del pipeline | `lyfta/` |

---

## 5. Integración con SynaptixFit

El dataset fue ingerido exitosamente en el catálogo de ejercicios de SynaptixFit. Los 682 ejercicios están disponibles en la base de datos con sus metadatos completos, videos y previsualizaciones alojados en Cloudflare R2.

### 5.1 Mapeo al Esquema de BD

| Campo Lyfta | Tabla/Columna SynaptixFit |
|-------------|--------------------------|
| `nombre_ejercicio` | `ejercicios.nombre` |
| `descripcion` | `ejercicios.descripcion` |
| `instrucciones` | `ejercicios.instrucciones` (TEXT[]) |
| `dificultad` | `ejercicios.dificultad` |
| `finalidad` | `ejercicios.finalidad` |
| `partes_cuerpo` | `ejercicio_parte_cuerpo` + `partes_cuerpo` |
| `musculos_objetivo` | `ejercicio_musculo_objetivo` + `musculos` |
| `musculos_secundarios` | `ejercicio_musculo_secundario` + `musculos` |
| `equipamientos` | `ejercicio_equipamiento` + `equipamientos` |
| `url_video` | `ejercicios.url_gif` (o columna específica para video) |
| `url_preview` | `ejercicios.url_gif` (previsualización estática) |

### 5.2 Videos y Previsualizaciones en R2

Los archivos multimedia están alojados en Cloudflare R2 bajo la ruta:
```
ejercicios/lyfta/{slug}.mp4     → video
ejercicios/lyfta/{slug}.webp    → previsualización
```

---

## 6. Estadísticas del Dataset

| Métrica | Valor |
|---------|-------|
| Ejercicios totales | 682 |
| Videos MP4 | 682 |
| Previsualizaciones (match con video) | 686 |
| Previsualizaciones totales descargadas | 3,661+ |
| Líneas del JSON final | ~28,600 |
| Idioma | Español (traducido + pulido en 2 pasadas) |
| Fuente original | my.lyfta.app |
| Formato de video | H.264 MP4 (CDN: GymvisualMP4) |
| Formato de previsualización | WebP (convertido desde PNG) |

---

**Documento compilado:** 05-06-2026  
**Versión:** 1.0  
**Clasificación:** PÚBLICO — Equipo jloen
