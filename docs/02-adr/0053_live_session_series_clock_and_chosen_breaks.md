# ADR 0053 — Sesión en vivo con reloj de series y descansos a elegir (Pomodoro y sala de estudio)

- **Fecha:** 2026-11-15
- **Estado:** aceptado (maqueta v3 aprobada por el propietario)

## Contexto

Fase 2A del plan de mejoras.

- **Sesión en vivo.** El reloj de arriba era el tiempo real de toda la sesión y nunca paraba: parecía que la serie
  corría mientras se colocaban discos o se descansaba. El panel de abajo repetía cosas («Después: Remo con barra»
  con series aún por hacer, «Siguiente» y «Después» juntos), el ⏱ no decía que servía para empezar la serie y
  «Marcar serie 2» competía con el ✓ de la fila.
- **Pomodoro.** Solo se elegía el bloque (15-90 min); el descanso lo fijaba `FocusPlan` (proporción 52/17, mínimo 5) y
  el largo, 30 min tras 3 bloques.
- **Sala de estudio.** Solo 25 + 5 o 50 + 10 (`StudyRoomLength`), sin poder cambiarlo después de crearla.

## Decisión

### Sesión en vivo (cliente)

- **Cabecera:** «N de M series», barra de avance y la píldora **⏱ del tiempo haciendo series**
  (`LiveSessionState.seriesSeconds`: suma de `activeSeconds` de las series de esta sesión + la serie en marcha;
  `recordingSeconds` evita que baje un instante mientras se guarda la serie recién marcada). Estados
  (`SeriesClockMode`): corriendo, color de acento con un punto que late dos veces y se queda fijo (WCAG 2.2.2); serie
  en pausa, ámbar con ⏸; sin serie en marcha, gris y quieta. El lector oye «Tiempo haciendo series: 3 minutos y 21
  segundos». Debajo, pequeño y en minutos enteros: «Entreno: N min · te quedan ≈ M min» («te quedan» solo si es
  mayor que 0 y hay estimación, ADR 0048). Fuera «Tiempo real, sin contar pausas». El total que se guarda al terminar
  no cambia (tiempo activo, ADR 0030).
- **Panel de abajo**, con poco texto y la foto del ejercicio a mano (miniatura que abre `showExerciseHowToSheet`; sin
  foto, el icono de su tipo):
  - antes: «Serie 2 de 4», «8 × 60 kg», puntos de avance, **«▶ Empezar serie»** (arranca el cronómetro de la serie) y
    **«Ya la hice»** (marca sin cronómetro: no suma al ⏱);
  - haciendo: reloj grande de la serie, ⏸ (pausa la serie y la sesión, ADR 0030) y «✓ Serie hecha»; en pausa, reloj
    ámbar, «▶ Seguir» y ✓;
  - descanso: «✓ Serie 2 hecha · descansa», cuenta atrás, «Después: serie 3 · 8 × 60 kg» (o el ejercicio siguiente),
    −15 s, +15 s y «Saltar descanso». **Sin «Deshacer»**: si se marcó sin querer, se quita con el ✓ verde de la
    fila (con «Deshacer» en el aviso, como antes);
  - ejercicio terminado: foto, nombre y cifras del siguiente con «Ir al siguiente →»; todo hecho, «Terminar».
  - La pausa del grupo (ADR 0047), el calentamiento y «Cambiar solo hoy» siguen igual.
  - **Foco (WCAG 2.4.3):** al cambiar de momento, si el foco estaba en la barra (o se soltó porque un botón se
    desactivó o desapareció) pasa a la acción nueva; ⏸ y «Seguir» comparten foco; al empezar el descanso va a
    «+15 s», no a «Saltar descanso» (un Intro de más no se salta el descanso). Mientras se guarda la serie
    cronometrada, el panel sigue en «haciendo» con «Serie hecha» cargando.
- **Tabla:** un solo sitio para marcar, el panel. Las filas pendientes **no tienen ✓** (hueco para alinear; el lector
  dice «Serie 3, pendiente»; la que toca, «Serie 2, ahora» y la palabra «Ahora» a la vista); las hechas llevan el ✓
  verde que las quita y tocar la fila las corrige.

### Pomodoro: descansos a elegir

- La hoja **«Descansos»** (fila «Descansos: 10 min · largo 30 min · Cambiar», antes de empezar una fase) elige el
  descanso entre bloques (atajos 5 · 10 · 15 y el del día, marcado **«Recomendado»**) y el largo (15 · 20 · 30 y el
  recomendado), con ajuste fino minuto a minuto. «Saltar descanso» sigue igual.
- Límites del servidor en `GET /planner/focus-sessions/plan` (campos nuevos, aditivos): `minShortBreakMinutes` 1,
  `maxShortBreakMinutes` 30, `minLongBreakMinutes` 5, `maxLongBreakMinutes` 60 (`FocusPlan`).
- **La última elección se recuerda en el teléfono** (`FocusBreakChoice`, `FocusBreakChoiceStorage` con
  `shared_preferences`, casos de uso `Load/SaveFocusBreakChoiceUseCase`). Por qué en el teléfono y no en el servidor:
  no existen preferencias de enfoque en el servidor (habría que crear tabla, migración, endpoint y exportación de
  datos para una comodidad), el descanso no entra en ninguna regla del servidor (XP, racha y retos solo miran la
  concentración) y la elección no tiene que viajar entre dispositivos para que la app sea útil. Elegir el
  recomendado se guarda como «el del día» (nulo): si mañana la recomendación cambia, se sigue. Una elección fuera de
  los límites que mande el servidor se ajusta al límite.

### Sala de estudio: minutos libres

- `StudyRoomLength` desaparece. La sala guarda **minutos** (`StudyRoomTimes`): concentración de 15 a 90 (los límites
  del Pomodoro) y descanso de 1 a 30; 25 + 5 y 50 + 10 quedan como **atajos** (`StudyRoomTimes.PRESETS`).
- **Antes de empezar, cualquiera de dentro puede cambiarlos:** `PUT /api/v1/together/study-rooms/{id}/times`
  (`{focusMinutes, breakMinutes}` → la sala), caso de uso `ChangeStudyRoomTimesUseCase`. Con la sala en marcha o sin
  estar dentro: `TOGETHER_INVALID_STATE` (409, código existente); fuera de límites: `VALIDATION_ERROR` (400). Se
  avisa por el canal en directo (ADR 0047, tema `STUDY_ROOM`) y la sala de los demás dice «Ahora: 30 min de
  concentración y 6 min de descanso».
- **API:** `POST /together/study-rooms` recibe `focusMinutes` y `breakMinutes`; `length` (`SHORT`/`LONG`) se sigue
  aceptando solo si faltan los dos, para las versiones anteriores de la app (lo traduce el DTO, no el dominio); con
  uno solo, `VALIDATION_ERROR`. Los límites de la sala son las constantes de `FocusPlan` (no pueden separarse). `StudyRoomResponse` ya no lleva
  `length`. `GET /together/limits` cambia `studyRoomLengths` por `studyRoomFocusMinutes {min,max}`,
  `studyRoomBreakMinutes {min,max}` y `studyRoomPresets [{focusMinutes, breakMinutes}]`.
- **Migración V1071:** columnas `minutos_concentracion` y `minutos_descanso` (las salas existentes pasan a 50 + 10 si
  eran `LONG` y a 25 + 5 si no) y se quita `duracion`.
- «Estudiar con amigos» desde el Pomodoro llega con sus minutos (`?focus=…&break=…`).

## Consecuencias

- La sesión dice qué hacer con una palabra por botón; el reloj de arriba ya no parece una serie en marcha.
- Las apps instaladas antes de este cambio siguen creando salas (con `length`); leen la sala sin `length` (su DTO lo
  admitía nulo) y no ven atajos de duración (lista vacía): crean 25 + 5.
- Hay que regenerar `docs/03-api/openapi.yaml` (cambian `StudyRoomResponse`, `CreateStudyRoomRequest`,
  `TogetherLimitsResponse` y `FocusPlanResponse`; endpoint nuevo `PUT …/times`).
- Pruebas: bloc y pantalla de la sesión (antes, haciendo, pausa, descanso, terminado, sin ✓ en pendientes, reloj de
  series), Pomodoro (descanso elegido, recordado y acotado), sala (minutos libres, límites, cambio solo antes de
  empezar; `StudyRoomTest`, `StudyRoomServiceTest`, `StudyRoomIT`).
