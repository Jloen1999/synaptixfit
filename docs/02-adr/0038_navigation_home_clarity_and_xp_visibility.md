# ADR 0038 — Navegación con Calendario, Inicio al grano y XP solo donde aporta

- **Estado:** aceptado
- **Fecha:** 2026-11-13

## Contexto

Una auditoría de claridad (noviembre de 2026, `docs/05-design/vocabulario.md` §4) encontró que la app no iba al grano:

1. **Navegación.** El calendario, lo que más se usa a diario, no estaba en la barra: se llegaba por cinco caminos desde Inicio («Planificar el día», «Calendario», «Planifica tus próximos días», «Planificar la semana» y los días de «Tu semana») y como pantalla completa. Retos ocupaba una pestaña propia aunque es una forma más de progresar.
2. **Inicio.** 33 acciones en una pantalla, dos o tres botones destacados a la vez, porcentajes de carga cognitiva, zona de ACWR y energía, kcal de la semana, «26 XP para el nivel 14», un «Empezar a correr» dentro de la tarjeta de gimnasio y «Termina de preparar tu app» por delante de lo de hoy. «Tu semana» se partía en dos filas (4 + 3) y dejaba un hueco. La cuenta atrás de un examen solo salía si faltaban 6 días o menos.
3. **«Cerrar semana».** Un botón con diálogo de explicación cuyo único efecto real era dar XP una vez por semana (los eventos ya se guardan solos). Nadie entendía para qué servía.
4. **XP en todas partes.** Avisos «Marcado como hecho · +X XP», diálogos «Se restarán N XP», pastillas de XP en tareas y tests, la barra de XP en el perfil. El propietario: «no es un dato requerido a nivel visual por la gente».

## Decisión

### Barra de navegación

- **Inicio · Calendario · Académico · Entreno · Progreso.** El orden de las ramas del `StatefulShellRoute` es el de la barra (`routes.dart`, `MainShellPage`); el modo de uso sigue ocultando Académico (solo deporte) o Entreno (solo estudios). Calendario se ve siempre: también planifica entrenos y lo personal.
- **Calendario es una pestaña** (`plannerBranchRoutes`, `/planner`). Se abre con `go`. Sus pantallas completas (`/planner/deadlines`, `/pomodoro`, `/suggestions`, `/past-study`, `/calendar-sync`, `/schedule-scan`) pasan a ser rutas sueltas de primer nivel, no hijas de `/planner`: si colgaran de la pestaña, abrirlas con `push` desde otra pantalla completa duplicaría el armazón (pantalla en negro). La página se recrea con una clave por consulta (`?week`, `?day`, `?block`, `?new`), así que un enlace nuevo vuelve a abrir lo pedido y la barra conserva lo que había. Como ya no se cierra al salir, `CalendarBloc` se refresca solo con los cambios del planificador, entreno y académico (`DataChangeRefreshMixin`).
- **Retos vive en Progreso**, junto al nivel, la racha y las insignias: Progreso tiene tres apartados, **Resumen · Retos · Insignias** (`?tab=challenges|badges`). Retos de la comunidad se abre aparte (`/challenges/community`) en vez de con otra fila de pestañas dentro de la pestaña.
- **Enlaces antiguos sin romper:** `/challenges` redirige a `/progress?tab=challenges` y `/progress/badges` a `/progress?tab=badges` (avisos de versiones anteriores, publicaciones del muro, apps viejas). `/challenges/:id`, `/challenges/new` y `/planner?block=…` siguen igual; los avisos (`RemindersHost`) abren el calendario con `go` y un reto con `push`. Todo lo que antes apilaba `/planner` con `push` (Académico, Correr, escanear horario, propuestas) ahora usa `go`.

### Inicio al grano

- **«Tu día» manda** y tiene **un solo botón**, el único destacado de la pantalla: «Concentrarme» (Pomodoro del evento) para estudio y repaso, «Empezar» (sesión en 1 toque) para el entreno, «Marcar como hecho» para lo personal en curso y, sin nada pendiente, «Añadir al calendario» (abre el calendario con la hoja de crear ya abierta en el próximo hueco, `?new=`). Una clase, una comida o un deporte sin día de rutina (un partido) no llevan botón: se ven y se marcan en la agenda.
- **Cuenta atrás siempre visible** del próximo examen (o, si no hay, de la próxima entrega): «Examen: Bioquímica · en 12 días» (`AppDueDates.countdown`, sin el límite de 6 días de las listas). La lista llega ordenada del servidor (`GET /planner/deadlines?upcoming=true`); Inicio elige el primer examen y si no la primera entrega.
- **Un solo camino al calendario:** su pestaña. Se quitan «Planificar el día», el enlace «Calendario» de la agenda y «Planificar la semana»; «Planifica tus próximos días» pasa a llamarse por lo que hace, «Importa tu horario» (abre el escaneo del horario). La tira de días de la agenda se queda (es la agenda) y los días de «Tu semana» siguen abriendo ese día.
- La tarjeta del próximo entreno pasa sus botones a secundarios y no repite «Empezar» si ya está en «Tu día»; «Empezar a correr» vuelve a Entreno › Correr.
- «Tu semana» va siempre en **una fila** (cada día ≥ 24 px, WCAG 2.5.8) y sin kcal; «Retos activos» solo sale si hay alguno; «Termina de preparar tu app» va **al final**.
- **Tu equilibrio** (carga cognitiva, carga física y energía con sus porcentajes) sale de Inicio y pasa a **Progreso › Resumen** (`BalanceCard`, que lee el mismo resumen del día con `GetHomeDashboardUseCase`).
- Acciones de Inicio, contadas en el estado de la auditoría (sin nada hoy, una entrega vencida, 3 repasos, una rutina en curso, sin retos, configuración a medias): **33 → 29** (sin contar los 14 botones de día: **19 → 15**), con **un** botón destacado en vez de dos y **un** camino al calendario en vez de cinco. Se quitan «Calendario», «Planificar la semana», «Empezar a correr», «Ver análisis» y «Crear reto»; «Planificar el día» pasa a «Añadir al calendario» y se suma la cuenta atrás.

### XP de planificar la semana, sin botón

- Se quita «Cerrar semana» (botón, diálogo, `SaveWeekPlanUseCase`, `GetWeekClosedUseCase` y sus textos).
- **Regla (servidor, `StudyPlan.rewardable`):** la semana da su XP de planificación **una sola vez**, cuando tiene **3 eventos planificados** y es **la semana actual o la siguiente**. Cuentan los eventos que pone la persona: ni fijos ni importados (horario escaneado, calendarios externos), ni los repasos que crea solo el repaso espaciado, ni descanso, comida o sueño (`ActivityType.countsInWeekPlan`). La cantidad es la de siempre, `100 + 5 × eventos` en ese momento.
- **Cuándo se comprueba:** al crear un evento (también sus copias semanales) y al repartir una rutina en el calendario (`CalendarBlockService` y `RoutineDistributionService` llaman a `RewardWeekPlanningUseCase`, que implementa `StudyPlanService`, dueño de los planes). No se comprueba en lecturas: un GET no da XP.
- **Por qué 3 y por qué solo esta semana y la siguiente:** con el primer evento bastaría crear uno suelto (o uno y borrarlo) para ganar una XP que antes pedía planificar; 3 refleja una semana pensada sin exigir llenarla. Sin el límite de semanas, 3 eventos en cada una de las 52 semanas siguientes darían la XP 52 veces de golpe (antes, «Cerrar semana» permitía algo parecido con semanas vacías).
- **No se da dos veces ni se pierde:** queda anotada en el plan de la semana (`planes_estudio.xp_planificacion_otorgado` y `_puntos`, ADR 0019). Borrar eventos después no la quita y volver a crearlos no la repite. `V1057` añade el índice único `(usuario_id, semana_inicio)` y antes junta los duplicados que hubiera (queda la mayor XP anotada; si dos duplicados la dieron, la persona conserva lo ganado). Qué cuenta como evento planificado lo decide el dominio (`CalendarBlock.plannedByPerson`).
- **Compatibilidad:** `PUT /planner/plans/{weekStart}` y `GET /plans/week/{weekStart}` siguen para las apps viejas: guardan nombre y visibilidad con la **misma** regla (una app vieja no gana más ni antes). La lógica del resto de XP no cambia.

### Dónde se ve el XP

- **Sí:** Progreso (nivel, barra y «Cómo se gana XP») y las celebraciones de `AchievementsHost` (subir de nivel, insignia nueva). El panel de administración sigue con sus cifras.
- **No:** avisos de marcar, desmarcar, apuntar estudio, actividades, carreras, registro diario, entregas, Pomodoro y recálculo de carga; diálogos de borrar o descompletar un reto; pastillas de XP en tareas, tests y repasos; detalle del reto; «Tu día»; perfil (queda la racha). El Pomodoro conserva su regla (`xpStatus`): con el tope diario lo dice, pero sin cifras.
- Lo mismo con kcal, carga, ACWR y porcentajes: fuera de Inicio y del calendario; en Progreso o en el detalle.

## Consecuencias

- **Positivas:** el calendario está a un toque desde cualquier pestaña; Inicio tiene una acción principal clara; la XP de planificar llega sin entender un botón; las pantallas del día a día no se llenan de números.
- **Negativas:** quien planificaba uno o dos eventos por semana deja de recibir esa XP (antes bastaba con cerrar la semana). Planificar con más de una semana de antelación no la da hasta que se añade algo en la semana siguiente. Progreso pide además el resumen de hoy (una petición más al abrirlo).
- **A vigilar:** si 3 eventos resulta mucho o poco, se cambia `StudyPlan.MIN_PLANNED_EVENTS` sin migración. Dos peticiones a la vez no chocan: el plan se crea con `INSERT … ON CONFLICT DO NOTHING` (propio de PostgreSQL, en `database_portability.md`) y la XP se anota con una actualización condicional (`… WHERE xp_planificacion_otorgado = false`), así que solo una la da. Mover un evento de semana no la da (solo crear o repartir). La insignia «Planificador nato» (3 planes) pasa a contar semanas que dieron esta XP.
