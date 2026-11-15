# ADR 0045 — «Estudiamos juntos»: salas con temporizador común y topes de «Con amigos» desde el servidor

- **Fecha:** 2026-11-15
- **Estado:** aceptado

## Contexto

Fase C2 del plan premium. La C1 (ADR 0044) dejó «Con amigos» asíncrono: retos entre amigos, racha con un amigo y
«Entrenamos juntos», con invitaciones, salida con «Deshacer», bloqueo, denuncia y `FriendshipEnded`. Faltaba estudiar
**a la vez**: una sala de 2 a 5 amigos con el mismo temporizador, sin chat, en la que cada ronda cuente como el
Pomodoro de siempre. El servidor no tiene WebSocket y el PC del propietario es modesto: la solución debe ser una
consulta periódica.

## Decisión

### 1. La sala

- Quien crea y de **1 a 4 amigos mutuos** (`StudyRoom.MAX_FRIENDS`). Se reutiliza `TogetherMembers` (invitar, aceptar,
  decir que no, salir y volver con «Deshacer»), `TogetherPeople` (solo amigos mutuos; volver solo si se sigue siendo
  amigo de quien la creó y sin bloqueos con nadie de dentro) y `TogetherNotifier` (aviso social
  `STUDY_ROOM_INVITED`).
- Rondas de **25 + 5** (`SHORT`) o **50 + 10** (`LONG`) minutos, de **1 a 4** rondas. Sin descanso tras la última.
- Tablas propias de Social (`salas_estudio`, `salas_estudio_miembros`, V1065), sin entidades JPA (`JdbcClient`), como
  la C1. API en `/api/v1/together/study-rooms`.

### 2. El tiempo lo da el servidor

- Solo se guarda la **hora de inicio**. La fase (`WAITING`, `FOCUS`, `BREAK`, `FINISHED`, `EXPIRED`), la ronda y
  cuándo termina la fase las calcula `StudyRoom.momentAt(ahora)` en cada lectura.
- Cada respuesta lleva `serverTime`. El móvil guarda la diferencia con su reloj y pinta la cuenta atrás cada segundo
  con su reloj corregido; consulta cada **12 s** solo mientras la pantalla está abierta y, al llegar a cero, pide la
  fase siguiente al servidor (no la deduce). Sin WebSocket.
- **Nadie gobierna la sala:** cualquiera que esté dentro pulsa «Empezar», una sola vez; después va sola, sin pausas
  (pausar a uno pararía a todos). Por eso, si quien la creó se va, todo sigue igual para los demás: no hay anfitrión
  que heredar. `creador_id` solo sirve para la regla de bloqueo de la C1 (`leavingWhenSeparated`).
- **Caduca sola:** al terminar la última ronda o, si nadie la empieza, **4 h** después de crearla
  (`StudyRoom.WAITING_LIMIT`). Una sala vacía no se cierra antes: sigue su reloj hasta esos límites (como mucho,
  4 × 50 + 3 × 10 minutos en marcha), y quien estaba invitado aún puede entrar.

### 3. Cada ronda es un Pomodoro normal

- Al terminar una ronda se apunta a **cada persona que estaba dentro al acabar** un Pomodoro con
  `RecordFocusSessionUseCase` (el mismo que el temporizador de siempre): suma racha, retos, «Estudia y muévete», racha
  con un amigo y retos entre amigos, con la XP normal y su tope diario. **Sin XP extra por estar en grupo.**
- Minutos de cada uno: desde que entró (si llegó tarde) hasta el final de la ronda (`StudyRoom.creditsDue`). Para la
  racha valen las mismas reglas que un Pomodoro suelto (10 minutos como mínimo, `FocusRewards`).
- **Quién apunta:** un programador cada minuto (`StudyRoomScheduler`, `synaptixfit.together.study-room-cron`), aunque
  nadie tenga la pantalla abierta; y, antes de salir (a mano o por `FriendshipEnded`), las rondas ya terminadas, para
  que quien sale no pierda lo hecho. Quien sale antes del final de una ronda no la suma.
- **Una sola vez:** `rondas_contadas` se reserva con comparar y cambiar (`UPDATE … WHERE rondas_contadas = :antes`);
  solo la petición que gana apunta. Las escrituras normales de la sala nunca tocan esa columna ni la hora de inicio
  ya puesta.
- **Sin pisarse:** toda acción que cambia la sala la lee bloqueada (`SELECT … FOR UPDATE`, `findByIdForUpdate`), porque
  guardar escribe a todas las personas: sin el bloqueo, dos que aceptan a la vez, o una que sale mientras otra
  reacciona, podían deshacer lo de la otra (y con ello quién suma la ronda). Lo mismo se aplica ya a los retos con
  amigos y a «Entrenamos juntos» de la C1 (unirse, decir que no, salir, reaccionar, quitar la reacción, empezar y
  `FriendshipEnded`), que tenían el mismo riesgo.
- Si la asignatura elegida se eliminó durante la sala, la ronda cuenta sin asignatura (se comprueba antes; no se
  captura el error, que marcaría la transacción para deshacerse). Una ronda de antes de ayer (servidor parado) no
  se apunta, igual que el Pomodoro de siempre.
- Se valoró que cada móvil registrara su Pomodoro al acabar: se descartó porque con la app cerrada o sin red se
  perdía la ronda y porque el servidor ya sabe quién estaba.

### 4. Privacidad y moderación

- **Solo amigos mutuos.** Se ve quién está dentro, quién está invitado y quién se ha ido; de cada persona, solo nombre
  y foto y su última reacción de los últimos **2 minutos**.
- **La asignatura de cada uno es privada:** la elige cada persona (o ninguna) y solo vuelve en su propia respuesta
  (`mySubjectId`). Nunca se comparten bienestar, ciclo, fatiga, sueño ni registro diario.
- **Sin chat:** cuatro reacciones fijas (👏 🔥 💪 ☕), una por persona que se sustituye, sin avisos.
- Bloquear y denunciar desde el menú de cada persona (`TogetherMemberMenu`, contexto `STUDY_ROOM`). `FriendshipEnded`
  saca de la sala con la regla de la C1.
- Borrado y exportación incluyen `salas_estudio_miembros` (y las salas creadas en la exportación).

### 5. Topes de «Con amigos» desde el servidor

`GET /together/limits` devuelve los topes (24 amigos en un reto, 4 en un entreno o una sala, 5 rachas, 4 rondas) y
las duraciones de ronda (`studyRoomLengths`: 25 + 5 y 50 + 10).
`FriendPickerBloc` los pide según a qué se invita (`TogetherInviteKind`) y el cliente ya no los repite; el servidor los
vuelve a comprobar (`TOGETHER_GROUP_SIZE`).

### 6. Entradas y nombres

En pantalla se llama **«Estudiar juntos»** (título y apartado) y el botón es **«Estudiar con amigos»**, como «Entrenar
con amigos»; el aviso dice «Estudiamos juntos». Solo aquí se dice «sala» (vocabulario §1). **Salir no pregunta y se
aplaza** hasta que se cierra su aviso con «Deshacer» (`DeferredCommitMixin`): deshacer no toca el servidor, así que no se
pierden los minutos de la ronda en curso. Si ya no se está en la sala (`STUDY_ROOM_NOT_FOUND`), la pantalla lo dice y
solo ofrece «Volver». Al pulsar «Unirme» o «Empezar» el foco pasa al siguiente control o a la cuenta atrás, y el final de
la sala se anuncia al lector.

Una sola acción principal en cada pantalla. «Con amigos» tiene el apartado «Estudiar juntos» (con «Estudiar con
amigos» en su cabecera) y las invitaciones; el Pomodoro, antes de empezar, un botón secundario «Estudiar con amigos»
que lleva su asignatura.

### 7. «10 horas de concentración» en grupo

La versión en grupo que la fase B dejó pendiente (ADR 0043) ya la cubren los **retos entre amigos** de la C1: la
plantilla «10 horas de concentración» se puede hacer «Juntos» (meta común) o en competición, con el tope diario de
120 minutos. Ahora, además, cada ronda de sala suma a esos retos. No hace falta otra plantilla.

## Consecuencias

- Nueva migración V1065 (dos tablas y el contexto `STUDY_ROOM` en las denuncias), 11 casos de uso en el servidor y
  9 en el cliente; un código de error nuevo (`STUDY_ROOM_NOT_FOUND`) y un aviso nuevo (`STUDY_ROOM_INVITED`).
- Hasta un minuto entre el final de una ronda y su Pomodoro en el historial si nadie sale ni abre la sala.
- La sala queda guardada (quién, cuándo, qué asignatura eligió cada uno) como los entrenos con amigos, hasta borrar
  la cuenta. Si crece, se podrán purgar las salas terminadas hace más de N días (hoy no hace falta: pocas filas).
- El aviso del móvil al cambiar de fase, la barra de sala abierta y salir sin apuntar en ese momento se resolvieron en
  el cierre del plan premium (abajo).
- `LegalTerms.CURRENT_VERSION` pasa a `2026-11-15` al cerrar «Con amigos» (decisión del propietario): una sola
  versión nueva recoge los enlaces de rutina (ADR 0043), la C1 (ADR 0044) y la sala; cada persona la acepta otra vez
  una vez al entrar.

## Cierre del plan premium (2026-11-15)

Antes de compilar, se dejaron a cero los pendientes de las fases A, B, C1 y C2. Decisiones:

### Fase A (ADR 0042)

- **La foto del detalle de sesión la elige siempre el servidor.** Nuevo `GET /api/v1/training/history/{sessionId}`
  (`GetSessionHistoryEntryUseCase`): la sesión como en el historial, con su `coverImageUrl` de `SessionLabel.withCover`.
  El detalle abierto sin pasar por el historial (aviso, Inicio, enlace) lo usa en vez de elegir la foto en el cliente.
- **La portada de un día de rutina** (próximo entreno de Inicio y Gimnasio, tarjeta de rutina) es la del primer
  ejercicio **con foto** (`RoutineDay.coverExercise`), la misma regla que las tarjetas de sesión; si ninguno la tiene,
  el primero. Antes, si el primer ejercicio no tenía foto, la tarjeta quedaba sin ella.
- **«Pausar racha» y «Reanudar»** enseñan un indicador de carga en su propio botón (el lector oye «Cargando») y no se
  pueden pulsar dos veces.
- **La vista previa del repaso hace una sola lectura** de los repasos programados (la ventana que cubre las seis
  notas) en vez de seis; cada día cuenta igual, así que da las mismas fechas que el repaso de verdad.
- **`PeekStreakUseCase`** (leer la racha sin guardarla) es un caso de uso aparte de `GetStreakUseCase`: un caso de
  uso, una acción. El catálogo de insignias usa el primero y la evaluación, el segundo.
- **Franja de la foto:** la cambió el propietario en el hilo principal (foto a todo color arriba y texto debajo, sobre
  la superficie lisa; ver ADR 0042), así que el texto ya no pisa la foto.
- **Titular de Progreso:** con menos de una hora de estudio dice los minutos («25 min de estudio»), como Inicio, en vez
  de «0 h».

### Fase B (ADR 0043)

- **Recuento de retos con regla:** solo se leen los vigentes y los que acabaron hace menos de un día
  (`Challenge.RULE_RECOUNT_GRACE`, margen para desmarcar lo del último día); pasado ese margen el resultado queda fijo.
- **DTO anidados** de plantillas de reto y de rutina y de enlaces de rutina, al paquete `dto/` (los nombres del esquema
  OpenAPI no cambian).
- **Semanas planificadas:** el reto «Planifica tu semana» cuenta la semana cuando dio la XP de planificar
  (`planes_estudio.xp_planificacion_en`, V1066), no cuando se creó el plan: un plan creado antes de empezar el reto que
  llega a los tres eventos después sí cuenta. Las filas anteriores toman la fecha de creación, así que ninguna cifra ya
  mostrada cambia.
- **`WEB_APP_URL`** (opcional, `--dart-define`): dirección de la app web para el enlace de rutina si la API y la web
  se separan. Sin ella, todo sigue igual (la web usa su origen y el móvil el de la API).
- **Concurrencia cerrada:** «Empezar este reto» (y copiar un reto de plantilla) bloquea antes la fila de la persona
  (`lockTemplateStarts`, `SELECT … FOR UPDATE` sobre `usuarios`) y «Compartir enlace» la de la rutina (`lockRoutine`):
  dos peticiones a la vez esperan una a la otra y la segunda ya ve el reto o el enlace de la primera. No se usó un
  índice único porque «un reto sin terminar por plantilla» depende de la fecha (los vencidos no cuentan). La
  transacción que empieza un reto no bloquea retos ya existentes, así que no se cruza con las que actualizan retos y
  después la experiencia.
- **Diseño:** la tarjeta de plantilla de rutina lleva dos pastillas (días y minutos, y carreras o exámenes si los hay);
  lugar, nivel y semanas van en una línea de texto. Los filtros pasan a una hoja («Filtrar (2)», «Ver 5 plantillas»,
  «Quitar filtros» fuera): antes ocupaban la primera pantalla entera y la lista no se veía. Un reto que se cuenta solo
  ofrece «Ir a…» según lo que cuenta (Concentrarme, Ir a Académico, Ir a Entreno, Ir a Correr, ¿Qué tal estás hoy?,
  Ir al calendario) y no enseña «Añadir tareas» ni el progreso a mano. Las horas se escriben con su palabra
  («10 horas»), así el lector no dice «10 h». En la hoja de compartir, cada botón tiene su propia carga y, tras dejar de
  compartir, el foco vuelve al ⋮ de la rutina. La rutina compartida abierta desde el enlace tiene flecha para volver
  (a Entreno) aunque no haya pantalla debajo.

### Fase C1 (ADR 0044)

- **Rutina cambiada después de copiarla:** al entrar en un «Entrenamos juntos», la copia se reutiliza solo si ese día
  tiene los mismos ejercicios en el mismo orden (`RoutineDay.sameSlotsAs`); si no, se copia la versión nueva (en
  pausa) y la anterior se queda, con su historial. No se pregunta: así el panel compara los mismos huecos.
- **Proponer una racha:** selección única con botones de opción (`RadioGroup`), porque solo se elige un amigo.

### Fase C2 (este ADR)

- **Salir y bloquear nunca fallan por un Pomodoro.** Cada persona guarda cuándo entró (`salas_estudio_miembros.entro_en`,
  V1067) y `StudyRoom.creditsDue` cuenta también a quien salió **después** del final de la ronda. Así salir y
  `FriendshipEnded` ya no apuntan nada en ese momento: lo hace el programador al minuto (idempotente con
  `rondas_contadas`). Volver a entrar sí cuenta antes lo pendiente, porque entrar cambia la hora de entrada.
- **Barra y aviso de la sala** (`StudyRoomBarBloc`, una sola instancia, y `StudyRoomBar` sobre la navegación, con la
  misma franja que el Pomodoro: `AppTimerStrip`). La alimenta la pantalla de la sala; al llegar a cero pide la sala una
  vez (no deduce la fase siguiente). El aviso del móvil al acabar cada fase va en su propio hueco
  (`TimerAlertSlot.studyRoom`), así no pisa el del Pomodoro, y llega con la app en segundo plano o cerrada. Sin sala, o
  al salir, dejar la sala o cerrar sesión, la barra y el aviso desaparecen. Esperando a que alguien la empiece, la
  barra pregunta cada 12 s, como la pantalla. El aviso del descanso no dice el número de la ronda siguiente («Fin del
  descanso: vuelve a concentrarte»): no se deduce en el cliente.
- **Excepción al perfil (como el `PomodoroBloc`, ADR 0025):** `StudyRoomBarBloc` se registra con
  `registerLazySingleton` y no como `factory`, porque la barra y el aviso tienen que seguir al salir de la pantalla.

### Otros arreglos de la revisión en pantalla

- Inicio no repite «¿Qué tal estás hoy?»: si la tarjeta del próximo entreno ya lo ofrece, el aviso de arriba no sale.

### Revisión de arquitectura y diseño

- `BadgeService` exige `PeekStreakUseCase` (sin rama de reserva sin pausas) y el plan de avisos lee la racha con él (una
  lectura no guarda). El margen de recuento sirve a los retos completados; uno vencido sin completar no se recuenta.
- `AppTimerStrip` usa `AppCardTapArea`: un solo nodo de botón con nombre y toque para el lector; con texto grande, la
  fase en dos líneas. La hoja de filtros anuncia el recuento (región viva) y, sin resultados, ofrece «Quitar filtros»
  en vez de un botón sin verbo.
- Pequeñas: iconos de `AppIcons` en «Ir a…», la hoja de compartir con cabecera para el lector y el foco al ⋮ tomado
  del nodo interno del botón.

### Pendiente (externo)

- Regenerar `docs/03-api/openapi.yaml` (lo hace el propietario): endpoint nuevo `GET /training/history/{sessionId}`.

