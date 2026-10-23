# 0009. Hacer avanzar los retos de fitness con las sesiones de entrenamiento recontadas desde cero

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
Los retos de tipo `FITNESS` no avanzaban al entrenar: Gamificación no escuchaba `TrainingSessionCompletionChanged` y los vínculos de un reto o tarea (`LinkType`) solo apuntan a exámenes, entregas o bloques del calendario. El reto no tenía ningún objetivo numérico con el que medir «cuánto» avanza una sesión, y sumar un incremento por cada evento no es idempotente: un evento repetido, o desmarcar y volver a marcar, deja el progreso desfasado.

Alternativas descartadas:
* **Un vínculo `TRAINING` por tarea** (como los bloques): una tarea necesita una entidad concreta a la que apuntar; una sesión no existe hasta que se entrena y no se puede vincular de antemano.
* **Una tarea por sesión** («la n-ésima sesión completa la n-ésima tarea»): choca con las tareas completadas a mano y con sus dependencias.
* **Progreso manual incremental por evento**: no idempotente y no reversible al desmarcar.

## Decisión
* Un reto `FITNESS` **sin tareas** puede tener un objetivo opcional de sesiones (`retos.sesiones_objetivo`, 1-365; campo `sessionTarget` de la API). Un reto `ACADEMIC` no lo admite (`VALIDATION_ERROR` en `sessionTarget`). Si el reto pasa a tener tareas, el objetivo deja de aplicarse (con tareas, el progreso y el XP son de las tareas).
* El progreso se **recalcula desde cero**: Gamificación cuenta, con `ChallengeReferencePort.completedTrainingSessions`, las sesiones con `completada_en` dentro de `[fecha_inicio, fecha_fin]` del reto y lo guarda en `retos.sesiones_completadas` (caché para listar sin leer Entrenamiento). Igual que el progreso de una tarea con bloques (`studyBlockProgress`), repetir el recuento no cambia nada.
* Al llegar al objetivo el reto se completa con el XP de su dificultad y publica `ChallengeCompleted`. Si un desmarcado lo deja por debajo **y lo había completado el recuento**, se descompleta restando exactamente ese XP. Una compleción manual por debajo del objetivo no se deshace.
* Disparadores: el oyente de `TrainingSessionCompletionChanged` (marcar y desmarcar) llama a `SyncTrainingSessionChallengesUseCase`; al crear o editar el reto se aplica el recuento actual (un reto con inicio pasado o con el objetivo rebajado puede quedar completado al guardarlo). Cada sesión nueva cuenta como actividad para la racha del reto.

## Consecuencias
* **Positivas:** entrenar mueve los retos de fitness sin acoplar módulos; idempotente y reversible; sin vocabulario nuevo en los vínculos ni en las tareas.
* **Negativas:** solo existe la métrica «número de sesiones» (no minutos ni RPE); un reto de fitness con tareas no avanza solo; el cliente debe enviar y mostrar `sessionTarget` / `sessionsCompleted`.
