# ADR 0064 — Cabecera de la asignatura, lista «Material» y «Compartir»

- **Fecha:** 2026-11-25
- **Estado:** aceptado (plan UX del 19 nov 2026, tanda 5B «Académico: asignatura y material»; referencia visual:
  maquetas `academico-fase4/` — `Main.html`, `Resumen.html` y las demás pestañas —)
- **Completa:** ADR 0057 (pestañas de la asignatura), ADR 0036 (apuntes compartidos) y ADR 0044 (elegir amigos).

## Contexto

La asignatura repetía datos en la cabecera (créditos, curso, cuatrimestre y días de clase) y los apuntes y los archivos
vivían en dos listas con acciones escondidas en un menú de tres puntos. Abrir la pestaña lanzaba una petición de
disponibilidad de documentos de IA por cada apunte y archivo (2 + N peticiones), y el visor de un apunte creaba un
`SelectableText` por bloque de Markdown. Para sacar un apunte de la app no había forma: ni PDF, ni pasárselo a un amigo,
ni publicarlo en el muro.

## Decisión

### Cabecera y pestañas (cliente)

- Franja con el color de la asignatura (decorativa: el nombre la acompaña siempre), el nombre entero y **una sola línea
  de datos** con `subjectMetaText` («6 ECTS · 2.º curso · 1.er cuatri»). Los días de clase salen de la cabecera (siguen
  en «Lo próximo» y en el calendario); «Archivada», en su píldora.
- Orden de las pestañas: **Resumen · Temario · Apuntes · Evaluación · Guía** (`SubjectDetailTab`). Los valores de
  `?tab=` no cambian, así que los enlaces viejos siguen abriendo la suya.

### Una sola lista «Material» (cliente)

- `SubjectMaterial` (dominio, `NoteMaterial`/`FileMaterial`) junta apuntes y archivos; `SubjectMaterial.merge` los ordena
  por fecha (lo más reciente primero, sin fecha al final, a igual fecha los apuntes antes).
- Cada fila (`MaterialTile`) lleva icono **y** tipo en texto («Apunte», «Nota rápida», «PDF», «Imagen», «Archivo DOCX»),
  nombre, fecha (tamaño o con quién se comparte); toda la fila abre el material; los documentos de IA guardados son
  botones con su nombre («Resumen de «X»»); y «Acciones» (`showMaterialActionsSheet`) abre la hoja con Abrir, Repasar,
  Practicar, la ayuda de la IA (si la IA lo lee), Compartir, Descargar y, aparte y en rojo, Eliminar.
- Añadir: «Nuevo apunte», «Desde una foto» y «Subir archivo» como botones con borde en un `Wrap`. Cuatro estados:
  esqueleto, error con «Reintentar», vacío con las tres formas de añadir, y la lista.

### Abrir más rápido

- **Una petición para toda la asignatura:** `GET /api/v1/study/subjects/{subjectId}/documents`
  (`GetSubjectDocumentAvailabilityUseCase`, `SubjectDocumentAvailabilityService`) devuelve los documentos guardados de
  todos sus apuntes y archivos legibles por la IA con dos consultas que solo leen fuente y tipo
  (`AiDocumentRepositoryPort.typesForAll`). `SubjectSyllabusBloc` pide apuntes, archivos y disponibilidad **a la vez** y
  emite una sola vez; si la disponibilidad falla, la lista sale igual sin iconos. Los visores siguen haciendo una sola
  petición de disponibilidad para su elemento.
- **Texto entero seleccionable:** `AcademicMarkdown` usa un `MarkdownBody` sin `selectable` dentro de **un**
  `SelectionArea`, en vez de un `SelectableText` por bloque.
- **Medidas** (test temporal con `flutter test`, borrado después): ver la tabla de «Consecuencias». En un móvil real
  los tiempos absolutos cambian; la proporción y el número de peticiones, no.

### «Compartir» y «Descargar» (servidor primero)

Un solo botón «Compartir» por material (en «Acciones» de la lista y en la barra de los dos visores) abre
`showMaterialShareSheet`, que usa un `MaterialShareBloc` de la página; el aviso lo pinta `MaterialShareFeedback`:

| Opción | Qué hace | Aviso |
|---|---|---|
| **Con un amigo** (solo apuntes) | `showFriendPickerSheet` (el de «Con amigos») → `POST /notes/{id}/recipients`. El servidor comprueba amistad mutua (`NOTE_RECIPIENT_NOT_FRIEND`, 422), guarda el permiso en `apuntes_destinatarios` y manda el aviso `NOTE_RECEIVED` que abre `/academic/notes/shared/{id}`. | «Enviado a Bea: le llega en sus avisos» + «Ver» |
| **Para todos** (solo apuntes) | `PATCH /notes/{id}` con `PUBLIC`; el servidor lo rebaja al tope del perfil como siempre. | «Está en Apuntes compartidos…» + «Ver»; con perfil privado, lo dice y lleva a «Privacidad» |
| **En el muro** (solo apuntes) | `POST /notes/{id}/wall`: el apunte pasa a público (con el tope del perfil, la misma regla que el muro) y se publica una vez con `PostType.NOTE` y metadatos estables `{"entityType":"note","entityId":…}` (`PublishAchievementPostUseCase`, idempotente). La tarjeta del muro enlaza el apunte. | «Publicado en el muro» o «Ya estaba en el muro» + «Ver» |
| **Fuera de la app** | El PDF del apunte (`GET /notes/{id}/pdf`, lo genera el servidor con PDFBox) o el archivo original (URL firmada del servidor: el cliente no habla con R2), al menú del sistema (`share_plus`). | Ninguno: el sistema ya lo confirma; cerrarlo no es un error |
| **Descargar** | El mismo archivo al «Guardar como» del sistema (`file_picker`, ya instalado; en web, la descarga): «guárdalo donde elijas». | «Guardado: X.pdf» |

Reglas de negocio en el servidor: quién es amigo, quién puede leer un apunte pasado (`NoteAccess`: lo que deja ver la
visibilidad efectiva o, si se lo pasaron, mientras sigan siendo amigos y sin bloqueo ni shadowban), a qué visibilidad
pasa un apunte al publicarlo y que no se duplique la publicación.

### Correcciones tras la revisión (privacidad, arquitectura y uso)

- **Llamadas síncronas a otros módulos (excepción documentada en `events.md`):** «En el muro» llama a
  `PublishAchievementPostUseCase` (Social) y «Con un amigo» a `CreateNotificationUseCase` en la misma transacción,
  porque la respuesta depende del resultado (`alreadyShared`). Lo que va en el otro sentido sí va por eventos.
- **Revocación permanente:** con `FriendshipEnded` (bloquear o dejar de ser amigos), `RevokeNoteRecipientsUseCase`
  borra en los dos sentidos las filas de `apuntes_destinatarios`. Volver a ser amigos no devuelve el acceso: hay que
  pasar el apunte otra vez.
- **Muro idempotente de verdad:** índice único parcial `ux_actividades_sociales_apunte` (`usuario_id`, `metadata`)
  `WHERE tipo = 'apunte'` (migración `V1081`) e inserción con `ON CONFLICT DO NOTHING`: si dos peticiones llegan a la
  vez, la segunda responde «ya estaba en el muro». Los metadatos salen de `Post.noteMetadata`.
- **Perfil privado:** «En el muro» se rechaza con `NOTE_WALL_PROFILE_PRIVATE` (422) en vez de publicar algo que nadie
  puede abrir; el cliente lo explica antes y lleva a «Privacidad».
- **Borrar un apunte** publica `NoteDeleted`; Social retira su publicación (`RetractNotePostUseCase`).
- **PDF:** `NotePdfExportService` lee el apunte con `GetNoteUseCase` (su transacción) y lo dibuja fuera de ella; tope de
  150 páginas (el resto, «[…]»); un fallo de PDFBox sale como `NOTE_PDF_UNAVAILABLE` (503), nunca como un 500 sin
  `code`. `ArchitectureTest` prohíbe `org.apache.pdfbox..` en `domain` y `application`.
- **Cliente:** «Para todos» y «En el muro» piden una confirmación corta con el alcance real según la privacidad del
  perfil («Hacer público» / «Publicar» y «Cancelar»); si falla compartir o descargar, el aviso lleva «Reintentar», que
  repite la misma acción con el mismo material (`MaterialShareState.retry`). Los botones que se nombran para el
  lector («Desde una foto», los documentos de IA) llevan su propia acción de pulsar; la fila del material se anuncia
  como botón y «Acciones» lleva su texto si deja sitio al nombre. El visor abre los enlaces `https` (otro esquema o un
  fallo, un aviso) y anuncia los títulos como encabezados. Las pestañas de la asignatura pasan de la barra a debajo
  de la cabecera, para que el lector oiga el nombre antes que ellas: se desplazan con el contenido, como en la maqueta.

## Desviaciones de la maqueta

- La maqueta pone **Evaluación antes que Apuntes**; el plan aprobado (19 nov) las invierte: el material se usa a diario y
  la evaluación de vez en cuando.
- La maqueta no pinta la franja de color en la cabecera (solo en la tarjeta de la lista); el plan la pide. Va a la
  izquierda del nombre, como en la tarjeta, y es decorativa.
- La pestaña «Apuntes» no tiene maqueta propia (enlaza a `Main.html`): la lista «Material» sigue el estilo de las
  tarjetas de la maqueta (fila tocable, texto secundario en gris, botones con borde).
- **Los archivos solo se comparten fuera de la app** (y se descargan): «Con un amigo», «Para todos» y «En el muro» son de
  los apuntes, que son lo que sabe leer «Apuntes compartidos». La hoja lo dice en vez de esconderlo.
- «Descargar» está en «Acciones» y también al final de la hoja «Compartir», separado: así los visores, con la barra
  llena, solo añaden un icono.
- El PDF es sencillo (fuentes estándar, alfabeto latino): lo que no cabe en ellas (emojis, griego) sale como «?».

## Consecuencias

| Medida | Antes | Después |
|---|---|---|
| Peticiones al abrir «Apuntes» con N elementos | 2 + N (la disponibilidad, después de la lista) | 3 a la vez, una sola emisión |
| Widgets seleccionables en un apunte de 60 apartados (300 líneas) | 240 `SelectableText` | 1 `SelectionArea` |
| Construir y pintar ese apunte (mediana de 5, `flutter test`, 400 × 900) | 1,52 s | 0,20 s (≈ 7,6 veces menos) |

- Migraciones `V1080__academic_note_recipients_and_wall.sql` (tabla `apuntes_destinatarios` y el tipo `apunte` en
  `actividades_sociales`) y `V1081__social_note_post_unique.sql` (índice único parcial, listado en
  `database_portability.md`).
- Códigos nuevos: `NOTE_RECIPIENT_NOT_FRIEND`, `NOTE_WALL_PROFILE_PRIVATE` y `NOTE_PDF_UNAVAILABLE`; aviso `NOTE_RECEIVED`;
  evento `NoteDeleted`; `PostType.NOTE` y `PostLinkKind.note` en el cliente.
- `DataChangeInterceptor`: publicar en el muro (`/notes/{id}/wall`) refresca también lo social.
