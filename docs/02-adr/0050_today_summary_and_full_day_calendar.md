# ADR 0050 — «Tu día» coherente con la agenda y calendario de 0 a 24 h

- **Fecha:** 2026-11-15
- **Estado:** aceptado
- **Modifica en parte:** ADR 0038 y 0041 (`nextUp` y lo que cuenta en «Tu día» ya no se calculan en el cliente)

## Contexto

Fase 1A del plan de mejoras. Dos fallos que la persona veía a diario:

1. **«Tu día» decía «Has terminado lo de hoy. ¡Buen trabajo!» con cosas sin hacer.** El cliente calculaba lo que
   tocaba (`nextUp`) ignorando lo que ya había pasado sin hacerse (`MISSED`) y, sin nada «por empezar», daba el día
   por terminado. La agenda, con los mismos eventos, los marcaba «Sin hacer». Las entregas de hoy salían en la agenda
   pero el anillo no las contaba. El test daba por bueno el fallo. Además, la regla («qué cuenta», «qué toca») vivía
   en el cliente.
2. **El calendario solo pintaba de 6:00 a 23:00.** Lo de madrugada o de noche no se veía (sin aviso), lo que cruzaba
   la medianoche no salía en el día siguiente y crear, mover o estirar estaban limitados a esa franja. En el móvil
   caben unos 2,8 días: el lienzo abría con hoy como primera columna, la barra horizontal quedaba al final de la
   cuadrícula y nada indicaba que había días a la izquierda («se saltaban días»). Los atajos «Entregas y exámenes» y
   «Concentrarme» ocupaban dos filas y el «Hoy» de la barra, en pantallas estrechas, era un icono de calendario que no
   se entendía.

## Decisión

### 1. Resumen del día en el servidor (`todaySummary`)

- **Dominio:** `TodaySummary` (`domain/model/dashboard/`), calculado sobre los mismos `todayEvents` que la agenda
  (`Dashboard.todaySummary()`), así no pueden contradecirse.
- **Qué cuenta:** los bloques con seguimiento (`ActivityType.isTrackable`) **menos las clases** (nadie las marca) y
  **las entregas de hoy**. Hecho = completado; pendiente = el resto, esté por empezar, en curso o sin hacer.
- **Evento destacado (`nextEventId`):** el que está en curso; si no, el próximo; si ya no queda nada por empezar, el
  último que quedó sin hacer (lo más reciente es lo más fácil de recuperar).
- **Estado (`state`):** `NOTHING_PLANNED` (nada que cuente), `PENDING` (algo en curso o por empezar), `MISSED_LEFT`
  (lo que queda ya pasó sin hacerse) y `ALL_DONE` (todo hecho y al menos uno).
- **API:** `GET /api/v1/dashboard` añade `todaySummary {done, total, missed, nextEventId, state}` (campo nuevo,
  compatible hacia atrás). Sin migración.

### 2. «Tu día» solo pinta el resumen

- `HomeDashboard.todaySummary` (`HomeTodaySummary`, `HomeDayState`); `TodayNext.nextUp` es el evento de
  `nextEventId`, y `TodayAction.of(summary, next)` solo elige el botón para ese evento. El anillo es `done/total`.
- «Has terminado lo de hoy» **solo con `ALL_DONE`**. Con solo clases: «Hoy solo tienes N clases» y «Añadir al
  calendario».
- **Lo que queda se nombra** (petición del propietario): con `MISSED_LEFT`, «Te queda:» + el título del evento + su
  hora con «sin hacer», y su botón directo: «Marcar como hecho» (los mismos casos de uso que la agenda, con
  «Deshacer») o «Empezar» si es un día de rutina, igual que en la agenda. Si queda más de uno (o, en `PENDING`, si
  algo ya se pasó), una línea «y N más» lleva el foco a la agenda de hoy.
- Una entrega de hoy pendiente se marca desde «Tu día» (se puede adelantar).
- Tras marcar, el evento se pinta hecho al momento y el resumen llega con el refresco de datos de siempre; mientras,
  sin botón (no se ofrece marcar lo ya marcado).

### 3. Calendario de 0:00 a 24:00

- `WeekGridGeometry` va por defecto de 0 a 24 h: crear, arrastrar y estirar en todo el día; estirar llega hasta las
  24:00 (medianoche del día siguiente) y el fin se calcula en hora de reloj (el día del cambio de hora también).
- **Lo que cruza la medianoche se pinta en sus dos días** (`dayParts`). El primer tramo es el bloque (foco, lector,
  arrastre); el del día siguiente solo se ve y se toca (el lector ya lo tiene en el primero), y el asa de la duración
  va donde acaba el evento.
- **Al abrir:** una hora antes del bloque pedido o, hoy, una hora antes de ahora (sin el tope de las 7:00); otro día
  (`?day=`), una hora antes de su primer evento y, sin eventos, a las 7:00.

### 4. Tira de 7 días, «Hoy» y atajos

- Si los 7 días no caben, una **tira de días** (`_WeekDayStrip`, con el chip compartido `AppDayChip`, el mismo de la
  agenda de Inicio) va encima del lienzo: lleva a cualquier día, marca el que se ve (seleccionado para el lector,
  «Lunes 16», «Hoy, miércoles 15») y sigue al desplazamiento a mano. `?week=` y `?day=` siguen igual.
- **«Hoy» sale de la barra** y va junto a ‹ › como texto corto, **solo si no se está viendo hoy** (otra semana o, en
  el móvil, otro día de esta; el lienzo avisa del día visible con `onVisibleDayChanged`).
- **Atajos en una fila:** «Entregas» y «Concentrarme», con icono y texto corto (el lector oye «Entregas y exámenes»,
  que empieza por el texto visible). Con el texto grande, la fila se desliza.

## Consecuencias

- La regla de «qué cuenta hoy» queda en un solo sitio (servidor), con test (`TodaySummaryTest`) e IT
  (`InsightsFlowIT`).
- El cliente ya no repite la regla; si el servidor no manda `todaySummary` (versión antigua), «Tu día» dice «nada
  planificado» y ofrece añadir.
- La cuadrícula es más alta (24 h): por eso se coloca al abrir donde importa.
- `docs/03-api/openapi.yaml` se regenera con el campo nuevo (`todaySummary`, `TodaySummaryResponse`).
