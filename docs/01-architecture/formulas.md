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

## Progreso justo (ADR 0019)

| Qué | Regla |
|---|---|
| Sesión de entrenamiento | Menos de 10 min: sin XP y no cuenta para retos, insignias ni racha; solo las 2 primeras del día dan XP |
| Test o práctica | XP solo con ≥ 5 preguntas; como mucho 5 tests con XP cada 24 h (la práctica de un banco da XP una sola vez por banco y no entra en ese tope) |
| Reto | Como mucho 140 XP entre todas sus tareas; uno de sesiones marcado a mano antes del objetivo no da XP hasta alcanzarlo |
| Bloque del calendario | 10 XP por media hora hasta 4 h; como mucho 200 XP al día en bloques |
| Entrega | Como mucho 5 con XP cada 24 h |
| Pomodoro | Fecha de hoy o de ayer; para la racha, fase de foco de al menos 10 min |
| Racha | Un día cuenta si hay entrenamiento (sesión o bloque de deporte), registro diario, Pomodoro o estudio (bloque de estudio o repaso, repaso SM-2 o test) |

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
- **Sesiones de entreno abandonadas:** una sesión abierta más de 6 h se da por abandonada; al empezar otra se cancela (con sus series) y su día de rutina vuelve a pendiente en Inicio. Al terminar, la duración se acota a 4 h para que olvidar la sesión abierta no infle minutos ni kcal.
- **Retos vencidos:** pasada su fecha de fin ya no se completan, desmarcan ni avanzan (`CHALLENGE_EXPIRED` si se intenta a mano; la sincronización con entregas, bloques y sesiones los salta sin error). Un progreso no puede registrarse con fecha fuera del periodo del reto.

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
- Herrmann, S. D. et al. (2024). 2024 Adult Compendium of Physical Activities. *Journal of Sport and Health Science*, 13(1), 6–12.
