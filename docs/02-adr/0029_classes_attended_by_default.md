# 0029. Clases dadas por asistidas al terminar, con «No fui»

* **Estado:** Aprobado
* **Fecha:** 2026-11-01
* **Autores:** SynaptixFit

## Contexto
Una clase solo contaba (XP, carga cognitiva, semana, asistencia) si se marcaba a mano. Casi siempre vienen del
horario importado y pocas personas las marcan, así que el día parecía incompleto aunque se hubiera ido a todas y la
carga cognitiva se quedaba corta. Lo habitual es ir a clase: lo que hay que apuntar es la excepción.

## Decisión
* **Estado materializado, no derivado.** Completar un bloque ya hace mucho más que cambiar un indicador: concede
  XP con el tope diario, guarda la carga cognitiva y el gasto, recalcula la semana y publica
  `StudyBlockCompletionChanged` (insignias, retos, analítica). Si la asistencia fuera solo un estado calculado al
  leer, cada lector tendría que reinterpretarla y la XP no existiría. Por eso la clase **se completa de verdad**
  con el mismo `BlockCompletionService` que al marcarla a mano.
* **Tarea programada.** `ClassAttendanceScheduler` (adaptador de entrada, cada 10 min,
  `synaptixfit.planner.auto-attend-cron` / `CLASS_AUTO_ATTEND_CRON`) busca con `AttendEndedClassesUseCase` las
  clases que terminaron en las últimas 24 h (`CalendarBlock.AUTO_ATTEND_WINDOW`), sin completar y sin ausencia, y
  completa cada una con `AttendClassUseCase` **en su propia transacción** (un fallo se registra y no frena a las
  demás). Es idempotente. Marcar a mano y la tarea leen el bloque bloqueando su fila (`findByIdForUpdate`), así
  un «No fui» simultáneo no se pisa ni se da la XP dos veces. Las de más de 24 h no se tocan, para no dar de golpe XP de clases antiguas al desplegar o tras una
  parada larga.
* **«No fui» = desmarcar una clase.** Sin endpoint nuevo: `PATCH .../completion` con `completed=false` en una clase
  la desmarca (resta su XP) y guarda la ausencia (`horarios_academicos.ausente`, V1030); también antes de que se
  complete sola. Volver a marcarla la borra. La respuesta del bloque lleva `absent`. **Excepción aceptada:** es una
  acción distinta dentro de `SetBlockCompletionUseCase` para que los APK anteriores, que ya desmarcaban, sigan
  valiendo; desmarcar por error una clase también deja la ausencia (se corrige con «Sí fui»).

## Consecuencias
* Entre el fin de la clase y la siguiente pasada (≤ 10 min) la clase sigue «no hecha»; el aviso de bloques sin
  hacer ya excluía las clases.
* Los APK anteriores siguen funcionando: desmarcar una clase ya era posible y ahora además deja la ausencia; no
  muestran `absent`.
* Migración V1030 (columna `ausente` e índice parcial para la búsqueda periódica). Ver `data_model.md`.
