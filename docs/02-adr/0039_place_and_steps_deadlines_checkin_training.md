# ADR 0039 — Cada cosa donde se busca y en menos pasos (entregas, registro diario, Entreno)

- **Estado:** aceptado
- **Fecha:** 2026-11-13

## Contexto

Fase 3 del plan de claridad (`docs/05-design/vocabulario.md` §4). El propietario: «hay cosas ubicadas en lugares poco accesibles o poco intuitivos; el usuario debe poder hacer las acciones con pocos pasos». La auditoría encontró:

1. **Entregas y exámenes** escondidos en el ⋮ del calendario: apuntar una entrega costaba unos 8 toques. Además había **dos conceptos para lo mismo**: el tipo de evento «Examen»/«Entrega» del calendario (un bloque de `horarios_academicos` que crea a la vez una fila de `entregas_examenes`) y el elemento de «Entregas y exámenes». La persona veía dos cosas (el bloque y la entrega) que no se borraban juntas.
2. **Pomodoro** solo en el mismo ⋮ y en un icono ⏱ de la asignatura.
3. **Dos registros diarios:** «Contar cómo estoy»/«Registro completo» (4 escalas 1-5, 11 zonas de dolor, notas) y la tarjeta «¿Qué tal estás hoy?» (3 toques). Las escalas iban en sentidos opuestos: en sueño el 1 era malo; en estrés y agujetas, el 1 era bueno. En la tarjeta, «Bien» estaba a la izquierda; en la pantalla, «Excelente» a la derecha.
4. **Evento de estudio:** la asignatura estaba en «Más opciones» (3 toques de más).
5. **Entreno › Gimnasio** con 27 acciones: chequeo abierto, 15 sugerencias, «Apuntar un partido», y un botón flotante «Nueva rutina» que tapaba «Saltar este día» y «Ahora no». Dos caminos a la sesión abierta («Sesión en curso · Volver» y «Continuar»).
6. **Correr:** «Tus actividades» mezclaba sesiones de gimnasio; en la web se pintaba un mapa vacío de España.
7. **Asignatura:** «Archivar» y una papelera roja en la barra; ⏱ y ✏ recortaban el título. En Académico, el icono 👥 de «Apuntes compartidos» parecía «Amigos». En Entregas, cada fila llevaba ○ y 🗑.
8. Pendientes de la fase 2: la cuenta atrás de «Tu día» la elegía el cliente con las 20 primeras entregas; los umbrales 0,3 · 0,6 · 0,8 de carga (y 0,4 · 0,7 de atención) vivían en el cliente; «Tu equilibrio» no tenía estado de error.

## Decisión

### Entregas: un solo concepto

- **La entrega (`entregas_examenes`) es lo único que la persona apunta y ve.** Al crear, «Examen» y «Entrega» de la hoja «Añadir al calendario» son botones con flecha (y la pista «Abre el formulario de entrega» para el lector), no opciones del grupo de tipos: cierran la hoja y abren el **mismo formulario corto** que «Nueva entrega» (`DeadlineFormSheet`), con el tipo, la asignatura y la hora del hueco ya puestos (`BlockEditorOutcome.deadlineRequested` → `PlannerPaths.newDeadline`). En el calendario la entrega se ve en la franja de entregas de la semana, no como un evento aparte.
- **Sin perder datos y sin migración.** Los bloques EXAM/DELIVERY que ya existen (creados antes o importados de un `.ics`) se quedan como están: siguen ocupando su hueco, se mueven arrastrando y su entrega sigue la hora (`followLinkedDeadline`). Tocar uno en el calendario abre **su entrega** (`/planner/deadlines?focus=<id>`), no el editor de eventos: la persona ve una sola cosa. Si su entrega se borró (la FK es `ON DELETE SET NULL`), se abre como un evento normal para poder quitarlo.
- **El servidor no cambia el contrato:** `POST /planner/blocks` con EXAM/DELIVERY sigue creando la entrega vinculada (apps antiguas e importación de horarios). Por qué no se convierten los bloques en entregas con una migración: un examen importado ocupa una franja (9:00-11:00) que la entrega sola no guarda; borrarlo perdería esa información y la importación `.ics` lo volvería a crear.
- **Formulario corto:** el título lleva el foco, «Hecho» del teclado guarda y la fecha tiene los atajos «Mañana» y «En una semana» (la propuesta). Si se abrió para apuntar una entrega y se cancela, se vuelve a donde se estaba. Apuntar una entrega desde Académico: «Nueva entrega» → escribir el título → «Guardar» (**2 toques**, 3 si se cambia la fecha con un atajo; antes ~8).
- **Accesos a la vista:** «Nueva entrega» en Académico (bajo el buscador) y en cada asignatura (con la asignatura puesta); en el Calendario, «Entregas y exámenes» y «Concentrarme» son botones visibles (`_Shortcuts`), y el ⋮ queda para lo ocasional (sugerir un plan, estudio ya hecho, importar y sincronizar).
- **Borrar una entrega** ya no ocupa sitio en cada fila: se desliza la fila (con «Deshacer»), está en el formulario («Eliminar») y, para el lector de pantalla, es una acción de la fila (`CustomSemanticsAction`). Marcar como hecha sigue a un toque.

### Pomodoro

«Concentrarme en esta asignatura» es un botón con texto en la cabecera de la asignatura (cuenta para ella) y «Concentrarme» está en Académico y en el Calendario. Inicio lo ofrece en «Tu día» cuando toca estudiar (ADR 0038). Ningún menú escondido es el único camino.

### Un solo registro diario: «¿Qué tal estás hoy?»

- Un nombre en toda la app, en los avisos (`CHECK_IN`) y en la guía de XP: **«¿Qué tal estás hoy?»**. Las mismas tres preguntas (`CheckInQuestions`) en la tarjeta de Entreno y en la pantalla del registro; la primera vez del día, **con la tercera respuesta se guarda** (3 toques, sin «Listo»), y se avisa antes con una línea («Se guarda al contestar la tercera»). Al cambiar un registro ya hecho, las tres vienen contestadas y se guarda con «Guardar cambios». Al guardar, el foco pasa a «Cambiar». «Añadir detalles» (estrés, zonas con dolor, «Me siento listo para entrenar», notas) es opcional y está plegado; con los detalles abiertos guarda «Guardar». Se mantienen el consentimiento de salud (`ensureHealthConsent`) antes de guardar y la entrada opcional a «Mi ciclo».
- **Todas las respuestas en el mismo sentido: a la derecha, lo mejor** («Mal · Regular · Bien», «Baja · Normal · Alta», «Muchas · Algo · Nada», «Mucho · Bastante · Algo · Poco · Nada»). El historial las dice en palabras, no en números.
- **Solo cambia la presentación; el servidor y la base de datos no.** El servidor sigue guardando las escalas 1-5 de siempre (sueño y energía: 5 = bien; estrés y agujetas: 5 = mucho). Se descartó convertirlas con una migración: la fatiga (`(6−sueño)·5 + (estrés−1)·5 + (6−energía)·4 + (agujetas−1)·7`), la energía (`EnergyScore`, con sus compuertas por agujetas ≥ 4 y sueño ≤ 1), la adaptación de la sesión y el historial dependen del sentido actual; invertir columnas habría obligado a cambiar todas las fórmulas a la vez, los registros antiguos y la API, sin ganar nada para la persona.
- La tarjeta de Entreno va **plegada en una línea** (que sigue ahí para volver a plegarla) hasta que se abre; después explica la adaptación de hoy.

### Evento de estudio

En Estudio y Repaso la asignatura sale en el paso 1 («¿Qué es?»); en el resto de tipos sigue en «Más opciones».

### Entreno

- **Gimnasio:** se ven el próximo entreno y tus rutinas; «Nueva rutina» pasa a la cabecera de «Mis rutinas» (sin botón flotante que tape «Saltar este día» o «Ahora no»); las sugerencias se pliegan en «Ver sugerencias»; «Apuntar un partido u otra actividad» va a Correr.
- **Un camino a la sesión abierta:** en Gimnasio, la barra «Sesión en curso · Volver» no sale para la sesión que ya retoma «Continuar» de la tarjeta del día (Gimnasio publica ese día en `ContinueSessionTarget` y la barra lo compara con el de la sesión). Una sesión de otro día u otra rutina sigue con su barra, y en el resto de la app la barra es el camino.
- **Correr:** con una carrera a medias, «Seguir con la carrera» es el único botón principal; apuntar una actividad tiene un solo nombre («Apuntar un partido u otra actividad»). «Tus actividades» (y el historial «Actividades y partidos») ya no incluye entrenos de rutina: el servidor excluye los bloques de deporte que reflejan un día de rutina (`dia_rutina_id`, la misma definición que `CalendarBlock.mirrorsTrackedActivity`; con rutina pero sin día es deporte libre y sí sale) en `LoggedActivityJdbcAdapter`. Sin GPS (web, escritorio) no se pinta el mapa: lista y «Apuntar a mano».

### Asignatura y Académico

La barra de la asignatura solo lleva el ⋮ (Editar, Archivar/Restaurar, Eliminar): el título ya no se recorta; la cabecera se desplaza con el contenido (texto al 200 %). En Académico, «Nueva entrega», «Concentrarme» y «Apuntes compartidos» son botones con texto bajo el buscador (el icono 👥 parecía «Amigos» y en la barra recortaba el título).

### Reglas que pasan al servidor

- **Cuenta atrás de «Tu día»:** `GET /dashboard` devuelve `nextDeadline` (`Dashboard.countdownOf`): el próximo examen pendiente y, si no hay, la próxima entrega pendiente, en un horizonte de 366 días. El cliente ya no la calcula ni pide las entregas para ello.
- **Niveles de «Tu equilibrio»:** `cognitive.loadLevel` (LOW, MODERATE, HIGH, CRITICAL con 0,3 · 0,6 · 0,8) y `cognitive.attentionLevel` (LOW, MODERATE, HIGH con 0,4 · 0,7) los da el servidor (`CognitiveLevel`). Un servidor antiguo que no los mande deja la tarjeta sin el nivel en palabras.
- **«Tu equilibrio» con error:** si no se puede leer, Progreso › Resumen muestra el título con el motivo y «Reintentar» en vez de ocultar la tarjeta.

## Toques antes → después

| Acción | Antes | Después |
|---|---|---|
| Apuntar una entrega (desde Académico) | ~8 (Calendario, ⋮, Entregas, Nueva entrega, campos, Guardar) | 2 («Nueva entrega» y «Guardar» o «Hecho» del teclado; el título se escribe) |
| Empezar un Pomodoro de una asignatura | 3 (Calendario, ⋮, Pomodoro) o un icono sin texto | 1 («Concentrarme en esta asignatura» o «Concentrarme») |
| Registro diario | 4 (3 respuestas + Listo) o la pantalla de 4 escalas | 3 (la tercera respuesta guarda) |
| Evento de estudio con asignatura | +3 por «Más opciones» | la asignatura está en el paso 1 |

## Consecuencias

- Sin migraciones ni cambios de esquema (V1059–V1062 quedan libres). Cambios de API solo aditivos: `nextDeadline`, `loadLevel`, `attentionLevel`; `GET /planner/past-activities` ya no lista entrenos de rutina (lo que su documentación ya decía).
- Hay que regenerar `openapi.yaml` al cerrar la fase.
- Las apps antiguas siguen funcionando: crean bloques EXAM/DELIVERY y calculan su propia cuenta atrás.
