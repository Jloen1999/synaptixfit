# ADR 0031 — Series de calentamiento, «Hasta no poder más», guía del ejercicio y «Usar hoy»

- **Fecha:** 2026-11-04
- **Estado:** aceptado

## Contexto

Quien entrena hace series suaves antes de las de verdad, a veces llega al límite en una serie y a menudo
encuentra la máquina ocupada. La app no distinguía el calentamiento (contaba como trabajo y falseaba
volumen, récords y la propuesta de peso), no sabía que una serie se hizo hasta no poder más y solo
permitía cambiar un ejercicio en la rutina entera. Además, la ficha del ejercicio daba pasos, pero no las
claves ni los errores típicos, en un lenguaje sencillo.

## Decisión

1. **Series de calentamiento:** `series_sesion.calentamiento`. Tienen numeración propia (`Calentamiento 1`
   no pisa la `Serie 1`) y en el dominio viven aparte (`TrainingSession.warmupSets`): `sets()` solo devuelve
   las de trabajo. Así volumen, récords, propuesta de peso, sugerencias tras la sesión y el progreso del día
   las ignoran sin tocar cada cálculo. Las kcal ya salen de las series planificadas y la carga de
   esfuerzo × tiempo activo, así que tampoco suben por el calentamiento. La API las devuelve en
   `warmupSets`.
2. **«Hasta no poder más»:** `series_sesion.al_fallo`. Si alguna serie del ejercicio lo fue,
   `ProgressionCalculator` mantiene la carga en vez de subirla aunque el esfuerzo de la sesión fuera bajo
   (las repeticiones fallidas y el esfuerzo máximo siguen mandando para bajarla).
3. **«Usar hoy»:** `RecordSetRequest.exerciseId` apunta la serie con otro ejercicio activo en el hueco de la
   rutina, solo en esa sesión; la rutina no cambia. El cliente guarda el cambio en el teléfono para no
   perderlo si se cierra la app.
4. **Guía del ejercicio:** `consejos_ejercicio` (por idioma; si falta, en español) con «Las claves» y
   «Errores comunes», redactados por familias de movimiento y asignados por el nombre del catálogo
   (`V1033`, generada con `tools/exercises/build_tips_migration.py`). `notas_ejercicio`: una nota privada
   por persona y ejercicio. `GET /exercises/{id}/tips`, `GET` y `PUT /exercises/{id}/note`.

Migraciones: `V1032` (columnas y tablas) y `V1033` (consejos de unas 1600 variantes en 4 idiomas).

## Consecuencias

- Un APK anterior no manda `warmup`, `toFailure` ni `exerciseId`: todo sigue como antes.
- Los ejercicios que se añadan al catálogo después de `V1033` no tienen consejos hasta una migración nueva:
  la app no enseña la sección (nunca un hueco vacío).
- La asignación por nombre depende de que el nombre en español siga el patrón de la familia; las
  exclusiones evitan variantes donde los consejos no valdrían (p. ej. «Remo al mentón»).
