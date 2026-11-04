# 0013. Recordatorios locales en el móvil en lugar de notificaciones push

* **Estado:** Aprobado (revisado: el plan de avisos lo decide el servidor)
* **Fecha:** 2026-10-21
* **Autores:** Equipo SynaptixFit

## Contexto
Las notificaciones solo existían dentro de la app (las crea el backend y se leen en la bandeja). Queríamos que el teléfono avisara de dos cosas: los repasos espaciados (SM-2) vencidos y la hora de empezar los bloques planificados de deporte y estudio. Las dos se conocen de antemano, así que no hace falta que el servidor las empuje. Las notificaciones push (Firebase Cloud Messaging) exigirían otro servicio externo, credenciales, registrar tokens de dispositivo en el backend y un planificador en el servidor.

La primera versión decidía en el cliente qué avisar (`ReminderPlanner` de Flutter replicaba `NotificationPreferences.evaluate` y `NotificationMode`). Eso rompía la regla 6 del proyecto (las reglas de negocio viven en el backend) y ya divergía del servidor. Se sustituyó por un plan que decide el servidor.

## Decisión
- Avisos **locales** con `flutter_local_notifications` en Android e iOS. En web y escritorio el adaptador no hace nada (`NoopReminderScheduler`) y el interruptor no se muestra.
- **El servidor decide qué y cuándo avisar.** `GET /api/v1/notifications/reminder-plan?days=7` (1..7) devuelve `{ reminders: [{ kind, at, refId, count?, title?, startsAt? }] }`, ordenado por hora, con `kind` = `REVIEWS` | `TRAINING` | `STUDY` | `EXAM` | `DEADLINE` | `WEEKLY_SUMMARY` | `ROUTINE_DAY_MISSED` | `OPEN_SESSION` | `CHALLENGE_DUE` (avisos de seguimiento, 2026-11-01: «tocaba ayer», «¿terminaste la sesión?» y «tu reto vence mañana»; ver `ReminderPlanner`). El `payload` de cada notificación es «tipo|referencia» para abrir el bloque, la sesión o el reto al tocarla. En `EXAM` y `DEADLINE`, `count` son los días que faltan (contados desde el aviso) y `startsAt` la fecha de la entrega; las entregas se leen con `DeadlineRepositoryPort.findAll(pendingOnly=true)`. En el móvil, «Tu semana» usa el id 90 y cada aviso de entrega el hash de `"<id>:<días antes>"`. Lo calcula `ReminderPlanner` (dominio del backend, puro) desde `GetReminderPlanUseCase` (`ReminderPlanService`), que lee las preferencias de notificación, el enfoque de uso (`UsageFocusPort`), los repasos vencidos (`StudyMaterialRepositoryPort.findDue`, hasta 100) y los bloques de la ventana (`CalendarBlockRepositoryPort.findOverlapping` y los nombres de asignatura con `SubjectDirectoryPort`).
- Reglas del plan (en `ReminderPlanner`, reutilizando las del dominio):
  - Repasos: a las 19:00 de los tres próximos días si hay vencidos (hoy solo si aún no han pasado).
  - Entregas y exámenes pendientes (añadido el 2026-10-25): a las 18:00 de tres días antes y del día antes. Al principio
    se dejaron fuera; sin ellos la app no avisaba de lo más importante de un estudiante.
  - «Tu semana» (añadido el 2026-10-25): el domingo a las 20:00, abre Progreso para repasar la semana y planificar la siguiente.
  - El permiso se ofrece una vez, la primera vez que se guarda algo de estudio o del planificador en el móvil
    (`ShouldOfferRemindersUseCase`), además del interruptor de Ajustes.
  - Bloques de deporte, estudio y repaso: 15 minutos antes; se descartan los completados, los ya empezados y el resto de tipos (clases, exámenes, entregas…).
  - Categoría y modo con `NotificationPreferences.admits` (`NotificationMode.allows`). Repasos y estudio usan `ACADEMIC`; «hora de entrenar», `MILESTONE`, porque no hay categoría de deporte. Enfoque con `ActivityType.visibleFor` (los repasos cuentan como `REVIEW`).
  - Horas de silencio con `NotificationPreferences.afterQuietHours`: diferencia deliberada con las notificaciones de la app (que se descartan porque ya han ocurrido): un recordatorio sigue siendo útil al terminar el silencio, así que se retrasa, y el de un bloque se descarta si llegaría a la hora de empezar o después.
  - Límite diario por día local, por orden de hora. Con límite 0 el servidor solo entrega las notificaciones importantes (`CRITICAL`); un recordatorio nunca lo es, así que no hay avisos.
  - Tope de 60 avisos (iOS solo guarda 64 pendientes por app).
  - El día local y las horas de silencio usan la zona `synaptixfit.notifications.zone` (por defecto Europe/Madrid), la misma que el centro de notificaciones.
- **El cliente solo pone textos y programa.** `SyncRemindersUseCase` pide el plan (`ReminderPlanRepositoryContract`), `ReminderComposer` le pone los textos traducidos (`ReminderTexts`) y un id estable (hash del id del bloque; 100+n para los repasos) y `ReminderSchedulerRepositoryContract.replaceAll` los programa. Si el plan falla, no se toca lo ya programado.
- Programación inexacta (`AndroidScheduleMode.inexactAllowWhileIdle`): puede llegar unos minutos tarde, pero no pide el permiso de alarmas exactas. Los instantes se programan en UTC (son absolutos), sin depender de la zona horaria del teléfono.
- Es una preferencia **del dispositivo**, no de la cuenta: se activa en Perfil → Ajustes → Notificaciones («Recordatorios · En este móvil», se aplica al momento) y entonces se pide el permiso del sistema. Se guarda con `shared_preferences`. Si el sistema niega o retira el permiso, la pantalla lo muestra en una fila fija con «Volver a pedir».
- El armazón de pestañas (`RemindersHost` dentro de `AchievementsHost`) sincroniza al entrar, cuando cambian planificador, estudio, entrenamiento, las preferencias (bus de cambios, ADR 0010) o el enfoque de la cuenta, y al activar el interruptor; borra los avisos al cerrar sesión.
- **Botones «Empezar» / «Posponer 10 min» (Android, 2026-11):** «Posponer» vuelve a programar el aviso sin abrir la app (`reminderBackgroundTap`, en un isolate aparte, con los textos dentro del `payload`). El aviso pospuesto guarda en su `payload` la hora a la que sonará, y `replaceAll` no lo borra mientras esa hora no llegue: abrir la app en esos minutos no lo pierde. Posponer **no** respeta el silencio ni el límite diario del servidor: lo pide la persona en ese momento, así que suena a los 10 minutos aunque sean las 23:05. En iOS los avisos van sin botones (necesitarían categorías registradas al iniciar).
- **Abrir lo concreto:** cada aviso lleva `payload` «tipo|referencia». En las entregas, el servidor manda el id que se abre en `targetId` (su `refId` lleva además los días de antelación).

## Consecuencias
* **Positivas:** sin servicios ni credenciales nuevos; una sola regla de entrega (en el backend) para la bandeja y para el móvil; funciona sin conexión una vez programado; los textos salen de las traducciones del cliente.
* **Negativas:** sincronizar necesita conexión (sin red se conservan los avisos ya programados); los avisos solo se actualizan cuando se abre la app en ese teléfono (un cambio hecho en la web no reprograma el móvil hasta abrirlo); el día local es el de la zona del servidor, no el del teléfono; el límite diario de los recordatorios no se suma a las notificaciones de la app; en web no hay avisos.
