# ADR 0042 — Fase A del plan premium: tarjetas de sesión con foto, «Hoy toca», pausar racha y repasos sin picos

- **Estado:** aceptado
- **Fecha:** 2026-11-15

## Contexto

Primera fase («al grano») del plan premium y social aprobado por el propietario. Cuatro piezas pequeñas de mucho valor, que se apoyan en lo que ya existía:

1. Las tarjetas de sesión (historial, sesión abierta, próximo entreno y detalle) eran texto sobre fondo liso: monótonas y difíciles de distinguir de un vistazo. Las rutinas ya tenían foto (`AppCoverCard`, lado final).
2. La adaptación de hoy (`GET /training/adaptation/today`) solo se veía en Gimnasio, en la tarjeta del registro rápido. Inicio no decía cómo tocaba entrenar.
3. La racha tenía «días libres» automáticos (ADR 0023) y un modo exámenes que solo filtra avisos. No había forma de pausarla a propósito (exámenes, una gripe, un viaje).
4. SM-2 programa cada repaso en `hoy + intervalo` sin mirar los demás: los materiales creados el mismo día vencen juntos y aparecen días con diez repasos.

## Decisión

### 1. Tarjetas de sesión con foto (texto abajo)

- **Se reutiliza `AppCoverCard`** con una variante nueva, `AppCoverLayout.bottom`: la foto ocupa la cabecera, con una franja a la vista arriba (`TokensSize.coverBanner`) y el texto abajo a la izquierda sobre un **degradado vertical de tres paradas** hacia la superficie (0 → `coverScrimMid` en `coverBannerFadeMid` → `coverScrimMax`).
- **La foto va a dos tonos** (la misma matriz que ya usaba `AppCoverCard` con texto grande): sus píxeles quedan entre la superficie y `coverTint`, así que el texto cumple AA en **cualquier** punto del degradado, también en la peor zona (sin velo). Es una imagen calmada, del color de la marca, y funciona igual en claro y oscuro. `contrast_test` mide el caso en las tres paradas (texto 4,5:1, iconos 3:1).
- **Imagen:** la elige el servidor (`SessionLabel.withCover`): la del primer ejercicio del día que tenga imagen (como el próximo entreno, `RoutineDay.coverExercise`, pero saltando los que no tienen foto) o, en una sesión libre o un día sin foto, la del primer ejercicio apuntado. Sin foto, el color de reserva (degradado del mismo tono). El detalle usa la del historial o, si se abrió sin él, la del primer ejercicio de la rutina.
- **Contenido:** estado en pastilla sólida (`AppCoverPill`: «En curso», «Sin terminar», «Hecho», «Próximo entreno», «Con retraso», récords) y **tres datos como mucho** (historial: fecha, duración y esfuerzo; próximo entreno: qué día, cuándo y duración; la semana del plan y la sesión de la semana bajan al pie). La rutina y los ejercicios del próximo entreno de Gimnasio bajan al pie.
- Debajo de la foto va siempre el color de reserva: mientras carga o si falla, la franja no queda vacía.
- Iconos con un significado (`AppIcons`): «En curso» `inProgress`, «Con retraso» `overdue` (no el reloj de la duración), «Hecho» `done`, «En pausa» `paused`.
- **Toque:** la tarjeta del historial es tocable entera (abre el detalle). Las que llevan botones propios (sesión abierta y próximo entreno) **no**: no se anidan controles (regla que ya seguía Gimnasio); sus acciones están en el pie, a todo el ancho.

### 2. «Hoy toca: suave / normal / fuerte»

- **Regla en el dominio** (`TodayIntensity.of`, expuesta como `GetTodayAdaptationUseCase.Result.intensity()`): suave si la adaptación de hoy recorta por cualquier motivo; fuerte si no hay motivo y el registro de hoy dice que estás bien (`DailyCheckIn.feelsStrong`: sueño y energía 4-5, agujetas 1-2, sin dolores y con ganas); normal lo demás. Sin registro nunca es «fuerte».
- **Solo con entreno por hacer hoy** (`Dashboard.trainsToday`: el próximo día de la rutina toca hoy o va con retraso, o hay un evento de deporte sin marcar). Lo decide el servidor y llega en `GET /dashboard` (`todayIntensity`, nulo si no toca); así Inicio no hace otra llamada ni replica la regla. También va en `GET /training/adaptation/today` (`intensity`).
- **En el cliente:** una línea dentro de «Tu día» con su porqué en el «?» (`AppHelpToggle`). Sin cifras ni jerga (nada de ACWR).

### 3. Pausar racha

- **Sin motivo (decisión del propietario):** «Pausar racha» no pregunta ni guarda por qué. Así no se guarda ningún dato de salud (una «enfermedad» lo sería), no hace falta consentimiento aparte ni subir la versión de la política, y pausar es un solo toque.
- **Nueva tabla `pausas_racha`** (V1059, módulo de gamificación; solo fechas) y regla en `StreakPause`: empieza hoy, dura como mucho **7 días seguidos** y no se pueden pausar más de **14 días en los últimos 90** (ventana móvil). Un día en pausa sin actividad es neutro (ni suma, ni corta, ni gasta un día libre); con actividad cuenta. En pausa la racha no está «en peligro», así que tampoco llega ese aviso.
- Una pausa por persona y día de inicio (índice único `usuario_id, desde`): dos toques a la vez no crean dos pausas. Sin racha, pausar no hace nada. «Hoy» es el del móvil: el cliente manda `zone` al leer, pausar y reanudar.
- **El aviso «racha en peligro» no se programa en pausa** (`WellbeingReminders.Input.streakPaused`).
- **Se construye sobre los días libres** (`StreakFreezes.run` recibe los días en pausa) en vez de un sistema aparte. El modo exámenes automático sigue siendo solo de avisos.
- **API:** `POST /streak/pause` (sin cuerpo; idempotente si ya hay pausa) y `DELETE /streak/pause` («Reanudar», la pausa acaba ayer; si empezó hoy se borra). `StreakResponse` añade `pausedUntil`, `pauseDaysLeft` y `canPause`. Sin días: `STREAK_PAUSE_LIMIT_REACHED` (422).
- **En el cliente:** en el titular de Progreso, junto a la racha, «Pausar racha» pausa en **un toque**, sin hoja ni diálogo: aviso «Racha en pausa hasta el …» con «Deshacer»; en pausa, la llama se apaga, una pastilla dice «En pausa» y la línea dice hasta cuándo con «Reanudar».
- **Privacidad:** las pausas son datos de la racha (gamificación), ya cubiertos por «rachas» en la política de privacidad: no se añade ninguna línea ni cambia `LegalTerms.CURRENT_VERSION`. Salen en la exportación de la persona con el resto de la gamificación y se borran al vaciar o anonimizar la cuenta.

### 4. Repasos sin picos

- `ReviewLoadBalancer` reparte la fecha que propone SM-2: intervalo 1 → no se mueve; 2 → solo puede retrasarse 1 día; 3-13 → ±1; ≥ 14 → ±2. Se elige el día con menos repasos programados; solo se mueve si otro tiene estrictamente menos; con empate, el más cercano y luego el anterior. El intervalo SM-2 guardado no cambia. Fórmula en `formulas.md` («Repasos sin picos»).
- El puerto `StudyMaterialRepositoryPort.scheduledReviews` lee solo id y fecha de los repasos de la ventana. La vista previa enseña la misma fecha que dará el repaso.

## Consecuencias

- API: campos nuevos en `DashboardResponse`, `TodayAdaptationResponse`, `StreakResponse`, `SessionHistoryResponse` y `OpenSessionResponse`; dos endpoints nuevos de racha. Hay que regenerar `openapi.yaml`.
- `DataChangeInterceptor`: `/api/v1/streak` avisa a gamificación (Progreso) y social (reprograma los avisos: el de racha en peligro no llega en pausa).
- Las tarjetas de rutina siguen con la foto al lado (`AppCoverLayout.side`): la foto a color y el texto en zona lisa siguen siendo lo mejor para un listado de rutinas.
