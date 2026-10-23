# 0015. Importar el plan docente con la IA en segundo plano

* **Estado:** Aprobado
* **Fecha:** 2026-10-23
* **Autores:** Equipo SynaptixFit

## Contexto
El estudiante quiere subir el plan docente (guía docente) de una asignatura en PDF y que la app rellene sola la asignatura, el temario y la evaluación. Ya existía una «guía docente» que se extraía desde un archivo de una asignatura creada antes, de forma síncrona: la petición esperaba a DeepSeek hasta 120 s. En el móvil esa espera se corta con facilidad, y el estudiante no podía usar el plan para crear la asignatura.

Además, casi todas las guías españolas traen dos sistemas de evaluación (continua y global) que suman 100 % cada uno. Mezclarlos daba una nota estimada errónea.

## Decisión
- **Importación propia**, sin asignatura previa. Tabla `importaciones_plan_docente` (V750) y modelo `TeachingGuideImport`, con los estados PENDING, PROCESSING, READY, FAILED y APPLIED. Flujo en `/api/v1/teaching-guide-imports`:
  1. `upload-url`: solo PDF, 15 MB como máximo, con clave `usuarios/{id}/planes-docentes/`.
  2. PUT del cliente directamente a R2.
  3. `POST` responde 202.
  4. `GET` de sondeo.
  5. `apply` con el borrador revisado.
  6. Además: `retry` y `DELETE`.
- **Análisis en segundo plano.** `StartTeachingGuideImportUseCase` publica `TeachingGuideImportRequested`. `TeachingGuideImportListener` lo atiende con `@Async("aiTaskExecutor")` + `@TransactionalEventListener(fallbackExecution = true)`, en 2 hilos y con una cola de 50. Es la **única excepción** a la regla de oyentes síncronos de la ADR 0005.
  - `ProcessTeachingGuideImportUseCase` no lleva transacción envolvente, para no retener una conexión mientras responde la IA.
  - Guarda el resultado o el `code` del error (`AI_UNAVAILABLE`, `AI_QUOTA_EXCEEDED`, `STUDY_GUIDE_EMPTY`…), y el cliente puede reintentar.
  - Si un análisis lleva más de 5 minutos procesándose, o más de 15 en cola (por ejemplo, el servidor se reinició a mitad), el dominio lo da por fallido.
- **Cambios de estado atómicos.** El puerto no tiene un «guardar» genérico, sino `create` y `transition(estadoEsperado, nuevo)`, un `UPDATE … WHERE estado = esperado` que no vuelve a crear una fila borrada. Así:
  - el procesado reclama la importación (PENDING → PROCESSING) y solo guarda el resultado si sigue en PROCESSING, de modo que un análisis que acaba después de descartarse no la resucita;
  - «aplicar» reclama la importación (READY → APPLIED) antes de crear nada: con dos peticiones a la vez, la segunda espera al bloqueo de la fila y recibe `TEACHING_GUIDE_IMPORT_ALREADY_APPLIED`;
  - el dominio recorta el borrador de la IA con los mismos límites que valida la API al aplicarlo, para que siempre se pueda reenviar.
- **Guía ampliada.** `TeachingGuide` añade:
  - datos de la asignatura: código, ECTS con decimales, semestre, carácter, titulación, centro y universidad;
  - subtemas y horas por tema;
  - por cada prueba: modalidad, tipo, duración, temas que cubre, si es recuperable y fecha;
  - la modalidad elegida por el estudiante (`PUT /subjects/{id}/teaching-guide/mode`). La nota estimada solo cuenta la modalidad activa.
- **Aplicar** (`ApplyTeachingGuideImportUseCase`):
  - crea la asignatura o completa la elegida, sin pisar lo que escribió el estudiante: los créditos solo si siguen por defecto y la próxima evaluación solo si se adelanta;
  - guarda la guía conservando el progreso de una importación anterior;
  - registra el PDF como archivo de la asignatura, con la misma clave y sin copiarlo;
  - publica `TeachingGuideApplied` con las pruebas que tienen fecha. El planificador las crea como entregas o exámenes sin duplicarlas.

## Consecuencias
* **Positivas:**
  - el estudiante crea una asignatura completa desde el PDF y puede seguir usando la app mientras la IA trabaja;
  - la nota estimada respeta la modalidad de evaluación;
  - las guías antiguas siguen leyéndose, porque el códec JSON trata los campos nuevos como opcionales.
* **Negativas:**
  - Hay un mecanismo asíncrono que mantener. Si el servidor se reinicia, un análisis en curso se pierde, aunque se puede reintentar.
  - Los PDF escaneados sin texto no se pueden leer (DeepSeek solo lee texto, ADR 0008).
  - Los ECTS con decimales se redondean en `asignaturas.creditos`, que es entero. El valor exacto queda en la guía.
