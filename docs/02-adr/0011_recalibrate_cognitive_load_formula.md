# 0011. Recalibrar la fórmula de carga cognitiva con una capacidad diaria

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
La fórmula 2 original sumaba `(1 − e^(−0,1·D))·μ·e^(−0,05·R)` por bloque y acotaba a 1. Cada bloque se saturaba a los ~30 min: un único Pomodoro de 25 min marcaba 0,92 («crítica»), así que la carga no distinguía 25 min de 4 h. Al contar también los Pomodoros, tests y repasos, la carga pasaba a «crítica» con casi cualquier actividad y la regulación cruzada perdía sentido.

## Decisión
Mantener la estructura (acumulación exponencial, recuperación con el descanso y decaimiento de la atención) y calibrarla con fuentes reales:
- Esfuerzo en minutos equivalentes (`D·μ`) que se recupera durante el descanso con semivida de 90 min (ciclo ultradiano; calibración).
- Carga del día `C = 1 − e^(−E/τ)` con τ elegido para que **4 h de estudio exigente** (máximo sostenible de práctica deliberada, Ericsson et al., 1993) den 0,8, el umbral crítico. Curva saturante como las escalas de esfuerzo diario de aplicaciones como Whoop.
- Atención a la mitad tras **52 min** seguidos y pausa de **17 min** para cortar la racha (ciclo 52/17 medido por DeskTime).

Detalle, tabla de ejemplos y referencias en `docs/01-architecture/formulas.md`. La interfaz pública de `CognitiveLoad` no cambia.

## Consecuencias
* **Positivas:** la carga es proporcional a lo estudiado (25 min ≈ 0,15; 2 h ≈ 0,55; 4 h = 0,8); el descanso reduce el cansancio acumulado; la regulación cruzada y los avisos reaccionan a días realmente cargados.
* **Negativas:** los valores guardados antes del cambio (`carga_cognitiva_generada` de bloques antiguos) siguen la escala anterior; el estado del día se recalcula desde cero, así que solo afecta a históricos. La semivida de 90 min es una calibración y puede ajustarse con datos de uso.
