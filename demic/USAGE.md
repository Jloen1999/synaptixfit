# Segmentacion de Videos de Ejercicios

Corta videos de ejercicios en clips MP4 o GIF con deteccion automatica de escenas, seleccion de segmentos asistida por LLM, y firma criptografica en metadatos.

## Flujo interactivo (recomendado)

```bash
python segmentacion_video.py "ejercicio.mp4" --interactive --threshold 0.02 --quality low
```

### Paso a paso

**1. Detecta escenas** y extrae previews numerados a la carpeta temporal `_ejercicios_preview/preview/`:

```
Extrayendo previews en '_ejercicios_preview/preview/'...
  1.webp (t=4.32s)
  2.webp (t=13.41s)
  3.webp (t=25.10s)
  4.webp (t=37.80s)
  5.webp (t=49.55s)
  6.webp (t=61.28s)
  7.webp (t=73.05s)
```

**2. Envia esas imagenes a un LLM** y escribe que segmentos conservar:

```
Con que imagenes te quedas? (ej: 1,3,5 o 'a' para todas): a
```

Puedes filtrar escribiendo `1,3,5` para conservar solo esos segmentos, o `a` para conservar todos.

**3. Especifica el directorio final y pega los nombres:**

```
Nombre del directorio final: curl_biceps

Pega la lista de 7 ejercicios:
----------------------------------------
1. Curl martillo con mancuernas
2. Curl de biceps con mancuernas
3. Curl de biceps en polea baja con barra recta
4. Curl de biceps inverso en polea baja con barra recta
5. Curl martillo en polea baja con cuerda
6. Curl de biceps con barra EZ
7. Curl de biceps inverso con barra EZ
```

**4. El script genera los archivos** y elimina automaticamente la carpeta temporal:

```
Carpeta temporal '_ejercicios_preview/' eliminada.
Completado. Archivos en 'curl_biceps/'
```

## Estructura de salida

```
curl_biceps/
  preview/
    curl_martillo_con_mancuernas.webp
    curl_de_biceps_con_mancuernas.webp
    curl_de_biceps_en_polea_baja_con_barra_recta.webp
    curl_de_biceps_inverso_en_polea_baja_con_barra_recta.webp
    curl_martillo_en_polea_baja_con_cuerda.webp
    curl_de_biceps_con_barra_ez.webp
    curl_de_biceps_inverso_con_barra_ez.webp
  videos/
    curl_martillo_con_mancuernas.mp4
    curl_de_biceps_con_mancuernas.mp4
    curl_de_biceps_en_polea_baja_con_barra_recta.mp4
    curl_de_biceps_inverso_en_polea_baja_con_barra_recta.mp4
    curl_martillo_en_polea_baja_con_cuerda.mp4
    curl_de_biceps_con_barra_ez.mp4
    curl_de_biceps_inverso_con_barra_ez.mp4
```

## Solo detectar (analisis + previews)

```bash
python segmentacion_video.py "video.mp4" --detect --threshold 0.02
python segmentacion_video.py "video.mp4" --detect --preview --threshold 0.02
```

Extrae previews numerados a `_ejercicios_preview/preview/` sin generar videos. Util para enviar a un LLM y decidir los nombres.

## Modo manual (timestamps conocidos)

```bash
python segmentacion_video.py "video.mp4" -e "curl_biceps,00:03,00:11" -e "curl_martillo,00:11,00:15"
```

Si no se especifica `-d`, el script pedira el directorio. Genera tanto videos como previews con los nombres indicados.

## Firma criptografica (metadatos)

Todos los archivos generados (MP4, GIF, WebP) incluyen metadatos con firma HMAC-SHA256 para verificar autenticidad:

```bash
ffprobe -v quiet -show_entries format_tags curl_biceps.mp4
```

Salida esperada:

```
TAG:synaptixfit_author=synaptixfit
TAG:synaptixfit_signature=a1b2c3d4e5f6g7h8
TAG:synaptixfit_timestamp=2026-05-30T12:00:00Z
```

Configura la clave via variable de entorno:

```bash
set SYNAPTIXFIT_KEY=mi-clave-secreta  # Windows
export SYNAPTIXFIT_KEY=mi-clave-secreta  # Linux/macOS
```

## Comandos utiles

```bash
# Maxima calidad
python segmentacion_video.py "video.mp4" --interactive --quality best

# Resolucion 720p
python segmentacion_video.py "video.mp4" --interactive -W 720 -H 1280

# GIFs ligeros
python segmentacion_video.py "video.mp4" -e "ejercicio,00:00,00:10" --format gif -W 360 -H 640

# Ajustar umbral
python segmentacion_video.py "video.mp4" --detect --threshold 0.01  # mas sensible
python segmentacion_video.py "video.mp4" --detect --threshold 0.10  # menos sensible

# Directorio especifico
python segmentacion_video.py "video.mp4" -e "sentadilla,00:12,00:22" -d piernas

# Verificar metadatos de un archivo generado
ffprobe -v quiet -show_entries format_tags archivo.mp4
```

## Parametros

| Parametro | Default | Descripcion |
|---|---|---|
| `--interactive` | — | Detecta escenas, extrae previews, permite filtrar por IDs (`a` para todos), pegar nombres y genera todo |
| `--detect` | — | Solo analiza cambios de escena |
| `--preview` | — | Extrae frames numerados a `_ejercicios_preview/preview/` |
| `-d DIR` | auto | Directorio de salida (si se omite en modo manual, se pide interactivamente) |
| `--threshold` | 0.07 | Sensibilidad de deteccion (0.01-0.10) |
| `-e "n,inicio,fin"` | — | Ejercicio manual. Repetir `-e` para varios. |
| `--format` | mp4 | Formato de salida: mp4 o gif |
| `-W`, `-H` | 1080x1920 | Dimensiones de salida |
| `--fps` | 30 | FPS constante |
| `--quality` | high | best / high / medium / low |
| `--preset` | medium | Preset x264: ultrafast, veryfast, fast, medium, slow, veryslow |
| `--tune` | film | Tune x264: film, animation, grain, stillimage, fastdecode, zerolatency |
| `--crf` | — | CRF personalizado (0-51). Anula `--quality`. |
