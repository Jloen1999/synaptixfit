# ADR 0051 — Fotos de apuntes: derechas, con confianza, freno a la IA y lector con visión

- **Fecha:** 2026-11-15
- **Estado:** aceptado
- **Amplía:** ADR 0040 (OCR con Tesseract y orden con la IA)

## Contexto

Fase 1B del plan de mejoras. Fallo: «hago una foto de mis apuntes y el texto que sale no se parece a la foto».

Causa real (comprobada en el código):

1. El móvil guarda los píxeles como salen del sensor y apunta en la etiqueta EXIF `Orientation` cómo girarlos. Una
   foto vertical de Android llega con `Orientation = 6`. `image_picker` reduce la foto a 2400 px **sin girar los
   píxeles** (copia la etiqueta), y ni Leptonica/Tesseract ni Java la aplican. Tesseract leía la hoja tumbada y
   devolvía letras sueltas sin sentido.
2. `ScannedNoteDraft.joinPages` solo exigía 12 letras o cifras, así que esa basura pasaba a la IA.
3. La IA (DeepSeek) tenía orden de «corregir errores evidentes». Con un texto tan roto, «corregía» hasta inventar un
   apunte plausible que no tenía nada que ver con la foto.

## Decisión

1. **Foto derecha antes del OCR.** `ImageHeader` (ahora en `domain/model/shared/`, porque también lo usa la foto de
   perfil) lee la orientación EXIF del segmento APP1 de JPEG, del bloque `EXIF` de WEBP y del bloque `eXIf` de PNG,
   sin abrir la imagen. `ImagePixels` (infraestructura) abre la foto **ya reducida** (submuestreo al leer, lado
   mayor ≤ 3000 px), la pasa a gris, la gira o voltea según las 8 orientaciones EXIF 2.3 y se la manda a Tesseract
   en PNG. Se hace dentro del hueco del lector (una lectura a la vez en producción): ~25 MB de memoria por foto y
   se libera al terminar. Si Java no sabe abrirla (p. ej. un JPEG en CMYK), se manda tal cual, como antes.
   - Dependencia nueva, pequeña: **TwelveMonkeys `imageio-webp` 3.15.3** (Java puro, ~400 KB con sus
     dependencias): Java solo trae lectores de JPEG y PNG, y el cliente acepta WEBP. Alternativa descartada: no
     preprocesar los WEBP (seguirían tumbados) o una librería nativa (libwebp), más pesada y con binarios.
2. **Confianza del OCR.** Tesseract devuelve TSV (`... --psm 3 tsv`): una fila por palabra con su confianza. El
   adaptador rehace el texto (saltos de línea y párrafos) y `PageReading.of` calcula la confianza media ponderada
   por la longitud de cada palabra (una coma suelta no hunde una página bien leída). **Umbral en el dominio:
   `PageReading.LOW_CONFIDENCE = 60`** (Tesseract da 85-95 con texto impreso, 60-80 con letra clara a mano y menos
   de 50 con fotos tumbadas, movidas o en sombra; 60 es el corte habitual para descartar palabras dudosas). Con una
   lectura dudosa **no se ordena con IA** y el borrador lleva `unclear = true`.
3. **Freno a la IA (`TidyFidelity`, dominio).** El texto ordenado debe decir lo mismo que el leído: al menos el
   **70 %** de sus palabras (3 letras o más, sin tildes ni mayúsculas) deben estar en el leído, contando como iguales
   las que difieren en 1 letra (palabras de 4-7) o 2 (8 o más), que es justo lo que corrige la IA; y no puede tener
   más de la mitad de palabras extra (+10 de margen para títulos). Si no se cumple, se devuelve el texto leído sin
   ordenar.
4. **Lector con visión (Gemini) como segundo adaptador de `ImageTextReaderPort`** (lo preveía el ADR 0040).
   `GeminiImageTextReader` llama a `POST /v1beta/models/{modelo}:generateContent` con la foto en línea (base64, ya
   girada, sin EXIF ni GPS, lado mayor `GEMINI_MAX_SIDE` = 2048 px) y la orden «transcribe literalmente el texto,
   sin añadir ni corregir; si no hay texto legible, responde vacío». Modelo configurable con `GEMINI_MODEL`; por
   defecto `gemini-3.8-flash` (el «flash» estable vigente en la documentación oficial el 15-11-2026;
   `gemini-2.5-flash` está obsoleto). `thinkingLevel: MINIMAL` (copiar no necesita razonar). Tiempo máximo 30 s,
   como mucho 2 a la vez, **sin reintentos**.
   - **Solo se usa** si Tesseract duda (o no está instalado) **y** `GEMINI_API_KEY` está configurada; sin clave,
     `available()` es falso y no se le llama.
   - Sus errores se traducen a `NOTE_SCAN_UNAVAILABLE` (el `code` de la lectura, ADR 0040) y el caso de uso los
     absorbe: vale lo que leyó Tesseract. Nunca llega un error de Gemini al cliente.
   - Su texto no trae confianza (`PageReading.UNKNOWN`): se da por claro y sí se ordena con IA, con el freno.
5. **Privacidad.** Si se usa Gemini, la foto sale a Google. La política (versión `2026-11-16`) lo dice: las fotos de
   apuntes que el lector propio no puede leer bien se envían a Google (Gemini) solo para pasarlas a texto.
   `GEMINI_API_KEY` es secreta (solo en el entorno; el despliegue la marca como secreta).
6. **Cliente.** El borrador trae `unclear`. En «Revisa el texto» se ven las fotos (miniaturas que se abren en grande
   con zoom) para comparar y, si `unclear`, un aviso: «No se ha podido leer bien la foto. Revisa el texto o escribe tú
   lo que falte.» Sin «OCR» ni «confianza» en pantalla.

## Consecuencias

- **Positivas:** las fotos verticales del móvil se leen; un texto ilegible ya no se convierte en un apunte inventado;
  con letra a mano difícil, la visión de Gemini ayuda si se configura.
- **Negativas:** la JVM abre y gira cada foto (~25 MB, una a la vez). Gemini cuesta por foto y su plan gratuito
  permite a Google usar los datos para mejorar sus modelos: **conviene el plan de pago** (decisión del propietario).
- **A vigilar:** el umbral de 60 y el 70 % del freno son puntos de partida; si se ven falsos avisos, ajustarlos en el
  dominio (con sus tests).
