# ADR 0048 — Estimación de la duración que aprende de las últimas veces

- **Fecha:** 2026-11-15
- **Estado:** aceptado

## Contexto

La duración prevista de un día de rutina («≈ 45 min» antes de empezar y «te quedan ≈ 12 min» en la sesión) salía de
`SessionDurationEstimate`: la fórmula `series × (trabajo + descanso)` o, si el ejercicio ya se había hecho, **la
duración real de la última vez** (`seleccion_de_ejercicios.duracion_real_segundos`).

Una sola vez manda demasiado: un día en que la sesión se quedó abierta (la persona se olvidó de terminar), en que se
charló entre series o en que se marcó todo de golpe al final deja la estimación torcida hasta la siguiente vez.

## Decisión

- **Dominio:** `PlannedExercise` guarda las **3 últimas duraciones reales** (`RecordedDuration`: segundos e instante
  de la sesión terminada), de la más antigua a la más reciente; `recordRealDuration(segundos, cuándo)` añade una y,
  con más de tres, sale la más vieja. Tres bastan para que la mediana descarte un día raro; guardar más no cambia la
  estimación de forma visible y frena el aprendizaje cuando la persona mejora.
- **Fórmula** (`SessionDurationEstimate`, detalle en `docs/01-architecture/formulas.md`):
  - la base es la de siempre (`series × (trabajo + descanso)`);
  - cada duración real se **acota** a [0,5 × base, 2,5 × base]: más de 2,5 veces es casi siempre una sesión olvidada
    abierta o una pausa sin marcar, y menos de la mitad, series marcadas de golpe;
  - 1 dato → ese; 2 → la media; 3 → la **mediana** (un día raro no cuenta).
- **Persistencia:** tabla nueva `duraciones_ejercicio_rutina` (V1070: `id`, `ejercicio_seleccionado_id` con
  `ON DELETE CASCADE`, `segundos`, `registrada_en`). La migración copia los `duracion_real_segundos` que había (con el
  id del propio ejercicio planificado, único, para no depender de una función del motor que genere uuid) y quita la
  columna. `RoutinePersistenceAdapter` la carga con la rutina y, al guardar, deja exactamente las que recuerda el
  dominio (compara segundos e instante en microsegundos, la precisión de la columna, para no reescribir las que no
  cambian). SQL estándar.
- **API:** no cambia de forma. `estimatedSeconds` (ejercicio) y `estimatedMinutes` (día) ya salían calculados;
  `realDurationSeconds` del ejercicio planificado pasa a ser la **duración de referencia** que usa la estimación (la
  aprendida, acotada), nula si aún no se ha entrenado.
- **Qué no cambia:** la duración que cuenta para la carga, las kcal y la XP sigue siendo la real activa de la sesión
  (ADR 0030); la estimación solo orienta.

## Consecuencias

- Una sesión olvidada abierta ya no convierte «≈ 45 min» en «≈ 3 h»; un día con prisa no lo baja a la mitad.
- La estimación tarda tres sesiones en seguir del todo un cambio real de ritmo (antes, una). Es lo esperado: prima la
  estabilidad.
- Copiar o compartir una rutina no copia las duraciones (son de quien entrena).
- Datos personales: la tabla sale en la exportación (`routineExerciseDurations`) y se borra en cascada con la rutina.
- Pruebas: `SessionDurationEstimateTest` (1, 2 y 3 datos, acotado, día raro, solo las 3 últimas) y
  `RoutineDurationsPersistenceIT` (V1070, guarda 3, descarta la cuarta y no reescribe las que no cambian).
