# ADR 0032 — Plan por fases, plantillas listas, evolución por ejercicio y tareas vinculadas a un día de rutina

- **Fecha:** 2026-11-04
- **Estado:** aceptado

## Contexto

Quien entrena con una rutina no veía en qué punto del plan estaba ni para qué servía cada semana (las
etiquetas «Adaptación», «Carga», «Pico» y «Descarga» eran jerga). Empezar exigía crear una rutina con IA o
a mano: no había rutinas ya hechas para casa o para semanas de exámenes. Tampoco se veía si un ejercicio
mejoraba con el tiempo, y una tarea de un reto no podía completarse sola al entrenar un día concreto.

## Decisión

1. **Plan por fases (`RoutinePlan`, dominio):** la respuesta de una rutina añade `currentWeek` (la semana
   del primer día con ejercicios sin hacer ni saltar, el mismo criterio que el «próximo día»; si no queda
   ninguno, la última), `progressPercent` (días hechos o saltados / días) y `nextStep`: con menos de 8
   semanas, `REPEAT_STRONGER` (repetir subiendo un poco el peso); con 8 o más, `NEW_PLAN` (cambiar de plan,
   porque repetir lo mismo tanto tiempo deja de hacer progresar). Cada semana trae `startsOn`/`endsOn` si
   la rutina tiene fecha de inicio (semana N = inicio + 7·(N−1)). El cliente nombra los tipos de semana en
   sencillo: Base, Subir, La más dura y Semana suave.
2. **Plantillas (`plantillas_rutina`, V1034-V1035):** catálogo de solo lectura con textos en es, en, fr y pt,
   generado con `tools/exercises/build_templates_migration.py`. `POST /training/templates/{id}/use` crea
   una rutina propia y privada delegando en `CreateRoutineUseCase` (mismas reglas que crear a mano). Cada
   semana repite los días de la plantilla con el tipo por posición; la semana suave quita una serie a cada
   ejercicio (mínimo una). Si un ejercicio no existe en la base de datos, la migración no lo inserta; una
   plantilla sin ejercicios no se lista.
3. **Evolución de un ejercicio (`ExerciseProgress`):** `GET /training/exercises/{id}/progress` devuelve por
   día el peso máximo estimado con la fórmula de la progresión de cargas (`ProgressionCalculator.oneRepMax`)
   y la serie que lo dio. Solo series de trabajo completadas con peso y de 1 a 12 repeticiones.
4. **Tareas vinculadas a un día de rutina:** nuevo tipo de vínculo `ROUTINE_DAY` (`dia_rutina`, V1036). La
   tarea se completa (o se reabre) cuando la sesión de ese día se completa (o se desmarca), por el evento
   `TrainingSessionCompletionChanged`. Un día de rutina no tiene fecha límite, así que no se comprueba el
   periodo del reto. `GET /challenges/routine-day-targets` lista los días de la rutina en curso que quedan
   por entrenar.

## Consecuencias

- La regla de la semana actual y del siguiente paso vive solo en el servidor; el cliente la pinta.
- Las plantillas se amplían con una migración nueva generada desde el JSON (no se edita una aplicada).
- Si se borra la rutina, la tarea vinculada deja de completarse sola y vuelve a marcarse a mano.
