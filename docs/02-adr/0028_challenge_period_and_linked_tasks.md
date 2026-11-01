# 0028. Retos: una regla de periodo y una sola fuente de verdad para las tareas vinculadas

* **Estado:** Aprobado
* **Fecha:** 2026-11-01
* **Autores:** SynaptixFit

## Contexto
Los retos tenían reglas contradictorias según por dónde se actuara:

* El periodo solo miraba el fin. Antes de empezar se podía completar una tarea pero no registrar progreso, y el
  reto aparecía «Activo». Desmarcar una tarea de un reto vencido hacía perder su XP para siempre (luego no se
  podía volver a completar), y borrar las tareas pendientes de un reto vencido lo daba por completado.
* Un vínculo con una entrega o examen funcionaba en los dos sentidos: deshacer el reto descompletaba la entrega en
  el planificador (y le quitaba su XP), y «Completar siguiente tarea» marcaba un examen como hecho. Se podía
  vincular una entrega que vencía después del reto (la tarea no podía completarse nunca) y, al vincular una
  entrega ya hecha o ampliar el plazo, la tarea seguía pendiente.
* Los bloques del calendario: el «vínculo de tipo bloque» no hacía nada; el editor de bloques no dejaba elegir la
  tarea y no se validaba que la tarea fuera del reto ni que el bloque cayera en su periodo.
* La importancia de una tarea se medía dos veces: con su dificultad (XP) y con «pesos manuales» que debían sumar
  100 y solo movían la barra.

## Decisión
* **Regla de periodo única (dominio).** `Challenge.requireOpen(now)`: actuar a mano (completar, desmarcar,
  registrar progreso) solo entre inicio y fin, esté o no completado: `CHALLENGE_NOT_STARTED` antes y
  `CHALLENGE_EXPIRED` después. Editar tareas solo hasta el fin (`requireNotEnded`). Nuevo estado `UPCOMING`
  (aún no empieza); el filtro `ACTIVE` sigue incluyendo los abiertos para no romper clientes y `upcoming` se
  desglosa en el resumen. Desmarcar un reto sin tareas pone su progreso manual a 0 (V1011 lo guarda en
  `retos.progreso_manual`).
* **Una sola fuente de verdad para lo vinculado.** La entrega/examen o los bloques mandan sobre la tarea; nada
  del reto cambia el planificador (se elimina `ChallengeLinkCompletionChanged`). Una tarea vinculada a una
  entrega o con bloques asignados no se marca a mano (`MILESTONE_LINKED`); un reto sin tareas vinculado tampoco
  (`CHALLENGE_LINKED`). Con tareas, el vínculo del propio reto es solo una referencia. Si una tarea tiene entrega
  y bloques, manda la entrega.
* **Vínculos con fecha coherente.** La entrega vinculada debe vencer dentro del periodo del reto (por días,
  `CHALLENGE_LINK_OUTSIDE_PERIOD`); se comprueban los vínculos nuevos o, si cambian las fechas, todos. Al crear,
  editar o reemplazar tareas se aplica el estado actual de lo vinculado (`Challenge.syncWithLinks`): una entrega
  ya hecha deja la tarea completada y ampliar un reto vencido recupera lo ocurrido. El reto se carga con una foto
  de solo lectura de sus entregas (`LinkedDeadline`) y de los bloques de cada tarea (`StudyBlockProgress`).
* **Bloques.** `BLOCK` deja de ser un tipo de vínculo (V1012 pasa los antiguos a `horarios_academicos.hito_id`).
  El editor de bloques ofrece «Tarea del reto»; el planificador valida que la tarea sea del reto (si no se indica
  el reto, se toma el de la tarea) y que el bloque caiga en su periodo (`BLOCK_OUTSIDE_CHALLENGE_PERIOD`, también
  al mover; las copias semanales se detienen al salir del periodo). Crear, mover de tarea o borrar un bloque
  publica `StudyBlockAssignmentChanged` para recalcular la tarea.
* **Una sola medida de importancia.** Peso = XP de la dificultad / suma de las del reto × 100, calculado por el
  dominio (V1010 recalcula los guardados). El campo `weight` de la API se acepta y se ignora; se retira
  `MILESTONE_WEIGHTS_INVALID`.
* **XP honesta.** Cada tarea muestra la XP real con el tope de 140 (`Challenge.milestoneXp`: la que dio si está
  hecha; si no, la que daría haciéndolas en orden) y el reto la total.
* **Racha vigente.** La respuesta devuelve la racha de hoy (`currentStreakOn`): 0 si el último día con
  actividad fue antes de ayer.

* **Entrega borrada.** Si la entrega vinculada ya no existe (no hay foto), la tarea o el reto vuelven a marcarse a
  mano y el vínculo antiguo no impide editar el reto (no se revalida un vínculo que ya tenía).
* **Excepción aceptada:** la fecha se comprueba al vincular y al cambiar las fechas del reto, no al mover la
  entrega en el planificador ni al acortar un reto con bloques ya asignados. Si una entrega movida queda fuera del
  periodo, su tarea se completará igualmente si el reto sigue abierto; si ya venció, basta con ampliarlo.
* **`open` en la respuesta:** `Challenge.isOpenAt` (la misma regla que `requireOpen`, sin lanzar) para que el
  cliente no ofrezca toques que el servidor rechazaría.

## Consecuencias
* Clientes ya instalados: siguen funcionando (`UPCOMING` cae en «activo», `amount` sigue sumando, `weight` se
  ignora). Marcar a mano una tarea vinculada ahora responde 422.
* Ya no existe el camino reto → entrega: quien completaba la entrega desde el reto debe hacerlo en el
  planificador.
* Migraciones V1010 (pesos), V1011 (progreso manual) y V1012 (vínculos de bloque; las tareas ya completadas a mano
  no reciben el bloque para no perder su XP).
* Las migraciones V1010-V1012 tienen número menor que V1020-V1021: una BD local que ya aplicó estas últimas necesita
  `spring.flyway.out-of-order=true` una vez (o recrearse). Producción (v980) no se ve afectada.
* Ver `docs/01-architecture/formulas.md` («Retos»), `events.md` y `docs/03-api/errors.md`.
