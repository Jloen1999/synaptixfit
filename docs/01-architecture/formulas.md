# Fórmulas del dominio

> **Qué es:** los modelos que usa SynaptixFit para relacionar estudio y entrenamiento, de dónde salen y dónde están en el código.
> **Aviso:** son modelos orientativos para planificar mejor, no un sistema médico ni de diagnóstico.
> **Dónde viven:** `backend/src/main/java/com/synaptixfit/domain/model/neuro/` (sin dependencias de framework ni de base de datos).

| Nº | Qué calcula | Clase | Base |
|---|---|---|---|
| 1 | Gasto calórico del estudio | `StudyEnergy` | Mifflin-St Jeor (1990) para el metabolismo en reposo; MET cognitivos del *Compendium of Physical Activities* 2024 (1,3 estudio, 1,8 clase) |
| 2 | Carga cognitiva del día y capacidad atencional | `CognitiveLoad`, `CognitiveState` | Ver abajo (v2, recalibrada el 2026-10-18, ADR 0011) |
| 3 | Regulación cruzada: minutos máximos de estudio y volumen de entrenamiento | `CrossRegulation`, `CrossRegulationState` | ACWR de Gabbett (2016) y teoría del gobernador central (Noakes) |
| 4 | Calidad de repaso ajustada por fatiga física (SM-2-Physio) | `FatigueAdjustedRecall` | SM-2 (Woźniak) e hipótesis de la fatiga central (Newsholme, Meeusen) |
| 5 | Gasto calórico del ejercicio: `kcal = MET · kg · h` | `ExerciseEnergy` (`domain/model/neuro/`) | MET por ejercicio (`ejercicios.valor_met`). Los ejercicios añadidos en V850 toman el MET típico de su categoría según el *Compendium of Physical Activities* 2024: estiramientos y readaptación 2,3; movilidad y yoga 2,5; pilates e isométricos 3,0; fuerza 3,5; calistenia 3,8; halterofilia 6,0; cardio 7,0; combate 7,8; pliometría 8,0 |

## Fórmula 2 (v2): carga cognitiva

### Problema de la versión 1

`C = Σ (1 − e^(−0,1·D))·μ·e^(−0,05·R)`, acotada a 1. El término `1 − e^(−0,1·D)` se satura a los ~30 min, así que **un solo bloque de 25 min daba 0,92** («crítica») y la escala no distinguía 25 min de 4 h. Además el descanso descontaba el bloque *siguiente* en lugar de recuperar el cansancio *acumulado*.

### Modelo

```text
Esfuerzo de un bloque   e_i = D_i · μ_i                      D en minutos; μ = 1,0 / 1,3 / 1,8 según la dificultad de la asignatura
Esfuerzo acumulado      E_i = E_(i−1) · e^(−λ·R_i) + e_i     R_i = descanso antes del bloque i (min)
Carga del día           C   = 1 − e^(−E_n / τ)               0 ≤ C < 1
Capacidad atencional    A(t) = e^(−β·t)                      t = minutos de trabajo seguido (pausas < 17 min no cortan)
```

| Constante | Valor | De dónde sale |
|---|---|---|
| Capacidad diaria | 240 min equivalentes | Unas **4 h al día** es el máximo sostenible de práctica deliberada, repartida en sesiones de ≤ 1 h (Ericsson, Krampe y Tesch-Römer, 1993, *Psychological Review*). |
| τ | 240 / ln 5 ≈ 149 min | Se elige para que 4 h den **C = 0,8**, el umbral «crítico» de la interfaz. La curva saturante sigue el patrón de las escalas de esfuerzo diario de aplicaciones reales como **Whoop** (cada minuto extra pesa menos cuanto más cargado está el día). |
| β | ln 2 / 52 | La atención baja a la mitad tras **52 min** seguidos: el ciclo de trabajo de los usuarios más productivos medido por la aplicación **DeskTime** (2014, 52 min de trabajo + 17 de pausa). |
| Pausa que corta la racha | 17 min | El descanso del mismo ciclo 52/17. |
| λ | ln 2 / 90 | Semivida de recuperación de **90 min**, un ciclo ultradiano (ritmo básico de reposo-actividad de Kleitman). **Es una calibración**: no hay un dato único medido de recuperación de la fatiga mental. |
| μ | 1,0 / 1,3 / 1,8 | Se mantiene de la v1 (dificultad percibida de la asignatura). |

### Qué significa en la práctica

| Día | C | Zona en la app |
|---|---|---|
| Un Pomodoro de 25 min | 0,15 | Baja |
| 1 h de estudio | 0,33 | Moderada |
| 2 h seguidas | 0,55 | Moderada |
| 2 × 1 h con 90 min de descanso | 0,45 | Moderada |
| 4 h seguidas | 0,80 | Crítica |
| 1 h de una asignatura difícil (× 1,8) | 0,52 | Moderada |

Zonas de la interfaz: baja < 0,3 ≤ moderada < 0,6 ≤ alta < 0,8 ≤ crítica.

### Qué cuenta como actividad

Bloques completados de tipo cognitivo (estudio, clase, repaso, examen, entrega) y prácticas sin bloque (Pomodoro, tests, repasos SM-2). La misma lista (`StudyActivity.of`, vía `GetStudyActivityUseCase`) da los minutos y kcal de estudio de hoy y los minutos de estudio de la semana de Inicio. Detalle en `events.md`.

El estado guardado (`estado_cognitivo_usuario`) solo se actualiza con los eventos de actividad (`RefreshCognitiveStateUseCase`); leerlo (`GET /insights/cognitive-state`, Inicio) lo recalcula en memoria sin escribir, así que siempre refleja el día en curso.

### Cómo cambiar las constantes

Todas están en `CognitiveLoad` como constantes con nombre. Los tests de `NeuroFormulasTest` fijan los anclajes (25 min ≈ 0,15; 4 h = 0,8; atención = 0,5 a los 52 min; 90 min de descanso recuperan la mitad): si se recalibra, se actualizan a la vez y se anota aquí el motivo.

## Fórmula 3: regulación cruzada

- **ACWR** = media diaria de carga de 7 días / media diaria de 28 días; carga de sesión = RPE × minutos. Sin carga en al menos 2 de las 3 semanas anteriores a la aguda no hay línea base y el ACWR queda vacío (una sola sesión suelta hace 9 días ya no basta). Un bloque de deporte del calendario sin rutina («Fútbol 90 min») también suma carga: esfuerzo × minutos del bloque, con esfuerzo 5 si no se indica (ADR 0019).
- **Minutos máximos de estudio:** 90 min con ACWR ≤ 1,3; entre 1,3 y 2,0 bajan de forma logarítmica (`90·(1 − 0,5·ln(ACWR/1,3))`); por encima de 2,0, tope del 50 %. El planificador nunca sugiere bloques más largos (mínimo 30 min).
- **Volumen de entrenamiento con examen cerca:** `V = V_base·(1 − 0,40·min(1, C/C_max·e^(−0,15·días)))`.
- **Sesión adaptada (`SessionAdaptation`):** al abrir una sesión de rutina en curso se aplica el factor más restrictivo de: examen cerca (el de arriba), sobreentrenamiento (ACWR > 1,5 → 0,7) y registro de hoy con fatiga alta (> 50 → 0,8); solo si recorta al menos un 5 %. Series de cada ejercicio = `max(1, round(series · factor))`, nunca por debajo de las ya completadas; una sesión terminada o abandonada no se adapta. La app muestra «Sesión adaptada hoy» con el motivo (`GET /training/sessions/{id}/adaptation`).
- **Pomodoro recomendado (`FocusPlan`):** bloque = `min(52, minutos máximos de estudio)` (nunca menos de 25) y pausa = `round(bloque·17/52)` (mínimo 5); pausa larga de 30 min cada 3 bloques. Sin datos de carga física, 52/17. Inicio («Hoy, bloques de X min con pausas de Y») y el Pomodoro muestran lo mismo; el usuario puede ajustar el bloque entre 15 y 90 min antes de empezar.

## Fórmula 4: repaso SM-2 con fatiga

- El ajuste por fatiga sube la calidad hasta +0,5 (`FatigueAdjustedRecall`), pero **solo cambia el factor de facilidad**: si el repaso falla (calidad real < 3) sigue siendo un fallo. Antes un 2 con la máxima fatiga daba 2,5, se redondeaba a 3 y contaba como acierto.
- **Repaso adelantado:** un acierto antes de la fecha prevista se registra pero no cambia estado, intervalo ni fecha; un fallo sí reinicia (`StudyMaterial.simulate`). La vista previa muestra lo mismo.
- **Tras un fallo todas las opciones dicen «En 1 día»:** un fallo (nota < 3) reinicia las repeticiones a 0, y en SM-2 tanto fallar como el primer acierto dan 1 día (después 6 días y luego intervalo × facilidad). No es un error; la app lo explica cuando todas las opciones tienen el mismo intervalo.
- **Nota propuesta con la práctica (`PracticeScore`):** se valora el repaso después de repasar (practicar, abrir el material o recordarlo sin mirar). Si se practicó con preguntas del material en las últimas 6 h y después del último repaso, con al menos 3 preguntas respondidas (la última respuesta de cada una), se propone: aciertos ≥ 90 % → 5, ≥ 75 % → 4, ≥ 60 % → 3, ≥ 40 % → 2, ≥ 20 % → 1, menos → 0. El 60 % para el 3 sigue el umbral de acierto de SM-2 (nota ≥ 3). Es solo una propuesta: quien repasa elige.

## Progreso justo (ADR 0019)

| Qué | Regla |
|---|---|
| Sesión de entrenamiento | Menos de 10 min: sin XP y no cuenta para retos, insignias ni racha; solo las 2 primeras del día dan XP |
| Test o práctica | XP solo con ≥ 5 preguntas; como mucho 5 tests con XP cada 24 h (la práctica de un banco da XP una sola vez por banco y no entra en ese tope) |
| Reto | Como mucho 140 XP entre todas sus tareas (cada tarea muestra la que daría de verdad con ese tope); uno de sesiones marcado a mano antes del objetivo no da XP hasta alcanzarlo |
| Bloque del calendario | 10 XP por media hora hasta 4 h; como mucho 200 XP al día en bloques |
| Entrega | Como mucho 5 con XP cada 24 h |
| Pomodoro | Fecha de hoy o de ayer; para la racha, fase de foco de al menos 10 min |
| Racha | Un día cuenta si hay entrenamiento (sesión o bloque de deporte), registro diario, Pomodoro o estudio (bloque de estudio o repaso, repaso SM-2 o test) |

- **Por qué «+0 XP» (`SessionXpWithheld`):** al terminar una sesión sin XP, `POST /training/sessions/{id}/finish` devuelve `xpWithheld` = `SHORT_SESSION` (menos de 10 min; manda sobre el tope) o `DAILY_LIMIT` (ya dieron XP 2 sesiones ese día). Lo decide `TrainingRewards.withheldReason`; la app solo lo explica.
- **Hoja «Cómo se gana XP» (cliente, `xp_guide_sheet.dart`):** es texto explicativo con las cifras de esta tabla, del bloque de calendario, del Pomodoro (`FocusRewards`: 5 XP por concentración de ≥ 10 min, tope 20 al día), del registro diario (20) y del bonus semanal de estudio (150). **Si cambia una regla de esta sección, actualiza también esos textos** (`xpGuide*` en `app_*_core.arb`).

## Duración prevista de una sesión (`SessionDurationEstimate`)

Solo orienta («≈ 45 min» en el próximo día y el detalle del día; «quedan ≈ 12 min» en la sesión). La duración que cuenta para la carga (esfuerzo × minutos), las kcal y la XP es siempre la **real activa**: de empezar a terminar **menos las pausas** (`TrainingSession.activeSeconds`, ADR 0030). Decisión del propietario: una llamada o una máquina ocupada no suman carga ni calorías. El cronómetro de cada serie (`segundos_activos`) es opcional e informativo: no cambia la carga.

**Series de calentamiento (ADR 0031):** no cuentan como trabajo. No suman volumen ni récords, no cuentan en el progreso del día («4 de 12 series») y no entran en la propuesta de peso ni en las sugerencias tras la sesión. Sí forman parte del **tiempo** de la sesión: la carga (esfuerzo × tiempo activo) y las kcal cuando la app manda el tiempo real de cada ejercicio (`SessionCalories` con `realDurations`) incluyen los minutos de calentamiento, porque calentar también es moverse. Si no llega ese tiempo, las kcal salen de las series planificadas y el calentamiento no las cambia.

- Por ejercicio: si ya se hizo, su duración real de la última vez (`realDurationSeconds`, que guarda la sesión en vivo). Si no: `series × (trabajo + descanso)`, con trabajo por serie = duración objetivo (cardio), o segundos de aguante (isométrico), o `3 s × repeticiones` (tempo medio de una repetición controlada). El descanso tras la última serie cubre el cambio al siguiente ejercicio.
- Por día: suma de sus ejercicios, en minutos redondeados hacia arriba. Va en `estimatedMinutes` del día de rutina, del próximo día (`/training/...pending`) y del próximo entreno de Inicio; cada ejercicio planificado lleva `estimatedSeconds`.
- «Quedan»: la app suma `estimatedSeconds × series sin apuntar / series` de cada ejercicio (proporción de lo que manda el servidor; no hay regla en el cliente).

## «Hasta no poder más» (ADR 0031)

Si alguna serie de trabajo de un ejercicio se marcó «hasta no poder más» (`al_fallo`), `ProgressionCalculator` **mantiene la carga** de ese ejercicio en vez de subirla, aunque el esfuerzo de la sesión fuera bajo (RPE ≤ 7): ya llegó al límite. Las repeticiones fallidas (bajar 5 % por fallo, entre 70 % y 95 %) y el esfuerzo máximo (RPE ≥ 9,5 → −15 %) siguen mandando antes. Vale igual para la propuesta de carga en la sesión y para las sugerencias tras la sesión.

## Sugerencias tras la sesión: qué cambia y por qué

Cada ajuste de una sugerencia (`ExerciseAdjustment`) lleva los parámetros nuevos, los que tenía (`before`) y el motivo (`reasonCode`: `FAILED_REPS`, `VERY_HIGH_RPE`, `VERY_LOW_RPE`, `LOW_RPE_MORE_REPS`, `LOW_RPE_MORE_WEIGHT`, `LOW_RPE_MORE_TIME`, `LOW_RPE_MORE_DISTANCE`, `INACTIVITY`), que decide `ProgressionCalculator`. El motivo de **toda** la sugerencia va en `details.reasonCode` (lo elige `SessionFeedback`: fallos o RPE máximo en una degradación, RPE bajo o muy bajo en una progresión, `INACTIVITY` en una descarga), porque cada ejercicio puede tener uno distinto. La app enseña «Peso: 40 → 42,5 kg», el porqué con el RPE, las repeticiones fallidas o los días sin entrenar de `details`, y que al aplicarla se guarda en la rutina (se nota la próxima vez que se haga ese día); «Ahora no» la quita y la rutina sigue igual. Las sugerencias antiguas (sin `before`) se ven como antes. La adaptación de la sesión de hoy (`SessionAdaptation`) dice qué ejercicios pierden series («4 → 3 series») y que es solo hoy; «Hacerla completa» (con confirmación) vuelve a las series planificadas en la app (el servidor no lo impide). «Quedan ≈ min» reparte la estimación entre las series planificadas, no las adaptadas.

## Progresión de cargas dentro de la sesión (`LoadSuggestions`)

`GET /training/sessions/{id}/load-suggestions` propone la cifra de hoy de cada ejercicio («Hoy prueba 42 kg (+5 %)») con **las mismas reglas** que la sugerencia de después de la sesión (`ProgressionCalculator`), para que las dos digan lo mismo:

- **Base:** lo que se hizo de verdad la última vez que se entrenó ese ejercicio (la serie de más peso con sus repeticiones; el aguante, el tiempo o la distancia más largos), no lo planificado. Si alguien subió por su cuenta, se progresa desde ahí.
- **Regla:** el RPE de aquella sesión y sus repeticiones fallidas: fallos → carga −5 % por fallo (entre −5 % y −30 %); RPE ≥ 9,5 → −15 %; RPE ≤ 5 → +10 % (isométrico +10 s); RPE ≤ 7 → +1 repetición o, en el tope del rango del objetivo, +5 % de peso (tiempo o distancia +10 %). El peso se redondea a 0,5 kg.
- **Cifra que se propone (`metric`):** la que mueve el motivo: `WEIGHT`, `REPS`, `HOLD_SECONDS`, `DURATION_SECONDS` o `DISTANCE_METERS`. Los recortes al rango del objetivo no se proponen. Solo cambia la carga de hoy; las series no.
- **Sin propuesta** si no hubo RPE, si la última vez fue hace más de 14 días (manda la descarga por inactividad), o si la rutina ya pide esa cifra (la sugerencia de después de la sesión ya se aplicó).
- **Por serie (`perSet`):** el servidor da la cifra de cada serie planificada: en una pirámide, el peso y el aguante se mueven en la misma proporción (peso a 0,5 kg) y las repeticiones en la misma diferencia; si no, la cifra propuesta.
- **En la app:** aceptarla («Usar en las series que faltan») rellena con `perSet` las series que faltan de ese ejercicio. No toca la rutina ni las series ya apuntadas.

## «Tu estudio» (Progreso) y valores por defecto

- **Semana:** de lunes a domingo en la zona de la app (`StudyWeekSummary`).
  - Minutos de concentración: solo las fases de foco completadas del Pomodoro, por su día registrado. No es la actividad de estudio completa de `StudyActivity`.
  - Bloques hechos: bloques de estudio y repaso completados frente a los que ya debían estar hechos (terminados antes de ahora, o ya completados); `planAdherence = round(100·hechos/debidos)` (vacío si aún no tocaba ninguno). Así el lunes por la mañana no sale «0 %».
  - Aciertos en simulacros: `round(100·Σaciertos/Σpreguntas)` de los simulacros terminados (media ponderada por preguntas, no media de las notas).
  - Repasos pendientes: materiales con `siguiente_repaso_en ≤ ahora` que no están abandonados (igual que la cola de repasos).
  - Horas de la semana frente al objetivo: `horas_estudio_reales` de `carga_academica_semanal` (bloques de estudio y repaso hechos **más** la concentración del Pomodoro que no está dentro de un bloque completado) frente a `horas_objetivo_estudio_semana` del perfil académico (14 h sin perfil). Son las mismas horas que dan el bonus semanal de 150 XP.
- **Perfil físico corto (onboarding):** sin actividad, días ni minutos, el servidor usa actividad ligera y 3 días de 50 min (los 150 min semanales de actividad moderada que recomienda la OMS). Al reemplazar el perfil sin esos datos se conservan los que había.
- **Repetir cada semana:** hasta 15 copias más (un cuatrimestre), a la misma hora local; exámenes y entregas no se repiten y las copias no heredan vínculos (rutina, reto, tarea ni entrega).

## Lo que ya pasó

- **Estado de bloques y entregas (`ItemTimeStatus`):** hecho, pendiente, en curso o **sin hacer** (bloque de estudio, repaso, deporte o clase que terminó sin completarse) / **vencida** (entrega sin completar con la fecha pasada). Descanso, comida, sueño y los bloques de examen o entrega quedan como «pasado» sin seguimiento. El servidor lo calcula al responder (`timeStatus`); el cliente solo lo pinta.
- Un bloque **no se marca como hecho antes de empezar** (`BLOCK_IN_FUTURE`): evita sumar XP y horas por adelantado. Los bloques espejo de una sesión de deporte o de un repaso se completan solos desde su origen y no pasan por esta comprobación.
- **Reprogramar** lleva el bloque al primer hueco libre de su duración entre las 8:00 y las 22:00 de los próximos 7 días (`BLOCK_NO_FREE_SLOT` si no hay).
- **Adherencia académica:** las horas planificadas se prorratean por los días transcurridos de la semana (`planificadas·días/7`), los días con estudio se comparan con esos días y las entregas son las que ya vencían.
- **Avisos de Inicio:** entregas vencidas de los últimos 14 días (antes que las próximas) y bloques de ayer u hoy sin hacer (sin contar clases, que casi siempre vienen del horario importado). La fatiga alta va antes que los bloques sin hacer.
- **Lista «Pendientes» de entregas:** `upcoming=true&includeOverdue=true` añade las vencidas sin completar de los últimos 30 días (primero). Con solo `upcoming=true` la lista empieza hoy, como antes.
- **Racha:** la de Inicio es la efectiva (`GetStreakUseCase`): si ayer no hubo actividad, ya está rota aunque la guardada diga otra cosa.
- **Sesiones de entreno abandonadas:** una sesión abierta más de 6 h se da por abandonada y **nunca se borra sola**: empezar ese día devuelve `SESSION_STALE_OPEN` y la app ofrece «Terminar con lo registrado» o «Descartar». Al terminarla, la duración (activa, sin pausas) se acota a 4 h y la sesión se fecha al **inicio + duración + pausas ya cerradas**, nunca después de ahora (`TrainingSession.completionInstant`): la carga, la XP y los retos cuentan en el día en que se entrenó, no en el de hoy.
- **Desmarcar, corregir y eliminar:** solo se desmarca una sesión el mismo día en que se terminó (`SESSION_UNMARK_EXPIRED`); una de otro día se corrige (RPE y duración, que recalculan su carga y kcal; la XP no cambia) o se elimina (resta su XP y retira su carga, su avance en retos y su bloque).
- **Sesión de rutina pasada:** hasta 7 días atrás (`SESSION_PAST_DATE_INVALID`); se fecha ese día a las 12:00 (o ahora si es hoy) y da la XP de una sesión con el tope diario de ese día.

## Avance de una rutina (`Routine`, `RoutineSchedule`)

- **La rutina avanza al ritmo al que se entrena (orden, no fechas).** El número de cada día (1-7) es el día de la semana preferido, no una fecha fija.
- **Próximo día:** si un día tiene una sesión en curso (menos de 6 h), ese; si no, el primer día con ejercicios que no esté hecho ni saltado, en orden de semana y día (los días vacíos no cuentan).
- **Fecha prevista:** la del bloque pendiente del calendario de ese día posterior al último avance; si no hay, el siguiente día de la semana preferido a partir del día siguiente al último día cerrado (`cerrado_en`), o desde la fecha de inicio (u hoy) si no se ha avanzado. **Atrasado** si esa fecha ya pasó. Se muestra también «sesión k de n de la semana» y «semana X de Y».
- **Saltar:** completar un día salta los anteriores pendientes (reversible con «Recuperar»); un día hecho no se salta (`ROUTINE_DAY_NOT_SKIPPABLE`). Una semana está completada si todos sus días con ejercicios están hechos o saltados.
- **Fin de ciclo:** con todo hecho o saltado la rutina pasa a completada (aviso y `RoutineCompleted`); «Repetir ciclo» pone el avance a cero con inicio hoy y conserva el historial.
- **Una sola rutina en curso:** activar una pausa la anterior; una nueva (creada, generada, duplicada o clonada) solo queda en curso si no hay otra.
- **Retos vencidos:** pasada su fecha de fin ya no se completan, desmarcan ni avanzan (`CHALLENGE_EXPIRED` si se intenta a mano; la sincronización con entregas, bloques y sesiones los salta sin error). Un progreso no puede registrarse con fecha fuera del periodo del reto.

## Plan por fases, plantillas y evolución (ADR 0032)

- **Semana actual:** la del primer día con ejercicios sin hacer ni saltar (como el «próximo día»); si no queda ninguno, la última. **Avance:** `round(100 × (hechos + saltados) / días)`.
- **Fechas de cada semana:** solo con fecha de inicio; semana N empieza en `inicio + 7·(N−1)` y acaba 6 días después.
- **Al terminar:** menos de 8 semanas → repetir subiendo un poco el peso; 8 o más → cambiar de plan.
- **Plantillas:** todas las semanas repiten los días; la semana suave (descarga) quita una serie a cada ejercicio, mínimo una.
- **Peso máximo estimado por día** (`ExerciseProgress`): la mejor serie de trabajo completada con peso y de 1 a 12 repeticiones, con `ProgressionCalculator.oneRepMax` (la misma fórmula no lineal que la progresión de cargas). Con más repeticiones la estimación no es fiable.
- **Tarea vinculada a un día de rutina:** se completa cuando se completa la sesión de ese día y se reabre si se desmarca. No tiene fecha límite, así que no se comprueba el periodo del reto.

## Bienestar: ciclo, registro rápido y ritmo (ADR 0033)

- **Estimación del ciclo (`CycleOverview`):** un ciclo empieza el primer día con regla tras un día sin ella. Duración = media de los últimos 6 ciclos completos entre 21 y 45 días, acotada a 21-40 (28 si no hay). Regla = media de los periodos apuntados, acotada a 2-8 (5 si no hay). Con la ovulación estimada 14 días antes de la próxima regla (`duración − 14`): días 1…regla → «Con la regla»; hasta 3 días antes de la ovulación → «Después de la regla»; ±2 días → «Mitad del ciclo»; después → «Días antes de la regla». Próxima regla = último inicio + duración. Sin inicio en los últimos 60 días no se estima. Es orientativo, no médico: la app lo dice.
- **Ajuste suave por el ciclo (`SessionAdaptation`):** con el seguimiento activo y hoy energía baja o alguna molestia, factor de series 0,9 (motivo `CYCLE_DISCOMFORT`). Como el resto de motivos, se aplica el más restrictivo, no se multiplican.
- **Causa de la fatiga (`DailyCheckIn.mainCause`):** el término que más suma en la fórmula del registro diario ((6−sueño)·5, (dolor−1)·7, (6−energía)·4, (estrés−1)·5); con empate, sueño > agujetas > energía > estrés. Solo explica, no cambia la puntuación. El registro rápido no pregunta el estrés: se conserva el de hoy o el neutro (3), que no suma.
- **Ritmo (`ActivityPace`):** s/km = minutos·60 ÷ km (redondeado); km/h = km ÷ (minutos ÷ 60), a una décima. Nadando se enseña por 100 m (s/km ÷ 10). Se usan los minutos reales apuntados, no los del bloque.

## Carreras con GPS (ADR 0037)

Todo se calcula en el servidor (`RunTrack`, `RunEnergy`); el móvil solo manda la ruta cruda y enseña cifras orientativas mientras graba (`RunLiveStats`, mismo criterio simplificado).

- **Filtrado de puntos:** fuera los de precisión peor que 25 m, los que no avanzan en el tiempo y los «saltos imposibles»: más rápido que 12 m/s corriendo o andando (por encima de un sprint de élite) o 25 m/s en bici. Cada pausa abre un segmento nuevo: entre segmentos no se suma nada.
- **Distancia (haversine):** d = 2·R·asin(√(sin²(Δφ/2) + cos φ₁·cos φ₂·sin²(Δλ/2))), con R = 6 371 008,8 m (radio medio, UGGI). Error < 0,5 % frente al elipsoide, de sobra para una carrera.
- **Tiempo en movimiento:** se avanza desde un punto ancla y solo cuenta un paso cuando se aleja al menos 5 m (el baile del GPS parado mide 1-4 m); el paso es movimiento si va a 0,5 m/s o más (1,8 km/h). Si pasan más de 10 s sin alejarse, se estaba parado: el ancla se mueve sin sumar tiempo.
- **Ritmo medio:** s/km = segundos en movimiento × 1000 ÷ metros (desde 100 m). Se enseña como «min por km» con una línea: «Minutos que tardas en recorrer 1 km: cuanto menos, más rápido».
- **Tramos por kilómetro:** se interpola el instante exacto en que se cruza cada km dentro del paso que lo contiene; el último tramo, incompleto, sale si llega a 100 m, con su ritmo por km.
- **Desnivel positivo:** la altitud del GPS tiene ±10 m de ruido. Media móvil centrada de 5 puntos y umbral de 3 m con histéresis: la referencia solo cambia con subidas o bajadas de 3 m o más, y se suman las subidas. Sin el umbral, el ruido de una pista llana sumaría decenas de metros.
- **Kcal:** `kcal = MET · kg · h` (como `ExerciseEnergy`, horas en movimiento, peso del perfil o 70 kg). Correr y andar con las ecuaciones metabólicas del ACSM en llano: VO₂ = 3,5 + 0,2·v (correr) y 3,5 + 0,1·v (andar), v en m/min, MET = VO₂ ÷ 3,5. Bici por velocidad (Compendium, 01010-01050): < 16 km/h 4,0; 16-19 6,8; 19-22 8,0; 22-25 10,0; ≥ 25 12,0.
- **Carga física y XP:** la carrera es una actividad (`LogPastActivityUseCase`, origen GPS) con los **minutos en movimiento** y el esfuerzo «¿Cuánto te ha costado?» (1-10): carga = esfuerzo × minutos, el mismo registro que alimenta el ACWR (`SportBlockCompletionChanged` → `registros_carga_fisica`). Como cualquier actividad, desde 10 minutos y con el bloque mínimo de 30 min del calendario (ADR 0033).
- **Límites:** 20 000 puntos por ruta (5,5 h a un punto por segundo; el móvil graba uno cada 2 s o 3 m), petición ≤ 2 MB, de 10 a 300 minutos en movimiento, de los últimos 30 días (las manuales, 7). La ruta que se devuelve para dibujar se reduce a 600 puntos repartidos.
- **Entrenos de carrera:** duración prevista = pasos de tiempo + pasos de distancia a 6:00 min/km; el evento del calendario dura eso (entre 30 min y 5 h). Hasta 20 grupos, 6 pasos por grupo, 30 repeticiones y 200 pasos desplegados.

## Retos (ADR 0028)

- **Periodo:** solo se actúa a mano entre el inicio y el fin (`Challenge.requireOpen`), esté o no completado: antes, `CHALLENGE_NOT_STARTED` (estado `UPCOMING`); después, `CHALLENGE_EXPIRED`. Las tareas se pueden preparar antes de empezar, pero no editar tras el fin.
- **Peso de cada tarea:** `peso_i = xp(dificultad_i) / Σ xp(dificultad) × 100` (baja 20, media 40, alta 70), redondeado a centésimas; la última se queda el resto para sumar 100. Progreso del reto = `Σ peso_i × progreso_i / 100`. Antes había pesos manuales que no cambiaban la XP: ahora la dificultad es la única medida de importancia.
- **XP por tarea mostrada:** la que dio si está completada; si no, `min(xp(dificultad), lo que queda hasta 140)` repartido en el orden de las tareas (`Challenge.milestoneXp`). La del reto es la suma.
- **Lo vinculado manda:** una tarea con entrega o examen sigue su estado; una con bloques asignados avanza con `bloques hechos / bloques` y se completa al 100 %. Ninguna se marca a mano. Si tiene las dos cosas, manda la entrega. Un reto sin tareas vinculado lo completa su entrega; con tareas, el vínculo del reto es una referencia.
- **Fechas de lo vinculado:** la entrega vence dentro del periodo del reto y el bloque cae dentro de él (por días, en la zona de la app). Se comprueba al vincular y al cambiar las fechas del reto (no al mover la entrega). Si la entrega se borra, la tarea vuelve a marcarse a mano.
- **Progreso manual (retos sin tareas):** «¿Cuánto llevas?» fija un valor absoluto 0-100; bajar es una corrección y no cuenta para la racha ni se anota en el historial (que guarda lo avanzado). Desmarcar el reto lo pone a 0.
- **Racha mostrada:** `currentStreak` si el último día con actividad fue hoy o ayer; si no, 0.

## Configuración pendiente (aviso de Inicio)

`SetupChecklist` decide qué falta según el enfoque de uso, en orden de importancia: asignaturas
(estudios), perfil físico y rutina activa (deporte), algo en el calendario de los próximos 7 días
(siempre) y universidad y grado (estudios). `total` son las tareas que aplican al enfoque. El cliente
lo muestra como una tarjeta en Inicio con enlaces a cada sitio; «Ahora no» la oculta 7 días en ese
dispositivo. No bloquea nada: el onboarding corto deja saltar pasos y aquí se recuerdan.

## Comodines de racha (ADR 0023)
- Se gana **1 comodín por cada 7 días seguidos** con actividad; se guardan **como mucho 2**.
- Un día sin actividad dentro de la racha gasta uno: **no suma** pero **no la corta**. Sin comodín, la racha
  vuelve a 0. Hoy, aún sin actividad, ni corta ni gasta.
- Se recalcula entero desde el historial de días activos (`StreakFreezes.run`); no se guarda.

## Modo exámenes automático (ADR 0023)
- Con el modo **Normal** y un **examen pendiente en los próximos 7 días**
  (`NotificationPreferences.EXAM_SEASON_DAYS`), las notificaciones y los avisos del móvil se filtran como en el
  modo **Exámenes**. Descanso y Exámenes elegidos a mano se respetan.

## Analítica por asignatura
- Minutos: bloques de **estudio y repaso completados** en las últimas N semanas (4 por defecto), por semana ISO
  en la zona del usuario.
- **Recuerdas** = repasos con calidad real (SM-2, 0-5) **≥ 3** / repasos de la asignatura (umbral de superado de
  SM-2). Con **3 o más repasos** y **menos del 60 %** se marca «repásala más a menudo»; con menos repasos no se
  juzga (`StudyBySubject`).

## Referencias

- Organización Mundial de la Salud (2020). *Directrices de la OMS sobre actividad física y hábitos sedentarios*: 150-300 min semanales de actividad moderada en adultos.

- Ericsson, K. A., Krampe, R. T. y Tesch-Römer, C. (1993). The role of deliberate practice in the acquisition of expert performance. *Psychological Review*, 100(3), 363–406.
- DeskTime (2014). Estudio de hábitos de trabajo de sus usuarios: los más productivos trabajan 52 min y descansan 17.
- Kleitman, N. (1982). Basic rest-activity cycle — 22 years later. *Sleep*, 5(4), 311–317.
- Gabbett, T. J. (2016). The training–injury prevention paradox. *British Journal of Sports Medicine*, 50(5), 273–280.
- Mifflin, M. D. et al. (1990). A new predictive equation for resting energy expenditure. *American Journal of Clinical Nutrition*, 51(2), 241–247.
- American College of Sports Medicine (2021). *ACSM's Guidelines for Exercise Testing and Prescription*, 11.ª ed., cap. 6: ecuaciones metabólicas de andar y correr.
- Sinnott, R. W. (1984). Virtues of the Haversine. *Sky and Telescope*, 68(2), 159.
- Moritz, H. (2000). Geodetic Reference System 1980. *Journal of Geodesy*, 74, 128–133 (radio medio de la Tierra).
- Herrmann, S. D. et al. (2024). 2024 Adult Compendium of Physical Activities. *Journal of Sport and Health Science*, 13(1), 6–12.

## Objetivos por serie (`ExerciseParameters`, ADR 0027)

- **Serie n:** usa `repsPerSet[n-1]`, `weightsKg[n-1]` e `isometricSecondsPerSet[n-1]` si existen; si la lista falta o es más corta, el valor común (`reps`, `weightKg`, `isometricSeconds`).
- **Valor común** (referencia de calorías y progresión): lo fija el dominio del servidor (`ExerciseParameters`) cuando una lista cubre todas las series: media de las repeticiones, peso de trabajo (el mayor) y aguante más largo. Si todas las series coinciden, solo se guarda el común; las listas más largas que las series se recortan. El cliente repite la regla solo para pintar al instante.
- **Progresión:** si sube o baja una repetición el valor común, se suma o resta a cada serie; si escala el aguante, escala cada serie en la misma proporción.
- **Tipo de seguimiento (`TrackingKind`, dominio del servidor):** primero los datos del ejercicio planificado (duración o distancia → cardio; aguante → isométrico) y después el catálogo (distancia, o solo tiempo y aeróbico → cardio; solo tiempo → isométrico; lo demás → repeticiones). El cliente lo traduce a columnas: reps (+ kg si lleva carga), segundos (+ kg) o minutos y metros.
- **Sustituir un ejercicio (`adaptedTo`):** según el tipo del nuevo. Repeticiones: conserva series, repeticiones y descanso, y la carga si se mide por peso. Isométrico: aguante (30 s si no tenía). Cardio: bloque de tiempo (10 min si no tenía) y la distancia si se mide por distancia.
