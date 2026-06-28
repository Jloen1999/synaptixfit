# SynaptixFit — Pipeline de Segmentacion de Video

## Proposito

`segmentacion_video.py` automatiza la extraccion de clips individuales de ejercicios desde un video completo de rutina. Genera archivos MP4 optimizados, GIFs y previews WebP con metadatos firmados cryptographicamente, listos para integracion directa con Cloudflare R2 y la base de datos de la aplicacion.

## Objetivo

Eliminar el proceso manual de grabar, cortar, nombrar y subir cada ejercicio por separado. El operador graba un unico video continuo de la rutina, ejecuta el script, y obtiene todos los assets organizados, normalizados y firmados.

## Funcionalidades principales

| Fase | Descripcion |
|---|---|
| **Deteccion** | Analiza el video con ffmpeg y detecta cambios de escena entre ejercicios mediante diferencia de frames. |
| **Seleccion** | Extrae previews numerados a una carpeta temporal para pasarlos a un LLM; luego permite filtrar segmentos escribiendo los IDs (ej: `1,3,5`) o `a` para conservar todos. |
| **Nombrado** | El operador asigna nombres descriptivos a cada ejercicio. Los nombres se sanitizan automaticamente a slugs URL-safe. |
| **Extraccion** | Recorta cada segmento con codec H.264, padding letterbox y framerate constante. Soporta salida MP4 y GIF. |
| **Firma criptografica** | Cada archivo generado (MP4, GIF, WebP) incluye metadatos con firma HMAC-SHA256 y timestamp UTC para verificar autenticidad e integridad. Sin watermark visible. |
| **Empaquetado** | Organiza la salida en `preview/` y `videos/` dentro del directorio especificado. La carpeta temporal de previews se elimina automaticamente al finalizar. |

## Estructura de salida

```
curl_biceps/
  preview/
    curl_martillo_con_mancuernas.webp
    curl_de_biceps_con_mancuernas.webp
    curl_de_biceps_en_polea_baja_con_barra_recta.webp
  videos/
    curl_martillo_con_mancuernas.mp4
    curl_de_biceps_con_mancuernas.mp4
    curl_de_biceps_en_polea_baja_con_barra_recta.mp4
```

## Integracion con SynaptixFit

1. El operador sube el video completo de la rutina al servidor
2. Ejecuta el script con `--interactive` para segmentarlo
3. Sube la carpeta generada al bucket R2: `r2://synaptixfit/ejercicios/curl_biceps/`
4. La aplicacion construye las URLs publicas: `https://cdn.synaptixfit.com/ejercicios/curl_biceps/videos/curl_martillo_con_mancuernas.mp4`

## Formato de video de salida

| Parametro | Valor |
|---|---|
| Codec | H.264 (libx264) |
| Resolucion | 1080x1920 (9:16 vertical) |
| FPS | 30 |
| Pixel format | yuv420p |
| Calidad | CRF 18 (alta, visualmente identico al original) |
| Audio | Eliminado (sin audio) |
| Optimizacion | `faststart` para streaming progresivo |

## Firma criptografica

Cada archivo de salida incluye los siguientes metadatos incrustados:

| Campo | Descripcion |
|---|---|
| `synaptixfit_author` | Identificador fijo `synaptixfit` |
| `synaptixfit_signature` | HMAC-SHA256 del contenido (nombre, timestamps, dimensiones, FPS). 16 caracteres hex. |
| `synaptixfit_timestamp` | Timestamp ISO 8601 UTC del momento de generacion |

La clave de firma se configura via variable de entorno `SYNAPTIXFIT_KEY`. Si no se define, se usa un valor por defecto.

Para inspeccionar los metadatos de un archivo:

```bash
ffprobe -v quiet -show_entries format_tags archivo.mp4
```

## Sanitizacion de nombres

Los slugs generados son compatibles con Cloudflare R2 y URLs:

- Minusculas, sin acentos (`biceps`, no `biceps`)
- Sin caracteres especiales ni puntuacion
- Espacios reemplazados por `_`
- Sin guiones bajos duplicados ni en bordes

## Requisitos

- Python 3.8+
- ffmpeg (con libx264, libwebp y soporte libx264 para GIF)

## Modos de uso

### Interactivo (recomendado)

```bash
python segmentacion_video.py "rutina_biceps.mp4" --interactive --threshold 0.02
```

Secuencia completa:
1. Detecta escenas y extrae previews numerados (`1.webp`, `2.webp`...) a `_ejercicios_preview/preview/`
2. Pregunta que segmentos conservar: escribe `1,3,5` (o `a` para todos)
3. Pide el nombre del directorio final
4. Pide la lista de nombres de ejercicios
5. Genera videos + previews con nombres definitivos
6. Elimina automaticamente la carpeta temporal `_ejercicios_preview/`

### Deteccion + preview (solo analisis)

```bash
python segmentacion_video.py "rutina.mp4" --detect --preview --threshold 0.02
```

Extrae previews numerados a `_ejercicios_preview/preview/` para inspeccion visual o envio a un LLM.

### Manual (timestamps conocidos)

```bash
python segmentacion_video.py "rutina.mp4" -e "curl_biceps,00:03,00:11" -e "curl_martillo,00:11,00:15"
```

Si no se especifica `-d`, el script pedira el nombre del directorio interactivamente. Genera tanto videos como previews.

## Parametros clave

| Parametro | Default | Funcion |
|---|---|---|
| `--threshold` | 0.07 | Sensibilidad de deteccion de escenas |
| `--quality` | high | Calidad de compresion (best/high/medium/low) |
| `-W`, `-H` | 1080, 1920 | Dimensiones de salida |
| `--fps` | 30 | Frame rate constante |
| `-d` | auto | Directorio de salida |
| `--format` | mp4 | Formato de salida (mp4/gif) |
| `--preset` | medium | Preset de compression x264 |
| `--tune` | film | Tune de optimizacion x264 |
| `--crf` | — | CRF personalizado (anula `--quality`) |

## Flujo operativo tipico

```
Video completo (1 toma)  →  Script  →  Carpeta con MP4 + WebP + metadatos  →  R2  →  App
```

Tiempo total estimado: ~2-3 minutos para una rutina de 10 ejercicios.
