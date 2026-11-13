# ADR 0030 — Pausas de la sesión y cronómetro por serie

- **Fecha:** 2026-11-01
- **Estado:** aceptado

## Contexto

La duración de una sesión era el tiempo de reloj desde «Empezar» hasta «Terminar». Durante un entreno hay
pausas imprevistas (una llamada, una máquina ocupada) que inflaban la carga física (esfuerzo × minutos) y
las kcal. Además, quien entrena quiere saber cuánto tardó en cada serie.

## Decisión

1. **Pausas en la sesión (dominio):** `TrainingSession` guarda `pausedAt` (pausa en curso) y
   `pausedSeconds` (pausas ya cerradas). `POST /training/sessions/{id}/pause` y `/resume` son idempotentes. `/resume` acepta `resumedAt` (opcional): el móvil reanuda al momento y, si no hay conexión, lo reintenta después con la hora del toque; el servidor la acota entre el inicio de la pausa y ahora. Mientras la reanudación no llegue, el cliente no deja terminar (si no, se contaría como pausa lo entrenado después).
   Terminar una sesión en pausa cierra la pausa.
2. **Duración = tiempo activo:** `boundedDurationSeconds` acota lo que manda el cliente al tiempo activo
   (`inicio → ahora − pausas`) y a 4 h. Decisión del propietario: las pausas **no** cuentan para la carga
   física ni para las kcal.
3. **Cronómetro por serie, opcional:** `series_sesion.segundos_activos` guarda lo que marcó el cronómetro de
   la serie (sin sus pausas). Es nulo si la serie se marcó sin usarlo: el cronómetro ayuda, nunca obliga.
4. **Sesión abandonada:** sigue siendo la abierta más de 6 h de reloj desde que empezó (una pausa no la
   alarga: nadie retoma un entreno al día siguiente). Al terminarla se fecha en
   `inicio + duración + pausas cerradas` (nunca después de ahora); una pausa que quedó abierta no cuenta.

Migración: `V1031` (`sesiones_registradas.pausada_en`, `segundos_en_pausa`; `series_sesion.segundos_activos`).

## Consecuencias

- Un APK anterior no pausa: su duración se sigue acotando al tiempo de reloj (no hay pausas que restar).
- El cliente muestra el tiempo activo con la misma regla (`startedAt`, `pausedAt`, `pausedSeconds` del servidor).

## Revisión (noviembre 2026): sesión más clara

Decisión del propietario (vocabulario, sección 4: ir al grano y pocos pasos):

- **Empezar es un toque.** Se quita la hoja «El cronómetro ya está en marcha» y su preferencia «No volver a
  explicarlo» (caso de uso, repositorio y almacenamiento locales). El tiempo real ya se ve en la píldora con la
  línea «Tiempo real, sin contar pausas».
- **Terminar son dos toques:** «Terminar» abre una hoja con el esfuerzo y «Guardar». Si faltan series o no hay
  ninguna, la propia hoja lo dice en una frase; ya no hay diálogo previo ni rojo.
- **Un verbo por acción:** «Terminar» (antes «Finalizar», «Terminar ahora», «Terminar con lo registrado»);
  «Descartar sesión» (antes «Abandonar»), confirmado con el mismo verbo; «Saltar descanso». La hoja de salir
  dice solo «El tiempo se para.» y el único camino de salida es la flecha (se quita el icono ⇥).
- **Desmarcar como en Hevy o Strong:** volver a tocar el ✓ de una serie hecha la desmarca al momento, con
  «Deshacer» y sin diálogo; tocar la fila (fuera del ✓) abre la hoja para corregirla. Desmarcar para el
  descanso **de esa serie** (`LiveSessionState.restForSet`); corregir una serie o deshacer un desmarcar no
  arranca otro descanso (`LiveSessionEvent.setRecorded(startRest: false)`). Igual en la vista de rutina y en la
  de lista.
- **«Deshacer» siempre a la vista:** mientras corre el descanso de la serie recién marcada, «Serie N registrada
  · Deshacer» va dentro del panel del descanso (el aviso flotante quedaba tapado); sin descanso, en el aviso.
- **Una acción destacada:** «Marcar serie N» es el botón principal; el cronómetro de la serie es un botón
  cuadrado con icono y su nombre en la descripción («Cronometrar la serie»).
- **Detalle de una sesión terminada:** «Desmarcar» y «Eliminar» se parecían. El servidor sí distingue:
  `unmark` (solo el mismo día) la vuelve a abrir con sus series y `delete` la borra. La etiqueta lo dice:
  «Reabrir y seguir» (sin diálogo, entra en la sesión) y «Eliminar» (confirmado). Los diálogos ya no hablan de
  XP; el resumen y el historial de entrenos tampoco la enseñan (se ve en Progreso y al subir de nivel).
