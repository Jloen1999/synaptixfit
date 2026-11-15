# ADR 0047 — «Juntos» a la vez: canal en directo (SSE), entrenar juntos sincronizado y cierre de la flecha «Volver»

- **Fecha:** 2026-11-15
- **Estado:** aceptado

## Contexto

Fase C3 del plan premium. «Estudiar juntos» ya iba a la vez en el servidor (ADR 0045), pero cada móvil se enteraba
consultando cada 12 s, y «Entrenamos juntos» (ADR 0044) era asíncrono: cada persona empezaba su sesión cuando quería.
El propietario pidió: «Debe ser síncrono el estudiar o entrenar juntos: si uno empieza, inmediatamente debe empezar
en el otro, y todo lo que conlleva». Sus decisiones:

1. Entrenar juntos: **empezar y pausar** van a la vez para todos; las series, los pesos y «Terminar» son de cada uno.
2. Con la app abierta, el cambio llega **en directo por SSE** (Server-Sent Events). Sin WebSocket y sin servicios
   externos.
3. Con la app cerrada, **sin push**: al abrir la app, va directo a la sesión o sala en marcha.
4. «Empezar» lo puede pulsar **cualquiera que esté dentro**, como en la sala.

También quedaban pendientes de la flecha «Volver» (ADR 0046).

## Decisión

### 1. Canal en directo: `GET /api/v1/together/stream` (SSE)

- **Solo avisos sin datos:** `event: change`, `data: {"type":"studyRoom|workout|together","id":"…"}`. El móvil vuelve
  a leer por la API de siempre, con sus permisos de siempre: el canal no puede filtrar nada que la API no deje ver.
  Al abrirse manda `event: ready`.
- **Dominio sin SSE:** los servicios llaman al puerto `TogetherLivePort` (a través de `TogetherNotifier`) con un
  `TogetherLiveChange` (destinatarios, tema e id). `SpringTogetherLiveAdapter` lo deja en el bus de Spring y
  `TogetherLiveListener` lo manda con `@TransactionalEventListener(AFTER_COMMIT)`: un cambio deshecho nunca se
  anuncia y quien recibe el aviso ya ve el cambio al leer.
- **Destinatarios:** las personas invitadas o dentro y quien actuó (sus otros dispositivos). Nadie de fuera.
- **Qué se avisa:** sala — crear (a los invitados), entrar, decir que no, salir, empezar, reaccionar y salir por
  `FriendshipEnded`; el cambio de fase no, porque lo calcula cada móvil con la hora del servidor. Entreno juntos —
  crear, unirse, decir que no, salir, empezar, pausar, reanudar, apuntar o quitar una serie y terminar.
- **Registro en memoria** (`TogetherStreamHub`): vale porque el backend corre en **una sola instancia**. Con
  varias réplicas haría falta un bus común (anotado en `REQUISITOS-INFRA.md`). Como mucho **3 conexiones por
  persona** (se cierra la más antigua), **latido cada 25 s** (comentario SSE, `TogetherStreamHeartbeat`; por debajo
  de los 60-100 s sin tráfico de nginx y Cloudflare, y descubre conexiones rotas) y **15 min por conexión**
  (`SseEmitter` con su propio límite, así no depende de `spring.mvc.async.request-timeout`): el móvil abre otra y
  vuelve a pasar por la autenticación con su token vigente.
- **Seguridad:** la petición se autoriza al abrirse con el JWT de siempre (`@CurrentUserId`); el final asíncrono
  de la respuesta (`DispatcherType.ASYNC`) no se vuelve a comprobar, porque no lleva contexto de seguridad y
  Spring Security intentaría escribir un 401 sobre una respuesta ya enviada. CORS no cambia (la web va por el mismo
  origen; en desarrollo ya se permiten todas las cabeceras).
- **nginx:** bloque propio con `proxy_buffering off`, `proxy_cache off`, `gzip off` y `proxy_read_timeout 120s`; el
  backend además responde `X-Accel-Buffering: no` y `Cache-Control: no-store`. Los límites de peticiones que ya
  había (`limit_req`) no cubren esta ruta.

### 2. Entrenar juntos a la vez

- **Migración V1068:** `entrenos_juntos.empezado_en`/`empezado_por` (hora de inicio común y quién pulsó «Empezar»,
  para el aviso «Ana ha empezado») y `pausado_en`/`pausado_por` (pausa del grupo en curso).
- **`POST /together/workouts/{id}/start`** (mismo endpoint y misma respuesta, `{sessionId}` de quien lo pulsa):
  lo puede pulsar cualquiera de dentro (una persona invitada entra al pulsarlo). La primera vez empieza para todo el
  grupo: en la **misma transacción**, la sesión normal de cada persona de dentro (con su copia de la rutina, como
  hasta ahora) y la **misma hora de inicio** (`StartTrainingSessionUseCase.start(..., startedAt)`). Una sola vez:
  el entreno se lee con `FOR UPDATE` y el dominio comprueba que no había empezado (`WorkoutTogether.start`).
  Después, «Empezar» retoma la sesión de quien lo pulsa.
- **Quien acepta después de empezar** entra con su sesión desde ese momento (no a la hora común) y, si el grupo está
  en pausa, en pausa.
- **Pausar o reanudar** cualquier sesión de un entreno juntos de hoy pausa o reanuda **la de todos**: el servicio de
  sesiones publica `TrainingSessionPauseChanged` (solo si cambia) y `WorkoutTogetherSessionListener` llama a
  `PauseWorkoutTogetherUseCase`/`ResumeWorkoutTogetherUseCase`, que guardan la pausa del grupo y pausan o reanudan
  las demás sesiones **con los casos de uso de siempre** (ADR 0030, idempotentes); la reanudación usa la misma hora
  para todos (la del toque, acotada). El rebote de cada sesión vuelve al oyente y no hace nada (el grupo ya consta
  en pausa). El evento se publica **antes de guardar** la sesión: así el entreno se bloquea siempre antes que las
  sesiones y dos personas que pausan a la vez se esperan en el mismo orden en vez de bloquearse entre sí.
- **Sin escrituras que se pisen:** ahora la transacción de una persona escribe la sesión de otra. `sesiones_registradas`
  lleva versión (bloqueo optimista, **V1069**): si dos transacciones cambian la misma sesión a la vez, la segunda
  falla al guardar y `TransactionalUseCaseFactory` repite el caso de uso entero (hasta 2 veces, solo la transacción
  de fuera), que vuelve a leer lo ya confirmado. No hace falta código de error nuevo: si aun así no sale, responde el
  `CONFLICT` de siempre. Sin versión, una persona que terminaba su sesión mientras otra pausaba al grupo podía perder
  la sesión terminada.
- **La pausa la puede poner cualquiera de dentro.** Esto incluye «Pausar y salir» de la sesión en vivo: pausa a
  todos. «Terminar» es de cada uno y no termina la de los demás; una sesión terminada no se pausa.
- **Quien tiene otra sesión abierta:** se le crea igualmente la del grupo y las otras sesiones abiertas que tuviera
  (no abandonadas) **se ponen en pausa**: no se terminan ni se descartan, así no cuentan como entrenadas mientras
  entrena con el grupo y decide él después. Una sesión de **otro** entreno juntos no se pausa (pausaría a todo ese
  otro grupo). Si ya tenía una sesión abierta del **mismo día** de la rutina, se usa esa
  (con su hora). A quien tiene una sesión **abandonada** (más de 6 h) de ese día no se le crea la del grupo (habría
  que preguntarle si terminarla o descartarla): entra después con «Ir», que le muestra esa pregunta de siempre; si es
  quien pulsa «Empezar», ve el aviso de siempre («Termínala o descártala»; se hace en Entreno) y no empieza nadie.
- **Invitado que pulsa «Empezar»:** entra con la misma regla que «Unirme» (seguir siendo amigo de quien invita y sin
  bloqueos con nadie de dentro); si no, `WORKOUT_TOGETHER_NOT_FOUND`.
- Sin códigos de error nuevos: lo que no vale responde `TOGETHER_INVALID_STATE` o `WORKOUT_TOGETHER_NOT_FOUND`,
  como antes.

### 3. Cliente

- `TogetherLiveHost` (en `AchievementsHost`, `TogetherLiveBloc`): abre el canal con la app en primer plano, lo
  cierra en segundo plano y al cerrar sesión (se desmonta el armazón) y reconecta con **espera creciente** (2 s, 4 s…
  hasta 1 min). Tras reconectar, las pantallas abiertas leen otra vez una vez (pudo perderse algún aviso).
- Cada aviso se publica como **cambio de datos** (`PublishDataChangesUseCase` → `DataTopic.studyRoom`,
  `workoutTogether` y `social`) y `StudyRoomBloc`, `StudyRoomBarBloc`, `WorkoutTogetherBloc`,
  `WorkoutTogetherLiveBloc` y `TogetherBloc` se refrescan con `DataChangeRefreshMixin`, como el resto de la app.
- La **consulta periódica** de siempre queda **de respaldo**: con el canal conectado se salta si se leyó hace menos de
  un minuto (`LivePollMixin`); si el canal cae, vuelve a sus 12 s.
- **Web:** Dio usa XMLHttpRequest y no entrega la respuesta a trozos. Se usa `fetch` con `ReadableStream` a través de
  `package:web` (ya estaba en el proyecto como dependencia de otros paquetes; se declara 1.1.1, que tiene más de dos
  semanas). Se descartó `EventSource`, que no deja mandar la cabecera `Authorization` (el token iría en la
  dirección), y añadir `fetch_client`, que suma una dependencia para lo mismo. Si el token caduca, el canal falla y
  reintenta; la renovación la hace la siguiente llamada normal de la app.
- La lectura de mensajes (`sseTransformer`, el repositorio y el `fetch` de la web) **no usa `async*` con
  `await for`**: cancelar no surte efecto hasta el siguiente mensaje y la conexión seguiría abierta al pasar a segundo
  plano. El transporte de Dio sí es un `async*`, pero con `yield*`, que corta al momento (si se cancela mientras se
  abre, la conexión se abre y se cierra enseguida).
- Los avisos de sala y entreno publican solo sus temas en directo (`studyRoom`, `workoutTogether`); `social` queda
  para las invitaciones y la reconexión, así una serie de un amigo no reprograma los recordatorios ni recarga
  Progreso en todo el grupo.
- **Pantalla de espera** (`WorkoutTogetherPage`): quién está dentro y un único «Empezar» (acción principal) con la
  línea «Cuando alguien empiece, empezáis todos a la vez». Si empieza otra persona con la pantalla abierta,
  se entra sola en la sesión en vivo de siempre (una vez; se anuncia al lector).
- **En otra parte de la app:** aviso «Ana ha empezado a entrenar · Entrar» (`showActionSnack`) y la barra de sesión abierta (se
  publica `DataTopic.training`). No sale si ya se está en esa sesión o en su pantalla de espera, ni si empezó uno
  mismo. El aviso se pone en cola (`showActionSnack(replaceCurrent: false)`): nunca tapa un «Deshacer» abierto, que se
  confirmaría sin que la persona lo decidiera.
- **Pausa común en la sesión en vivo:** el estado de pausa viene del servidor. `WorkoutTogetherLiveScope` detecta el
  cambio de pausa del grupo y la sesión lee su estado (`LiveSessionEvent.groupPauseChanged`) y lo adopta sin volver
  a mandarlo; el cronómetro de la serie se congela o sigue como con la pausa propia y el borrador sin conexión
  (`LiveSessionDraft`) se guarda igual. Mientras una pausa o reanudación propia va camino del servidor, o con una
  reanudación sin llegar (sin conexión), manda lo del teléfono. Se pinta «En pausa · la ha puesto Ana», «Reanudar» pasa a «Reanudar para todos» y la sesión anuncia al lector, una
  vez y solo cuando ya la ha adoptado, «Ana ha puesto la pausa» o que se ha quitado.
- **Al abrir la app:** al entrar en el armazón, si hay un entreno juntos de hoy empezado en el que estoy y no he
  terminado, se abre mi sesión; si no, una sala en concentración o descanso con la persona dentro. Una vez por
  apertura y solo si se entró por Inicio sin nada encima: un aviso del móvil o un enlace de rutina pendiente que abrió
  la app mandan.

### 4. Cierre de la flecha «Volver» (pendientes del ADR 0046)

- **«Atrás» del sistema (Android) sin pila:** `AppBackButton` registra un `BackButtonListener` que hace lo mismo que
  la flecha (`backOr(fallback)`), solo en la pantalla visible (`TickerMode`; las pestañas que go_router mantiene
  montadas detrás no responden). Con pila, vuelve a la de debajo como siempre (respeta `PopScope`). Probado en
  `back_button_routes_test.dart` con `handlePopRoute`. Solo responde la pantalla de arriba del navegador principal:
  con un diálogo o una hoja encima, o dentro de una pestaña, se deja el «atrás» de siempre (cierra lo de arriba).
- **Detalle de sesión sin pila:** «Corregir», «Reabrir y seguir» y «Eliminar» se ven siempre y los hace
  `SessionDetailBloc` con sus casos de uso (antes los hacía el historial al volver). Reabrir entra en la sesión
  (con historial debajo, cierra el detalle y abre la sesión encima; sin pila, la sesión ocupa su lugar); eliminar
  vuelve al historial con `popOrGo`. El historial lee otra vez al volver del detalle.
- **«Deshacer» al salir** de la sala, de entrenar juntos y de un reto con amigos: al cerrarse el aviso se sale con
  `context.leaveAfterUndo(padre)` (como `popOrGo`, también sin pila), solo si la pantalla sigue arriba; el `onCommit`
  diferido (`DeferredCommitMixin`) no cambia.
- `trainingBackToRoutines` dice «Volver a Entreno» (y «Back to Training», «Retour à Sport», «Voltar a Treino»).

## Consecuencias

- **Positivas:** empezar y pausar llegan al momento a todo el grupo; la consulta periódica queda de respaldo y,
  con el canal conectado, el servidor recibe muchas menos lecturas. El dominio no sabe nada de SSE y el canal no
  puede filtrar datos. Ninguna pantalla se queda sin salida tampoco con el «atrás» del sistema.
- **Negativas:** una sola instancia del backend (registro en memoria). Con la app cerrada no llega nada hasta abrirla.
  Pausar sale de la sesión de cada uno: «Pausar y salir» pausa a todos. Cada serie de un amigo hace una lectura del
  entreno en cada móvil con la sesión abierta (una consulta pequeña). En la web, un token caducado deja el canal
  cortado hasta la siguiente llamada normal (la espera máxima entre intentos es 1 min).
- Salir de un entreno por `FriendshipEnded` (bloquear o dejar de ser amigos) no se avisa en directo: los demás lo
  ven en la siguiente lectura. Si quien sale había puesto la pausa, el grupo sigue en pausa hasta que alguien de
  dentro la quite.
- Los avisos se escriben en la conexión de cada destinatario en el hilo de quien actuó (tras el commit); con hilos
  virtuales y pocas personas por grupo no se nota. Si creciera, se mandarían desde un ejecutor aparte.
- **Migraciones:** V1068 y V1069. **Endpoints:** nuevo `GET /api/v1/together/stream`; `POST /together/workouts/{id}/start`
  cambia de efecto (empieza para todos) pero no de forma; `WorkoutTogetherResponse` añade `startedAt`, `startedBy`,
  `pausedAt` y `pausedBy`. **Eventos nuevos:** `TrainingSessionPauseChanged`, `TrainingSessionProgressed`.
- **Pendiente (externo):** regenerar `docs/03-api/openapi.yaml` (lo hace el propietario).
