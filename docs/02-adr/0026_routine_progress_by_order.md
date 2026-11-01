# 0026. La rutina avanza por orden; una sola rutina en curso

* **Estado:** Aprobado
* **Fecha:** 2026-11-01
* **Autores:** SynaptixFit

## Contexto
Una rutina tiene semanas y días numerados del 1 al 7. Ese número se leía de tres formas (día de la semana en el
editor, orden en Inicio, contador en el calendario) y el «próximo día» se calculaba dos veces (dominio y un SQL
copiado en Inicio). Consecuencias: un día no entrenado bloqueaba la rutina para siempre, la semana no se cerraba,
el calendario y la rutina se contradecían, duplicar o clonar cambiaba la rutina en curso sin avisar y las sesiones
abandonadas se borraban en silencio al volver a empezar ese día.

## Decisión
* **La rutina avanza al ritmo al que se entrena (orden, no fechas).** El número del día es el día de la semana
  preferido. Regla única en el dominio: `Routine.nextPendingDay` / `RoutineSchedule` (fecha prevista, atraso,
  «sesión k de n», «semana X de Y»). Inicio, Rutinas y el calendario usan el mismo caso de uso.
* **Días saltados:** estado `saltado` y `dias_rutina.cerrado_en` (V1000). Completar un día salta los anteriores
  pendientes (reversible). La semana se completa con todo hecho o saltado; la rutina, también (fin de ciclo,
  `RoutineCompleted`, «Repetir ciclo»).
* **Una sola rutina en curso:** activar una pausa la anterior; una nueva solo queda en curso si no hay otra.
  V1001 deja en curso solo la activa más reciente de cada usuario.
* **El calendario sigue a la rutina** por eventos (`RoutineDaysSkipped`, `RoutineDaysRemoved`,
  `RoutineDeactivated`); un bloque enlazado a un día de rutina no se marca a mano (`BLOCK_ROUTINE_LINKED`).
* **Sesiones abandonadas:** nunca se borran solas (`SESSION_STALE_OPEN`); se terminan en su fecha o se descartan.
  Solo se desmarca el mismo día; otros días se corrigen o se eliminan.

## Consecuencias
* Al desplegar, las rutinas activas antiguas (todas menos la más reciente de cada usuario) quedan en pausa.
* Los nombres «Día N» por defecto desaparecen (V1002); el cliente muestra el día de la semana.
* El SQL de Inicio que repetía la regla se eliminó.
* Ver `docs/01-architecture/formulas.md` («Avance de una rutina») y `events.md`.
