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
