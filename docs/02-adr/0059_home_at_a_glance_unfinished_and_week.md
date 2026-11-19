# ADR 0059 — Inicio al grano: «Tu día» en filas, lo que quedó a medias y «Tu semana» en una frase

- **Fecha:** 2026-11-19
- **Estado:** aceptado (maqueta `inicio-calendario.html`, pantallas 1, 2 y 6, aprobada por el propietario el 19 nov 2026,
  tanda 1)

## Contexto

La revisión del 19-11 con estudiantes reales dejó claro que Inicio no se entendía de un vistazo:

- «Tu día» medía 300-350 px (anillo de 64 px, «Ahora / A continuación / Te queda», «Hoy toca: entreno normal» suelto y la
  cuenta atrás) y la Agenda empezaba hacia y≈500 en un móvil de 390×844. El título del evento no se podía tocar y «Hoy
  toca» no decía **qué** entreno.
- Una sesión de entreno abandonada (`SESSION_STALE_OPEN`) salía como un aviso sin acciones y «Empezar» fallaba sin
  salida, aunque `nextTrainingDay.staleSessionId` ya llegaba al cliente.
- Lo que quedó sin hacer era un aviso genérico con «Al próximo hueco» (el usuario no elige el día) y «Hecho»; un deporte
  mandaba al calendario.
- «Tu semana» pintaba columnas apiladas con «2/3» por día y «N de M hechos esta semana»: no se entendía.
- No había forma de ver las solicitudes de amistad desde Inicio en el móvil.

## Decisión

### Servidor (todo aditivo en `GET /dashboard` y `GET /training/sessions/open`)

- **Aula y profesor** de cada evento (`todayEvents[].place`, `.teacher`): el aula del propio evento (`horarios_academicos.
  ubicacion`, la del horario importado) y, si no la trae, la habitual de su asignatura (`asignaturas.aula`, ADR 0036); el
  profesor es `asignaturas.docente`. Regla en `CalendarBlock.where()` (la misma que `SubjectAgenda`). Sin migración: las
  columnas ya existían.
- **Fila del evento de «Tu día»** (`todaySummary.spotlightEventId`, `TodaySpotlight`): lo que está en curso; si no, lo
  próximo; si ya no queda nada, lo último sin hacer que aún se puede marcar. A diferencia de `nextEventId` (ADR 0050),
  **entran las clases** (la fila dice cuál, a qué hora y en qué aula) y no entran las entregas (tienen su fila, la cuenta
  atrás) ni los días de rutina (los nombra la fila del entreno). `nextEventId` se conserva para apps anteriores.
- **El entreno es hoy** (`nextTrainingDay.dueToday`): el próximo día de rutina toca hoy o va con retraso. Entonces sale
  en «Tu día» y «Próximo entreno» desaparece de Inicio.
- **Sesión a medias** (`unfinishedSession`: `sessionId`, rutina, día, `startedAt`, `exercisesDone`, `exercisesTotal`,
  foto): la más reciente que hay que cerrar. La regla es del dominio, `TrainingSession.isLeftover(now)`: abierta **más de 6 h**
  (`STALE_AFTER`). El cambio de día no cuenta: quien empieza a las 23:30 sigue entrenando pasada la medianoche sin que
  se le pida cerrarla (decisión del 19-11 tras revisarlo); una sesión de ayer olvidada ya lleva más de 6 h. Mientras
  tanto sigue en curso (barra «Seguir entrenando»). La misma regla rige al **empezar** (`SESSION_STALE_OPEN` si la del mismo día de
  rutina está a medias: no se mezclan series de dos jornadas) y al **guardar** (`completionInstant(…, zone)`: cuenta en
  el día en que se hizo). Zona: Inicio usa la del móvil (`tz`); empezar y guardar, la de la app
  (`synaptixfit.insights.default-zone`), como el resto de sesiones; solo difieren para quien está en otra zona. `exercisesDone` = ejercicios distintos con alguna serie de trabajo hecha
  (`TrainingSession.exercisesDone()`); `exercisesTotal` = ejercicios del día (`SessionLabel.exerciseCount`, nulo en una
  sesión libre). `OpenSessionResponse` gana los mismos dos campos.
- **Lo de ayer sin marcar** (`missedEvents`): los mismos bloques que el aviso (`SmartBannerRules.missedForBanner`: ni
  clases ni lo personal) pero solo los de **ayer**, el más reciente primero, con nombre, día y hora. Lo de hoy ya lo
  dicen «Tu día» y la agenda. Por eso el aviso de Inicio ya **no elige** `MISSED_BLOCKS` (el servidor le pasa 0 a
  `SmartBannerRules.choose`) y deja sitio al siguiente aviso (entregas, registro diario…); el tipo sigue existiendo y
  una app anterior simplemente ve otro aviso.
- **Solicitudes de amistad** (`pendingFriendRequests`): las recibidas sin responder (`ListFriendshipsUseCase`, `RECEIVED`,
  una página de uno; solo se cuenta).
- **«Tu semana» en una frase** (`weekSummary`: `done`, `planned`, `missed`, `state`; `WeekSummary.of`): `NO_PLAN` sin nada
  planificado; `BEHIND` cuando más de una de cada cuatro cosas que ya tocaban (hechas + sin hacer) se quedó sin hacer;
  si no, `ON_TRACK`. Una falta en una semana cargada no es ir mal; la mitad sin hacer, sí.
- **Marca de cada día** (`planWeek[].mark`, `.pending`; `PlanDay.mark()`): `NONE` (nada planificado), `DONE` (todo hecho),
  `MISSED` (algo sin hacer; manda sobre lo demás porque es lo que aún se puede recuperar), `PARTIAL` (algo hecho y algo
  por hacer) o `PENDING` (solo por hacer; el cliente pinta cuántos quedan).
- **Estudio planificado de la semana** (`week.studyMinutesPlanned`): estudio y repaso (`countsAsStudy`; la clase es
  asistencia) para «Estudio 5 h de 8 h».

No hay errores nuevos: `SESSION_STALE_OPEN` ya estaba en el catálogo.

### Cliente

- **Cabecera**: icono de personas «Comunidad» también en el móvil, con el número de solicitudes (`Badge`) y la etiqueta
  «Comunidad, 2 solicitudes de amistad». Por ahora abre Amigos (en «Recibidas» si hay); la tanda 3 lo llevará a «Tú ›
  Comunidad».
- **«Sin terminar: <sesión>»** arriba de Inicio (`UnfinishedSessionCard`) con «Empezado el <día> a las <hora> · N de M
  ejercicios» y dos botones con una línea debajo que explica qué hacen: **Guardar lo hecho** (pide minutos y esfuerzo,
  como en Gimnasio; `FinishSessionUseCase`; cuenta en el día en que se hizo) y **Descartar** (rojo y aparte; confirma y
  deja «Deshacer»: se quita al momento y `CancelSessionUseCase` se llama al cerrarse el aviso, `DeferredCommitMixin`).
  Mientras está, «Guardar lo hecho» es el único botón destacado y «Empezar» de «Tu día» se desactiva con «Primero guarda
  o descarta la del <día>». Si «Empezar» devuelve `SESSION_STALE_OPEN` (carrera con otro dispositivo), el bloc vuelve a
  leer Inicio (`showUnfinished`) y la página lleva el foco a la tarjeta con un aviso que lo explica.
- **«Ayer quedó sin marcar»** (`MissedEventsCard`): el evento con nombre, día y hora y tres botones: **Lo hice** (como la
  agenda; un día de rutina se apunta como sesión de ese día con `LogPastSessionUseCase`, porque marcarlo a mano no avanza
  la rutina, `BLOCK_ROUTINE_LINKED`), **Pasar a otro día** (hoja con hoy si aún no ha pasado esa hora, mañana, los cinco
  siguientes y «Otro día…»; misma hora y duración, `RescheduleBlockUseCase`; el aviso dice a cuál y lleva «Ver») y
  **Quitar** (rojo y aparte; `DeleteBlockUseCase` aplazado con «Deshacer»). Con varios, uno y «Ver los N». El evento se
  abre en el calendario al tocarlo y el nombre de la sesión a medias abre la sesión (lo que se marcó).
- Con el «Deshacer» de «Descartar» aún abierto, la tarjeta ya no se ve y «Empezar» vuelve a estar activo: al pulsarlo,
  el bloc confirma antes el descarte pendiente. «Empezar» de la agenda se desactiva igual que el de «Tu día».
- **«Tu día» compacto** (`TodayHeroCard`): «Tu día» con «2 de 5 hechos» y una barra fina; debajo, filas que dicen cuál
  es cada cosa y se abren al tocarlas (la zona y su botón son hermanos, no anidados): el entreno de hoy (foto 48 px,
  «Entreno de hoy · suave», la sesión, «≈ 45 min · 6 ejercicios · rutina» y «Empezar» en la fila; tocar abre la rutina),
  el evento de ahora o siguiente (hora, «Clase de …», aula y profesor; «Concentrarme» o «Marcar como hecho» según
  `TodayAction.forEvent`) y la entrega o el examen más cercano («Examen · en 4 días»; abre esa entrega). Un solo botón
  relleno; los demás, tonales. «y N más» es un botón con borde. Con el texto grande, el botón de cada fila baja de línea.
- **«Tu semana»**: pastilla «Vas bien / Vas por detrás / Semana sin plan», «8 de 12 cosas hechas · 2 se quedaron sin
  hacer», un círculo por día con una marca que no depende del color (✓, medio lleno, «!», el número, «–»), leyenda corta
  y «Entrenos 2 de 3» / «Estudio 5 h de 8 h» con su barra. Cada día sigue abriendo ese día en el Calendario. La fila de
  días va sin relleno lateral para que cada día mida 48 px en 390.
- **Botones con forma de botón** en la agenda: «Empezar» tonal, «Ya lo hice», «Ver N más» y «Repasar todos» con borde;
  la fila de un repaso lleva «Repasar» en gris con flecha (toda la fila abre).
- **Guía de primer uso**: «Tu día» (filas y «Empezar»), la agenda, «Tu semana» (qué significan las marcas) y Comunidad.

## Consecuencias

- La Agenda empieza hacia la mitad de la pantalla en 390×844 con entreno, clase y examen (test de la vista).
- Lo que quedó a medias deja de ser un callejón: cada tarjeta dice cuál es y qué pasará con cada botón.
- Una sesión empezada a las 23:30 sigue en curso pasada la medianoche; si se guarda al día siguiente, cuenta en el día
  en que se empezó (`completionInstant(…, zone)`).
- `HomeDashboardBloc` ya no usa `RescheduleBlockToNextFreeSlotUseCase` (Inicio no ofrece «Al próximo hueco»); el caso de
  uso sigue para el resto de la app.
- La API cambia de forma aditiva: hay que regenerar `docs/03-api/openapi.yaml`.
