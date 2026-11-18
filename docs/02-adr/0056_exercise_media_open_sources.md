# ADR 0056 — Fotos y vídeos de los ejercicios de fuentes abiertas, con su crédito

- **Fecha:** 2026-11-19
- **Estado:** aceptado (decisión del propietario del 18 nov 2026: «todas las imágenes»)

## Contexto

Fase 3C. De los 5.445 ejercicios del catálogo, solo los 909 originales (V2) tienen foto o vídeo; los 4.536 que llegaron
de openGym (V850) no traían ninguno, porque sus medios eran de Gym Visual con licencia solo para ese proyecto
(`tools/exercises/data/FUENTES.md`). En pantalla salía el icono de su categoría (ya en todas las miniaturas que saben la
categoría o la modalidad; en el editor de rutina no se sabe y queda la pesa genérica).

Fuentes revisadas:

| Fuente | Licencia declarada | Procedencia de las imágenes |
|---|---|---|
| wger, ilustraciones de **Everkinetic** | CC BY-SA 3.0 | Proyecto abierto de ilustraciones conocido |
| wger, resto | CC BY-SA 3.0/4.0, CC BY 4.0 o CC0, por imagen | Las suben usuarios y nadie comprueba la licencia. Al revisarlas había ilustraciones con el estilo de atlas comerciales y alguna con marca de agua |
| free-exercise-db | Unlicense (dominio público) para el repositorio | Las fotos vienen de `wrkout/exercises.json`, que no dice de dónde salen y vende aparte un paquete de imágenes «para proyectos comerciales» |

## Decisión

- Se usan **las tres fuentes**, en ese orden de preferencia, solo para ejercicios **sin ninguna foto ni vídeo**. El
  propietario lo pidió así para tener el catálogo completo y **asume el riesgo de licencia** de las dos últimas. La
  advertencia queda escrita aquí: una reclamación de derechos de autor en Google Play puede retirar la app.
- **Emparejamiento solo exacto**, por el nombre inglés normalizado (el nuestro y el original de openGym), más una lista
  manual de equivalencias claras (`MANUAL` en `tools/exercises/exercise_images.py`). Se probó el parecido difuso y
  emparejaba mal («Air squat» con «Chair squat», declinado con inclinado, abducción con aducción): una foto de otro
  ejercicio enseña mal el movimiento, así que se descartó.
- Resultado: **324 ejercicios con foto y 16 con vídeo** (V1077). Las plantillas de rutina quedan en 47 de 48 con foto o
  vídeo (falta el jalón con agarre abierto).
- **Rendimiento:** las fotos se pasan a WebP de 720 px como mucho, calidad 80, con fondo blanco (muchas son dibujos con
  fondo transparente que en el tema oscuro no se verían). Los vídeos de wger llegaban en `.mov` de hasta 57 MB; se pasan
  a MP4 H.264 de 720 px, 24 fps, sin sonido y con el índice al principio (1–1,6 MB). En total, de 520 MB a 15,5 MB. Cambiar
  formato o tamaño es una modificación técnica que Creative Commons permite (no es obra derivada).
- **Alojamiento:** en el bucket R2 de la app (`ejercicios/wger/…`, `ejercicios/wger/video/…`, `ejercicios/fedb/…`),
  servidos como el resto por `/media` (ADR 0024). No se depende de las webs de origen.
- **Crédito por medio:** tabla `creditos_medios_ejercicio` (ejercicio, `FOTO`/`VIDEO`, fuente, licencia, enlace de la
  licencia, autor, página de la obra). El servidor lo da en `GET /api/v1/exercises/{id}/media-credits`
  (`ListExerciseMediaCreditsUseCase`) y la ficha y «Cómo se hace» lo enseñan bajo la demostración: «Foto: Everkinetic
  (wger) · CC BY-SA 3.0», que abre la licencia. La línea de openGym («Datos del ejercicio: openGym…») sale también en
  los ejercicios que ahora tienen foto con crédito.
- **Retirar una fuente** es una migración: vaciar `url_preview`/`url_gif` de los ejercicios con crédito de esa fuente,
  borrar sus filas de `creditos_medios_ejercicio` y sus archivos del bucket.

## Consecuencias

- Scripts: `exercise_images.py` (descarga con caché y empareja), `upload_exercise_media.py` (convierte y sube con la API
  S3 de R2, sin imprimir claves) y `build_media_migration.py` (escribe la migración). La subida se puede repetir (no
  vuelve a subir lo publicado). La migración no: el script se niega a sobrescribir una que ya existe; para añadir
  medios se genera otra con la versión siguiente, que también solo rellena lo vacío.
- Las URL se guardan con la dirección de desarrollo del bucket (`pub-….r2.dev`), como V2: `ExerciseMediaUrls` las
  cambia por `MEDIA_PUBLIC_BASE_URL` al servirlas (ADR 0024).
- **Pendiente aparte, más grave:** los medios del catálogo original (V2, carpeta `ejercicios/lyfta/` del bucket, unos
  1.360 archivos) se copiaron de la app comercial Lyfta. Sus nombres (código de 8 cifras + ejercicio + parte del cuerpo)
  coinciden con los de la carpeta `GymvisualPNG` que sirve la propia Lyfta, así que lo más probable es que sean de
  Gymvisual, que vende licencias. Los términos de Lyfta prohíben copiar y redistribuir su material. Antes de publicar en
  Google Play hay que comprar una licencia de Gymvisual que cubra apps o sustituir esos medios. Decide el propietario.
