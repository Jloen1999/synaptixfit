# 0023. Reglas del día a día: comodines de racha, modo exámenes automático, entreno sin conexión y actividad pasada

* **Estado:** Aprobado
* **Fecha:** 2026-10-31
* **Autores:** SynaptixFit

## Contexto
Lo que más hace abandonar una app de hábitos son los pequeños fallos de la vida real: un día sin actividad que
borra una racha de semanas, avisos de entreno en plena semana de exámenes, un gimnasio sin cobertura que pierde
las series, o un partido de fútbol que no se apuntó. Esta decisión agrupa cuatro reglas que los cubren.

## Decisión
* **Comodines de racha** (`StreakFreezes`, dominio de insignias): se gana uno por cada 7 días seguidos con
  actividad y se guardan como mucho 2. Un día sin actividad dentro de la racha gasta uno: no suma, pero no la
  corta. Se calcula entero a partir del historial de días activos en cada consulta (no hay tabla ni estado
  guardado), así el resultado es reproducible. Con un comodín guardado la racha no aparece «en riesgo».
* **Modo exámenes automático** (`NotificationPreferences.duringExamSeason`): si el modo es Normal y hay un examen
  pendiente en los próximos 7 días, las notificaciones y el plan de avisos del móvil se comportan como el modo
  Exámenes (solo lo académico, conflictos y fatiga). No se guarda: se decide en cada envío y vuelve solo. Descanso
  se respeta. La sesión de entreno ya se adapta a la cercanía de un examen (`SessionAdaptation`, Fase 2).
* **Entreno sin conexión** (cliente): si guardar una serie falla por falta de red, se guarda en el teléfono por
  sesión, se ve en la lista como pendiente y se reintenta cada 15 s, en orden. Terminar la sesión exige haberlas
  subido todas: la experiencia y la carga las calcula el servidor. Un error que no es de red al reintentar
  descarta esa serie (reintentarla no lo arreglaría).
* **Actividad pasada** (`LogPastActivityUseCase`): una actividad física ya terminada de los últimos 7 días se
  apunta como bloque de deporte completado con su esfuerzo; reutiliza `SetBlockCompletionUseCase` para que se
  apliquen los mismos topes de XP y la misma carga física que al marcarla desde el calendario.

## Consecuencias
* **Positivas:** perder un día o la cobertura no castiga; los avisos acompañan a la época de exámenes sin tocar
  ajustes; lo que se hizo fuera de la app cuenta.
* **Negativas:** el número de la racha ya no es «días seguidos» estrictos (lo explica la tarjeta de Progreso).
* **Aceptado:** en la cola sin conexión, si el servidor guardó una serie pero la respuesta no llegó, al reintentar
  se puede duplicar; la persona puede borrarla desde la lista. Las series pendientes viven solo en ese teléfono.
