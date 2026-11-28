# ADR 0067 — Sesión libre con ejercicios

- **Fecha:** 2026-11-28
- **Estado:** aceptado
- **Completa:** ADR 0030 (sesión en vivo), ADR 0053 (barra de la sesión), ADR 0054 (cifras de partida) y ADR 0055
  (atajos de Entreno). Maqueta aprobada: «Sesión libre» (pantallas 3a y 3b); el nombre se queda «Sesión libre».

## Contexto

La sesión libre apuntaba «Series libres» sin ejercicio: no quedaba registrado qué se hizo, ni servía para récords,
historial ni repetirla. En «Más», además, Historial y Ejercicios se ofrecían otra vez aunque ya estuvieran en los
atajos (a partir de ~600 px).

## Decisión

1. **La sesión libre lleva su propia lista** (`ejercicios_sesion_libre`, `V1082`). Cada hueco es un
   `PlannedExercise` de la sesión (`TrainingSession.freeExercises`), con sus cifras de partida; las series enlazan con
   él (`series_sesion.hueco_libre_id`) y guardan su `ejercicio_id`. Así la sesión en vivo es la misma que con rutina
   (tabla, `LiveSessionBottomBar`, descansos, «Cambiar solo hoy»): el cliente solo recibe `exercises` en la sesión.
2. **Empezar tiene tres caminos y una fuente por llamada** (`POST /training/sessions`, `StartFreeSessionUseCase`):
   `exerciseIds` (elegidos con el buscador o por grupo muscular), `fromSessionId` (repetir lo que se hizo: series y
   cifras de verdad, `FreeSessionPlan.performed`) o `templateId` + `templateDayNumber` (la primera semana de ese día,
   con el peso de partida). Las cifras de partida de un ejercicio elegido las pone el servidor
   (`FreeSessionPlan.startingFor`, las mismas que al añadirlo a una rutina). Sin fuente, empieza vacía.
3. **«Añadir ejercicio»** (`POST /training/sessions/{id}/exercises`): idempotente; en una sesión de rutina,
   `SESSION_NOT_FREE`.
4. **«Guardar como rutina»** (`POST /training/sessions/{id}/routine`, opcional, en el resumen): una rutina propia de
   un día (el de la semana en que se entrenó) con lo hecho, vía `CreateRoutineUseCase`. Sin series con ejercicio,
   `SESSION_NOTHING_TO_SAVE`; repetir una sesión antigua sin ejercicios, `SESSION_NOTHING_TO_REPEAT`.
5. **Cuenta igual que cualquier entreno:** terminar es `FinishTrainingSessionUseCase` de siempre, así que racha, XP
   (con sus topes), carga, retos, «Esta semana» y «Tu semana» salen de las mismas reglas; las kcal usan la lista de la
   sesión. Las propuestas de progresión solo miran huecos de rutina (cambian la rutina).
6. **«Más»** recibe si los atajos anchos están a la vista (`TrainingQuickAction.more`) y no los repite.

## Consecuencias

- Las sesiones libres antiguas siguen leyéndose: sin lista, con sus «Series libres».
- La calibración y la propuesta de carga de la sesión libre no se piden al servidor todavía (son reglas de rutina).
- En el calendario, un entreno suelto se sigue marcando con «Marcar como hecho» (no lo enlaza ningún día de rutina);
  la sesión libre terminada sale hecha en «Esta semana» y en «Tu semana», como cualquier otra.
