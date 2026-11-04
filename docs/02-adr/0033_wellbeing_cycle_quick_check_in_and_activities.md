# ADR 0033 — Bienestar: ciclo opcional, registro rápido, actividades a mano y avisos de bienestar

- **Estado:** aceptado
- **Fecha:** 2026-11-04

## Contexto

La regulación cruzada ya adapta la sesión con el registro diario, el examen cercano y el ACWR, pero:

1. Quien tiene ciclo menstrual no podía tenerlo en cuenta, y la energía y las molestias de esos días cambian cómo se entrena.
2. El registro diario tenía cinco preguntas y vivía en otra pantalla; la adaptación de hoy no se explicaba antes de entrenar.
3. Correr, andar o un partido fuera de las rutinas solo se podía apuntar como bloque de 30 min o más, sin distancia ni ritmo, y no salía en el historial de entrenos.
4. Faltaban avisos útiles: racha en riesgo, registro diario y clase a punto de empezar con su aula.

## Decisión

- **Ciclo, opcional y con consentimiento** (`seguimiento_ciclo`, `dias_ciclo`, V1040). Apagado para todo el mundo: no se da por hecho por el género. Activarlo exige aceptar expresamente para qué se usa (`CYCLE_CONSENT_REQUIRED`) y se guarda cuándo. Son datos de salud (categoría especial del RGPD): solo los lee su dueño, se borran con un toque (al desactivar se ofrece borrar todo), se borran en cascada con la cuenta y entran en la exportación. No salen del backend ni se mandan a la IA.
  - La estimación del momento del ciclo es sencilla y se presenta como tal (formulas.md).
  - El ajuste del entreno es suave: si hoy se apuntó energía baja o alguna molestia, `SessionAdaptation` recorta las series al 90 % (`CYCLE_DISCOMFORT`). No se toca la generación de rutinas (`ContextAdjuster`): un día del ciclo no debe cambiar la rutina, solo la sesión de hoy.
- **Registro rápido de tres toques** (sueño, energía, agujetas) en la tarjeta de Rutinas, sobre el mismo `PUT /training/check-ins/today` (el estrés pasa a ser opcional y se conserva o queda neutro). `GET /training/adaptation/today` da la adaptación de hoy sin sesión, con `fatigueCause` (lo que más pesa en la fatiga) para explicarla en una frase: «Hoy harás menos series porque dormiste mal».
- **Actividades a mano con ritmo** (`actividades_apuntadas`, V1041). El deporte pasado admite desde 10 min, clase (`RUN`, `WALK`, `BIKE`, `SWIM`, `MATCH`, `OTHER`) y distancia; el servidor calcula el ritmo. Como un bloque del calendario dura al menos 30 min, el de una actividad corta ocupa esos 30 min terminando cuando terminó: la carga física puede quedar algo por encima en actividades muy cortas, a cambio de no tocar la regla de los bloques. `GET /planner/past-activities` lista el deporte completado (partidos del calendario incluidos) para la pestaña «Actividades y partidos» del historial.
- **Avisos de bienestar** (`WellbeingReminders`, sumados al plan de `ReminderPlanner` antes del límite diario): racha en riesgo (20:00, hitos), registro diario (9:00, fatiga; hoy solo si falta) y clase en 15 minutos con el aula (académica, se omiten las de «No fui»). Cada uno se apaga en `opciones_avisos` (V1042, `GET`/`PUT /notifications/reminder-options`).

## Consecuencias

- El cliente no estima nada: pinta la fase, el día y el ritmo que manda el servidor, y solo traduce el registro rápido a la escala 1-5.
- Un APK anterior sigue funcionando: los campos nuevos son opcionales y los avisos de tipo desconocido se ignoran.
- Pendiente: GPS en directo y Health Connect / Strava (fuera de esta decisión).
