# ADR 0060 — Calendario con más rejilla: cabecera compacta, «+» y ficha de lectura del evento

- **Fecha:** 2026-11-20
- **Estado:** aceptado (maqueta `inicio-calendario.html`, pantallas 3 y 4, aprobada por el propietario el 19 nov 2026,
  tanda 2)
- **Sustituye en parte a:** ADR 0050 (atajos `_Shortcuts` y «Hoy» también para otro día de la semana)

## Contexto

En un móvil de 390×844 todo lo que iba encima de la rejilla del Calendario ocupaba 340-400 px: barra de título (56),
fila de la semana (48), atajos «Entregas» y «Concentrarme» (44), franja de horas `WeekBalanceStrip` (56), franjas
opcionales de choques y de entregas (56 cada una), la tira de días (84) y la cabecera de días (48). La rejilla se quedaba
en unos 300 px y el botón flotante extendido «Añadir al calendario» tapaba parte de ella.

Además, tocar un evento abría directamente el formulario de edición (`BlockEditorSheet`) con las acciones encima: para
ver a qué hora era o de qué asignatura había que entrar en un formulario, y lo que se hace a diario (concentrarse, marcar,
mover) competía con los campos.

## Decisión

### Cabecera compacta (~180 px en 390×844)

- **Sin barra de título.** La fila de la semana hace de cabecera: ‹ «17 – 23 nov» › (`plannerWeekRangeSameMonth`; si la
  semana cambia de mes, «27 oct – 2 nov»). El rango es el encabezado de la pantalla para el lector: «Calendario, semana
  del 17 de noviembre al 23 de noviembre».
- A la derecha, **iconos con nombre** (tooltip y nombre para el lector, 48 px): «Entregas y exámenes», «Concentrarme» y
  el ⋮ de siempre (sugerir un plan, estudio ya hecho, importar el horario, sincronizar). **La disposición la decide el
  ancho real** (`LayoutBuilder` y el ancho medido del rango con el tamaño de texto, `context.textWidth`): si el rango no
  cabe entero en la fila con las flechas, «Hoy» y los iconos, «Hoy» y los iconos bajan a una segunda fila (a 320 px en
  otra semana, o a 360 px con el texto al 125 %, ya pasa; WCAG 1.4.10). El rango no tiene límite de líneas: antes que
  cortarse, baja de línea.
- En tablet y escritorio, ‹ rango › van **juntos**, con un ancho máximo (`TokensLayout.weekNavMaxWidth`, 360 px), en vez
  de dejar las flechas en los extremos.
- **«Hoy» solo fuera de la semana actual**, en esa fila. Dentro de la semana la tira de días ya lleva a hoy (su chip se
  llama «Hoy»). Antes salía también al ver otro día de esta semana en el móvil.
- **Tira de días** (`_WeekDayStrip`, sin cambios) y, debajo, **una línea de cifras tocables** (`WeekSummaryChips`), que
  sustituye a las tres franjas fijas:
  - «2 entregas y exámenes» → hoja con las de la semana (día, hora, «Hecha» con texto, asignatura); cada una abre su
    entrega y «Ver todas las entregas y exámenes» abre la lista completa.
  - «10 h estudio · 3 h deporte» (lo planificado; el icono es el del estado del balance y el lector oye también el
    estado) → la carga semanal (`WeeklyLoadSheet`), que ya enseña lo hecho frente a lo planificado.
  - «1 choque de horario» → la lista de choques de siempre. Solo sale si hay choques: el aviso sigue, pero como un chip
    más, sin banda fija.
- **La cabecera de días se queda, fina.** Cuando no caben los 7 días (móvil) se ven unas 3 columnas: la tira no dice qué
  columna es cada día, así que quitarla obligaba a adivinarlo. Pasa de 48 a 28 px (`WeekCanvas.compactHeaderHeight`,
  `labelMedium`) y sigue siendo el encabezado de cada columna para el lector. Con los 7 días a la vista no hay tira y la
  cabecera mantiene sus 48 px. Resultado medido en el test: unos 180 px encima de la rejilla (antes 340-400), más
  cerca del objetivo de ~150 de la maqueta sin perder qué día es cada columna. El alto fino es el token
  `TokensSize.calendarDayHeaderCompact`.
- **Chips sin rojo ni solo color:** el icono de «N entregas y exámenes» va en el color de acento (una entrega no es un
  error) y el de las horas, el del estado del balance, lleva tooltip con su nombre («Equilibrada»).
- Mientras carga, el esqueleto imita lo que hay bajo la cabecera (que ya se ve): la tira de días si no caben los 7, la
  línea de cifras y la rejilla, con alturas de tokens.

### Añadir

- Botón flotante **cuadrado «+» de 56 px** (`FloatingActionButton`, tooltip y nombre «Añadir al calendario»), que ya no
  tapa la rejilla.
- **Mantener pulsado un hueco vacío** añade ahí, como tocarlo (`WeekCanvas.onSlotLongPress` → `CalendarEvent.slotTapped`:
  en el pasado avisa, en el futuro abre el formulario). Sobre un evento, la pulsación larga sigue siendo arrastrar.

### Ficha de lectura del evento (`BlockDetailsSheet`)

Tocar un evento abre una hoja para **leer** (`calendar/page/block_details_sheet.dart`), pintada con los datos del
`CalendarBloc` (se repinta si el evento cambia mientras está abierta):

- Icono y pastilla del tipo, estado con texto, icono y color («Hecho», «Sin hacer», «Fijo»; **el mismo icono que en la
  rejilla**: `AppIcons.done`, `AppIcons.overdue` y `AppIcons.readOnly`), el título (el mismo que en la rejilla,
  encabezado de la hoja) y, arriba a la derecha, **«Editar» con icono y texto** (abre el `BlockEditorSheet` de siempre;
  desactivado mientras se hace algo; si no cabe junto al título, debajo). Sin «Cerrar»: la hoja se cierra con el asa
  (que el lector anuncia como botón de cerrar), tocando fuera, Esc o «atrás».
- **Cuándo:** «Hoy / Mañana / Jueves, 20 de noviembre, 19:00 – 20:00» y debajo **solo la duración**. El calendario no
  sabe si los avisos están activos en este móvil, así que no promete ninguno.
- **Asignatura** con «Abrir asignatura» (nombre de la línea de tiempo, `CalendarState.blockSubjects`; sin nombre no sale
  la línea), **reto** que
  adelanta («Adelanta «Día 2» del reto «Estudia y muévete»», con `GetPlannerChallengesUseCase`, que el bloc pide una
  sola vez y solo si algún evento de la semana va con un reto; sin datos, «Adelanta una tarea de un reto»), **lugar** y
  **nota** (los temas; en lo personal el nombre ya es el título).
- **La acción que toca, grande y la única rellena** (`BlockDetails.primaryAt`): «Concentrarme» (estudio o repaso que no
  se quedó sin hacer), «Empezar el entreno» (día de rutina de hoy: abre la sesión con `StartSessionUseCase`, la misma que
  «Empezar» de Inicio; con una sesión a medias avisa con el texto de `SESSION_STALE_OPEN`), «Abrir en la rutina» (día de
  rutina de otro día) o «Marcar como hecho» (lo que ya empezó o se quedó sin hacer).
- **Debajo**, con borde: «Marcar como hecho» / «Desmarcar» (si no es la principal; lo que aún no empezó lo explica con
  «Podrás marcarlo como hecho cuando empiece»), «Sí fui» / «No fui» en las clases (ADR 0029), **«Pasar a otro día»** (el
  mismo selector que Inicio, `showMoveDaySheet`, ahora en `widgets/move_day_sheet.dart`; misma hora; evento
  `CalendarEvent.blockMoved` y aviso «Pasado al jueves, 20 de noviembre a las 19:00» con «Ver», que va a ese día) y
  **«Eliminar»** en rojo, con icono y texto, **siempre en su propia línea, al final y separado**; deja «Deshacer» con
  el mismo verbo («Eliminado del calendario»). Los botones con borde van en fila, a partes iguales, solo si cada
  etiqueta cabe entera en su mitad (se mide con el ancho real y el tamaño de texto); si no, uno debajo de otro a todo el
  ancho: nunca parten una palabra. Lo fijo no se pasa a otro día y lo hecho tampoco: una nota gris dice por qué («Este
  evento es fijo y no se puede mover.», «Ya está hecho: desmárcalo antes de moverlo.»).
- Exámenes y entregas con entrega siguen abriendo la entrega (ADR 0039). Los enlaces `?block=` (avisos, Inicio) abren
  la ficha.
- **El formulario ya no lleva acciones.** `BlockEditorSheet` solo crea o cambia el evento; se quitan los resultados
  `focusRequested`, `rescheduleRequested`, `completionRequested`, `absenceRequested`, `trainingRequested` y
  `deleteRequested` (la papelera roja solo con icono, pegada a cerrar: borrar ya está en la ficha, desde donde se abre
  el formulario al editar).
- `CalendarBloc` deja de usar `RescheduleBlockToNextFreeSlotUseCase` («Al próximo hueco» desaparece también del
  calendario: se elige el día, como en Inicio).

### Guía de primer uso

Cinco pasos: «Añadir al calendario» (el «+» y la pulsación larga), «Toca un evento» (la ficha), «Mover un evento»
(«Mantén pulsado un evento para moverlo; arrastra su borde de abajo para cambiar cuánto dura»), «Tu semana en cifras»
(los chips) y «Entregas y exámenes» (el icono). El consejo de arrastrar ya no es un aviso que salía cada vez que se
abría la página: va en la guía, que se ve una vez por cuenta y teléfono.

## Consecuencias

- La rejilla gana unos 160-220 px en 390×844; el test de la vista comprueba que empieza antes de 190 px.
- Leer un evento ya no obliga a entrar en un formulario; cambiarlo sigue a un toque («Editar»).
- Sin cambios en el servidor ni en la API: la ficha usa lo que ya llegaba (bloques, línea de tiempo, retos, sesión).
- `RescheduleBlockToNextFreeSlotUseCase` y su llamada en `data/` quedan sin uso en el cliente; se pueden quitar en una
  limpieza (el endpoint del servidor no cambia).
- Pendiente de otra tanda: «Ir a la clase» de la maqueta (no hay a dónde ir más allá de la asignatura, que ya se abre).
