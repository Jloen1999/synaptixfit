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

- **ACWR** = media diaria de carga de 7 días / media diaria de 28 días; carga de sesión = RPE × minutos. Sin carga anterior a los últimos 7 días no hay línea base y el ACWR queda vacío.
- **Minutos máximos de estudio:** 90 min con ACWR ≤ 1,3; entre 1,3 y 2,0 bajan de forma logarítmica (`90·(1 − 0,5·ln(ACWR/1,3))`); por encima de 2,0, tope del 50 %. El planificador nunca sugiere bloques más largos (mínimo 30 min).
- **Volumen de entrenamiento con examen cerca:** `V = V_base·(1 − 0,40·min(1, C/C_max·e^(−0,15·días)))`.
- **Pomodoro recomendado (`FocusPlan`):** bloque = `min(52, minutos máximos de estudio)` (nunca menos de 25) y pausa = `round(bloque·17/52)` (mínimo 5); pausa larga de 30 min cada 3 bloques. Sin datos de carga física, 52/17. Inicio («Hoy, bloques de X min con pausas de Y») y el Pomodoro muestran lo mismo; el usuario puede ajustar el bloque entre 15 y 90 min antes de empezar.

## «Tu estudio» (Progreso) y valores por defecto

- **Semana:** de lunes a domingo en la zona de la app (`StudyWeekSummary`).
  - Minutos de concentración: solo las fases de foco completadas del Pomodoro, por su día registrado. No es la actividad de estudio completa de `StudyActivity`.
  - Bloques hechos: bloques de estudio y repaso completados de los planificados esa semana; `planAdherence = round(100·hechos/planificados)` (vacío si no hay ninguno planificado).
  - Aciertos en simulacros: `round(100·Σaciertos/Σpreguntas)` de los simulacros terminados (media ponderada por preguntas, no media de las notas).
  - Repasos pendientes: materiales con `siguiente_repaso_en ≤ ahora` que no están abandonados (igual que la cola de repasos).
- **Perfil físico corto (onboarding):** sin actividad, días ni minutos, el servidor usa actividad ligera y 3 días de 50 min (los 150 min semanales de actividad moderada que recomienda la OMS). Al reemplazar el perfil sin esos datos se conservan los que había.
- **Repetir cada semana:** hasta 15 copias más (un cuatrimestre), a la misma hora local; exámenes y entregas no se repiten y las copias no heredan vínculos (rutina, reto, tarea ni entrega).

## Referencias

- Organización Mundial de la Salud (2020). *Directrices de la OMS sobre actividad física y hábitos sedentarios*: 150-300 min semanales de actividad moderada en adultos.

- Ericsson, K. A., Krampe, R. T. y Tesch-Römer, C. (1993). The role of deliberate practice in the acquisition of expert performance. *Psychological Review*, 100(3), 363–406.
- DeskTime (2014). Estudio de hábitos de trabajo de sus usuarios: los más productivos trabajan 52 min y descansan 17.
- Kleitman, N. (1982). Basic rest-activity cycle — 22 years later. *Sleep*, 5(4), 311–317.
- Gabbett, T. J. (2016). The training–injury prevention paradox. *British Journal of Sports Medicine*, 50(5), 273–280.
- Mifflin, M. D. et al. (1990). A new predictive equation for resting energy expenditure. *American Journal of Clinical Nutrition*, 51(2), 241–247.
- Herrmann, S. D. et al. (2024). 2024 Adult Compendium of Physical Activities. *Journal of Sport and Health Science*, 13(1), 6–12.
