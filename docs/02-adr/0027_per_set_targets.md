# 0027. Objetivos por serie y series de tiempo o distancia

* **Estado:** Aprobado
* **Fecha:** 2026-11-01
* **Autores:** SynaptixFit

## Contexto
Un ejercicio planificado tenía un único número de repeticiones para todas sus series (el peso sí admitía
`weightsKg` por serie). No se podía planificar una pirámide (12/10/8) ni la sesión en vivo podía apuntar lo que
se mide en ejercicios de tiempo o distancia: `series_sesion` solo guardaba repeticiones y peso, así que una
plancha o una carrera se registraban con «repeticiones» sin sentido. El editor de la rutina mostraba los mismos
campos para todos los ejercicios, aunque el catálogo ya sabe cómo se mide cada uno (`MeasurementType`).

## Decisión
* **Valores por serie con valor común de reserva.** `ExerciseParameters` añade `repsPerSet` e
  `isometricSecondsPerSet` (como `weightsKg`): la serie n usa la posición n-1 y, si la lista falta o es más corta,
  el valor común. Las rutinas existentes no cambian (V1020 añade columnas `jsonb` nulas). El valor común sigue
  siendo la referencia de calorías y progresión y **lo fija el dominio del servidor**: si una lista cubre todas
  las series, el común es la media de repeticiones, el peso de trabajo (el mayor) y el aguante más largo; si
  todas coinciden, la lista se quita; las listas más largas que las series se recortan. La progresión mueve
  cada serie igual que el común. El cliente repite la regla solo para pintar al instante una edición en línea.
* **Series de tiempo y distancia.** `SessionSet` y `series_sesion` añaden `durationSeconds`/`duracion_segundos` y
  `distanceMeters`/`distancia_metros`. `POST /training/sessions/{id}/sets` los acepta y las respuestas los devuelven.
* **Cada serie guarda el ejercicio que se hizo** (`series_sesion.ejercicio_id`, V1021, rellenada desde su hueco).
  Antes solo enlazaba con el hueco (`seleccion_id`, `ON DELETE SET NULL`): al quitar o sustituir un ejercicio de la
  rutina, sus series perdían el ejercicio y el historial y los récords dejaban de saber qué fue. Las lecturas usan
  `COALESCE(ss.ejercicio_id, sel.ejercicio_id)`.
* **Tipo de seguimiento en el dominio.** `TrackingKind` (`REPETITIONS`, `HOLD`, `CARDIO`) lo decide
  `PlannedExercise.trackingKind()`: primero los datos planificados (duración o distancia → cardio; aguante →
  isométrico) y después el catálogo (`ExerciseRef.trackingKind()`). La API lo envía (`trackingKind`) y el cliente
  solo lo traduce a columnas (`SetFields`), con la misma regla de reserva si falta.
* **Sustituir un ejercicio** es un caso de uso propio (`PUT /routines/{id}/exercises/{plannedId}/exercise`): el
  hueco recibe un id nuevo en la misma posición y los parámetros se adaptan al tipo del nuevo
  (`ExerciseParameters.adaptedTo`: repeticiones y carga, aguante o bloque de cardio, con valores por defecto).
  Al terminar una sesión, una serie apuntada para un hueco que ya no existe se guarda como serie suelta (con su
  ejercicio) en vez de hacer fallar la sesión.

## Alternativas descartadas
* **Una tabla de series planificadas** (una fila por serie): más normalizada, pero obligaba a migrar todas las
  rutinas y a cambiar la generación, la IA y la progresión a la vez. Las listas `jsonb` siguen el patrón que ya
  usaba `pesos_kg`.
* **Reutilizar `repsDone` para los segundos**: mezclaba unidades y rompía volumen y récords.

## Consecuencias
* La API añade campos opcionales; los clientes antiguos los ignoran y siguen funcionando. Ojo: `PUT
  /routines/{id}/exercises/{plannedId}` sustituye todos los parámetros, así que editar un ejercicio desde un APK
  anterior borra sus valores por serie (vuelven al valor común). Conviene publicar el APK nuevo a la vez que el
  servidor.
* Los récords y el volumen siguen contando solo repeticiones y peso; las series de tiempo o distancia no suman
  récords todavía.
* Las propuestas de la IA no generan valores por serie (siguen con el valor común).
