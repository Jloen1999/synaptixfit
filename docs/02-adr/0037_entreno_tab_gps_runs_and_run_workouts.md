# ADR 0037 — Pestaña Entreno con «Correr»: carreras con GPS y entrenos de carrera

- **Estado:** aceptado
- **Fecha:** 2026-11-07

## Contexto

1. Correr solo se podía apuntar a mano después (ADR 0033): sin GPS, sin mapa, sin ritmo por kilómetro ni guía mientras se corre.
2. La pestaña se llamaba «Rutinas» aunque el entreno ya no es solo de gimnasio, y habrá más disciplinas (CrossFit).
3. Varias explicaciones no se entendían («progresión», «RPE», «volumen») y algunos avisos decían «se puede recuperar» sin decir dónde.
4. La explicación del cronómetro volvía a salir tras «Pausar y salir» aunque se hubiera marcado «No volver a explicarlo».

## Decisión

### Una carrera es una actividad

- Se graba en el móvil y se sube la **ruta cruda**: `POST /training/runs` con `clientKey` (UUID del móvil), clase (`RUN`, `WALK`, `BIKE`), inicio, esfuerzo («¿Cuánto te ha costado?», 1-10) y puntos compactos `[lat, lon, altitud, precisión, segundos, segmento]`.
- El servidor lo calcula todo (`RunTrack`, `RunEnergy`, formulas.md): filtrado, distancia haversine, tiempo en movimiento, ritmo, tramos por km, desnivel con suavizado e histéresis y kcal por MET. El cliente solo enseña cifras orientativas mientras graba.
- Se apunta con el mismo caso de uso que las actividades a mano (`LogPastActivityUseCase`, origen `GPS` en `actividades_apuntadas.origen`), con los minutos **en movimiento**. Así cuenta igual en racha, XP, carga física (esfuerzo × minutos → ACWR), retos ligados, resumen semanal, «Actividades y partidos» y Progreso. La ruta y las cifras van en `carreras_gps`, ligadas al bloque en cascada.
- **Idempotente:** `UNIQUE (usuario_id, clave_cliente)`. Reintentar desde la cola devuelve la carrera ya guardada con `xpDelta = 0`.
- **Reglas revisadas de las actividades:**
  - Mínimo de 10 minutos (en movimiento): se mantiene. Con menos, `RUN_TOO_SHORT`; el móvil lo avisa antes de terminar y ofrece seguir o descartar.
  - Hasta **30 días atrás** con GPS (7 a mano): una carrera grabada sin conexión puede subirse días después y no debe perderse; a mano se sigue limitando a 7 porque es más fácil equivocarse de día. El ACWR usa 28 días, así que algo de hace 30 apenas lo mueve. `RUN_OUT_OF_RANGE` si es más antigua o termina en el futuro (2 min de margen de reloj).
  - Máximo 300 minutos en movimiento, como cualquier actividad.
- **Límites:** 20 000 puntos y 2 MB por petición (`RUN_ROUTE_TOO_LARGE`, 413). El detalle devuelve la ruta reducida a 600 puntos.
- Borrar una carrera borra su evento del calendario con `DeleteCalendarBlockUseCase` (resta su XP y su carga); la ruta se va en cascada. En el móvil se hace con «Deshacer»: se borra en el servidor al cerrarse el aviso o al salir de la pantalla.

### Grabar en el móvil

- `geolocator` con su **servicio en primer plano de tipo `location`** (`FOREGROUND_SERVICE_LOCATION`): sigue con la pantalla apagada y enseña el aviso fijo «Grabando tu carrera · 3,2 km · 18:40». El texto se actualiza volviendo a publicar el aviso con el mismo id del servicio (75415) cada 5 s; si falla, queda el texto fijo.
- Permisos: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`. **Nunca** `ACCESS_BACKGROUND_LOCATION`. La ubicación es un `DevicePermission` más (ADR 0034): paso «Permisos», Ajustes › Permisos del móvil y `ensureDevicePermission` justo antes de la primera carrera, con «Abrir ajustes» si está bloqueado y «Apuntar a mano» como alternativa.
- La carrera en curso se guarda en el teléfono cada 5 puntos, al pausar y al pasar a segundo plano (`run_recording`); al terminar pasa a la cola (`run_pending_<clave>`) y se sube al momento o, sin conexión, al volver a Correr. Si la app se cerró grabando, al volver aparece «Tienes una carrera sin terminar» y el hueco cuenta como pausa (otro segmento). Al cerrar sesión se borra todo: lleva ubicación exacta.
- En web y escritorio no se graba: la pantalla lo explica y ofrece apuntar a mano.

### Entrenos de carrera por pasos

- `entrenos_carrera` con grupos de pasos (`WARMUP`, `RUN`, `RECOVER`, `COOLDOWN`; por tiempo o distancia) y repeticiones. Seis plantillas en el servidor (solo código y pasos); el nombre y el porqué los pone el cliente en cada idioma.
- **«Poner en el calendario»** lo hace el servidor con `CreateCalendarBlockUseCase` (contrato del planificador, sin tocar su hoja): evento de tipo Entreno con el nombre del entreno y su duración prevista, ligado en `eventos_entreno_carrera`.
- Al grabarlo desde ese evento (`plannedBlockId`): si ya había empezado, **ese evento queda hecho** como actividad (`CompletePlannedActivityUseCase`, del planificador: completa con el esfuerzo y guarda clase, minutos, distancia y origen en `actividades_apuntadas`, tabla suya) y la carrera se guarda en él; si era más tarde (se corrió antes), el evento se borra y la carrera se apunta en su hora real. El planificador no mueve eventos al pasado y así no quedan dos cosas para lo mismo.
- Mientras se graba, `RunGuide` (cliente) lleva el paso actual, lo que queda y el siguiente; al cambiar vibra y lo anuncia el lector de pantalla.

### Pestaña Entreno

- La pestaña se llama **Entreno** y `/training` tiene apartados con `?section=` (`TrainingSection`: `gym`, `run`): se cambia con `go`, la barra inferior se conserva y los enlaces de siempre (`/training/routines/:id`…) no cambian. Un tercer apartado (CrossFit) es un valor del enum, su texto y su pantalla.
- Correr: mapa con «Estás aquí» (solo si el permiso ya está dado), «Empezar a correr», «Crear entreno», «Esta semana» (distancia, tiempo, desnivel, salidas, mini gráfica y «Compartir»), «Tus actividades (N)» con su origen y «Tus entrenos de carrera». La grabación es de pantalla completa; el detalle y el editor viven dentro de la pestaña.
- Inicio solo suma «Empezar a correr» en las acciones del próximo entreno.

### Mapa

- `flutter_map` con teselas ráster de MapTiler: `MAP_TILES_KEY` y, opcional, `MAP_TILES_URL` (plantilla con `{z}/{x}/{y}` y `{key}`) por `--dart-define`; en el CI web, `vars.MAP_TILES_KEY`. Atribución «© MapTiler © OpenStreetMap». Sin clave, la ruta se dibuja sobre un fondo liso con «Mapa no disponible».
- Compartir manda una imagen **solo con cifras** (la tarjeta de logros), nunca el mapa.
- Excepción a «solo el backend llama a servicios externos» (CLAUDE.md): las teselas del mapa las pide el móvil o el navegador directamente a MapTiler, como cualquier mapa; solo viaja la zona visible, nunca la ruta. La clave es pública y se restringe por dominio y paquete de Android en MapTiler.

### Privacidad

- Rutas siempre privadas. Se borran con la carrera, con la cuenta (cascada) y al vaciarla o anonimizarla (`UserDataErasureJdbcAdapter`). Van en la exportación de la persona (`gpsRuns`) y **no** en la del administrador, como los datos de salud. `LegalTerms.CURRENT_VERSION` pasa a `2026-11-07`: la política añade la ubicación exacta y MapTiler, y hay que aceptarla de nuevo.

### Textos y fallos

- «Siguiente paso: prueba 42,5 kg» y el porqué sin «RPE»; «Semana 2 de 8» con qué toca esa semana; títulos de Progreso sin jerga.
- Saltar un día dice dónde se recupera y lleva el botón («Ver rutina» o «Recuperar» si ya se está en ella); lo mismo en salir de la sesión, actividades y ciclo.
- Fallo 7: la hoja del cronómetro devolvía `null` al cerrarse con «atrás» o deslizándola, y eso perdía la casilla. Ahora la casilla vive fuera de la hoja (`ValueNotifier`) y se lee se cierre como se cierre.

## Consecuencias

- Un APK anterior sigue funcionando: los campos nuevos de «Actividades y partidos» (`source`, `elevationGainMeters`) son opcionales.
- La carga física de una carrera de menos de 30 min queda algo por encima (bloque mínimo del calendario), igual que en las actividades a mano.
- La cola del móvil solo descarta una carrera si el servidor la rechaza por una regla (`RUN_TOO_SHORT`, `RUN_OUT_OF_RANGE`, `RUN_ROUTE_TOO_LARGE` o validación); con cualquier otro fallo se queda para reintentar.
- Pendiente: Strava y Health Connect; en iOS falta el modo de fondo de ubicación (`UIBackgroundModes`) para grabar con la pantalla apagada; un aviso del plan para «el entreno de carrera de hoy» (lo decide `ReminderPlanner`, de Notificaciones).
