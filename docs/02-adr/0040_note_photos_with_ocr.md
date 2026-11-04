# 0040. Fotografiar apuntes: OCR con Tesseract en el backend y orden con la IA

* **Estado:** Aprobado
* **Fecha:** 2026-11-04
* **Autores:** SynaptixFit

> Numerado como 0040 (y no 0031) porque se escribió en paralelo con otra tanda que usa los siguientes números;
> al juntarlas se puede renumerar.

## Contexto
Mucha gente estudia con apuntes en papel. Pasarlos a mano a la app no compensa, así que no entran en el repaso ni
en el simulacro. Se quería «haz una foto y tienes el apunte».

La IA del proyecto (DeepSeek) **solo entiende texto**: `AttachmentTextExtractor` ya rechaza imágenes
(`AI_ATTACHMENT_UNSUPPORTED`). Además, la regla del proyecto es que solo el backend habla con servicios externos.

## Decisión
* **OCR en el backend con Tesseract** (libre, sin cuenta ni coste por uso). Va instalado en la imagen Docker del
  backend con los diccionarios de los cuatro idiomas de la app (`spa`, `eng`, `fra`, `por`). Se llama como programa
  (`TesseractImageTextReader`, `ProcessBuilder`): la foto entra por la entrada estándar y el texto sale por la
  salida estándar, sin escribir nada en disco. No hace falta ninguna dependencia Java nueva.
  - Diccionarios según el idioma de la petición (`Accept-Language`), con inglés de apoyo.
  - Como mucho 2 lecturas a la vez (`synaptixfit.ocr.max-concurrent`) y 60 s por foto
    (`synaptixfit.ocr.timeout-seconds`): cada lectura es un proceso de 100-200 MB.
  - Sin Tesseract instalado (p. ej. en un equipo de desarrollo), `NOTE_SCAN_UNAVAILABLE` (503).
* **La IA ordena el texto leído** (`NoteTidierAiAdapter`): corrige errores evidentes de lectura y lo pasa a
  Markdown, con la regla explícita de no añadir contenido. Si la IA falla o se agotó la cuota, se devuelve el texto
  tal cual con `tidied = false`: sigue siendo útil.
* **Nada se guarda sin revisarlo.** `POST /api/v1/notes/scan-drafts` (multipart `files`, de 1 a 5 fotos JPG, PNG o
  WEBP, 10 MB cada una y 20 MB en total) devuelve un borrador. La persona lo corrige, elige título y asignatura, y
  el cliente lo guarda como un apunte privado normal (`POST /notes`).
* Las reglas del lote (cuántas fotos, tamaño, formato, «no hay texto legible», título por defecto) viven en el
  dominio (`NotePhoto`, `ScannedNoteDraft`). El caso de uso no abre transacción: no toca la base de datos y tarda
  segundos.

## Alternativas descartadas
* **OCR en el móvil (ML Kit):** solo Android/iOS, no en la web, y rompe la regla de que el backend es quien procesa.
* **Un servicio de visión de pago (Google Vision, un modelo multimodal):** mejor con letra a mano, pero añade una
  cuenta, un secreto y un coste por foto. Queda como mejora si la letra a mano resulta ser lo habitual: bastaría
  otro adaptador de `ImageTextReaderPort`.

## Consecuencias
* La imagen del backend crece unos 60 MB.
* Tesseract lee bien el texto impreso o la letra clara; con letra a mano descuidada falla. La pantalla lo dice
  («Funciona mejor con letra clara o apuntes impresos») y siempre deja corregir antes de guardar.
* El cliente aplica también el límite de 5 fotos, para no dejar elegir fotos que luego se rechazarían.
