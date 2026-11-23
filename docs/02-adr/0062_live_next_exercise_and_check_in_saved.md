# ADR 0062 — Sesión en vivo: el ejercicio siguiente se ve y se oye; «¿Qué tal estás hoy?» confirma lo guardado

- **Fecha:** 2026-11-21
- **Estado:** aceptado (plan UX del 19 nov 2026, tanda 4 «Entreno»; referencia visual: maqueta
  `sesion_en_vivo.html`, aprobada en una fase anterior)
- **Completa:** ADR 0053 (sesión en vivo) y ADR 0039 (un solo registro diario).

## Contexto

Al acabar un ejercicio, la sesión en vivo cambiaba sola al siguiente sin decirlo: el nombre cambiaba arriba, la tira de
ejercicios podía tenerlo fuera de la pantalla y, si se había bajado por la tabla de series, el título quedaba oculto. El
lector solo oía «Serie 3 registrada» y el descanso. En «¿Qué tal estás hoy?», tras la tercera respuesta (o «Guardar
cambios») las preguntas desaparecían sin una confirmación que se quedara, y en la pantalla del registro un fallo solo
salía en un aviso que se va. Además, en la tarjeta de Gimnasio la tercera respuesta no guardaba: la página leía las
respuestas de su último repintado, que aún no tenía la tercera.

## Decisión

### Ejercicio siguiente (sesión en vivo)

- **Cuándo es «pasar al siguiente»:** lo decide el bloc. `LiveSessionState.advancedCount` sube al marcar la serie con la
  que se acaba el ejercicio que se miraba (la vista pasa sola al siguiente con series) y con «Ir al siguiente», que
  ahora manda `LiveSessionEvent.nextExerciseRequested`. Tocar otro ejercicio en la tira (`exerciseSelected`) no cuenta:
  la persona ya sabe adónde va.
- **Resaltado:** el título del ejercicio que toca (`_ExerciseTitle`) va con borde `primary` y fondo `primaryContainer`,
  igual que la fila de la serie que toca y la fila `.cur` de la maqueta, más la etiqueta **«Ahora toca»** con icono ▶: el
  color no es la única señal. En la tira, el mismo fondo y un ▶ pequeño sobre la miniatura; el lector oye «…. Ahora toca».
  Mirando un ejercicio ya hecho, sin resaltar.
- **Desplazamiento:** la página desplaza la tira y la lista hasta el ejercicio (`revealContext`, sacado de
  `revealFocusedNode` en `widgets/app_focus_group.dart`; el foco no se mueve: si estaba en la barra, ella lo lleva a la
  acción nueva). Con animación (`TokensDuration.slow`) salvo que el sistema pida reducir el movimiento
  (`context.motion`, `MediaQuery.disableAnimations`), que salta sin animar. La tira deja de ser perezosa (pocos
  ejercicios) para que el siguiente exista aunque esté fuera de la pantalla.
- **Anuncio, una vez:** «Siguiente: Press banca, serie 1 de 4». Al marcar una serie, «Serie N registrada» ya no se dice
  al tocar sino cuando la sesión la tiene, y en el mismo anuncio que lo que pasa después: en la última serie de un
  ejercicio, «Serie 4 registrada. Descanso: quedan 90 segundos. Siguiente: …» (con la pregunta de calibración si toca).
  Si no llega a guardarse, no se dice. Lo calcula `_transitionAnnouncement` con el estado anterior y el nuevo.
- **Sin pisarse con el foco:** los anuncios de la sesión salen al acabar el cuadro siguiente
  (`SchedulerBinding.endOfFrame`), después de que la barra mueva el foco a la acción nueva («Ir al siguiente» →
  «Empezar serie»): el lector lee el botón y luego el anuncio, sin cortarlo.

### Confirmación del registro diario

- Tras guardar (tercera respuesta la primera vez o «Guardar cambios»), **«Guardado hoy a las 9:41»** con icono ✓ se queda
  en la tarjeta de Gimnasio (encima de la explicación de la adaptación) y en la pantalla del registro (justo debajo de
  las preguntas si guardó la tercera respuesta; junto al botón si se guardó con él; si después se cambia una respuesta
  o un detalle, la nota se quita porque ya no está guardado):
  `CheckInSavedNote` (`AppInlineMessage` de éxito, sin región viva). La hora es la del teléfono al confirmarse el
  guardado (`savedAt` en `QuickCheckInState` y `CheckInState`, con reloj inyectable); la confirmación dura mientras la
  pantalla está abierta. Al volver otro día no se enseña: el servidor no da la hora de la última modificación.
- Se anuncia al lector **una vez**, al guardar: en la tarjeta, junto con la frase de cómo queda el entreno (la tarjeta
  carga la adaptación nueva antes de dar el guardado, así el anuncio ya la trae; la explicación deja de ser región viva
  para no repetirlo); en la pantalla del registro, junto con «adaptamos tu día a cómo estás». El aviso flotante de
  «Guardado» de esa pantalla se quita (`TrainingMessage.checkInSaved`): eran dos confirmaciones del mismo guardado.
- **Tarjeta de Gimnasio, dos fallos distintos** (`QuickCheckInState.saveError` y `loadError`): si no se pudo guardar,
  el motivo y «Reintentar» que vuelve a guardar (cargando mientras envía); si no se pudo leer la adaptación (al entrar o
  justo después de guardar), el motivo y «Reintentar» que la vuelve a leer (`QuickCheckInEvent.refreshed`). Lo guardado
  desde la tarjeta (`saved`) cuenta como hecho aunque falle esa lectura: no vuelven las preguntas vacías, la nota se ve
  igual y el anuncio dice solo «Guardado…», sin inventar cómo queda el entreno.
- **Si falla:** el motivo (región viva) y «Reintentar» en la propia tarjeta. Donde ya hay un botón de guardar a la vista,
  ese mismo botón pasa a decir «Reintentar» (no hay dos botones que hagan lo mismo). En la pantalla del registro el fallo
  ya no sale en un aviso (`CheckInState.saveError`).
- La regla de cuándo se guarda sigue en el dominio (`CheckInAnswers.savesOnLastAnswer`); la tarjeta lee las respuestas
  del bloc al guardar.

## Diferencias con la maqueta

- La maqueta marca la serie que toca con «Ahora» y no dibuja el paso al ejercicio siguiente. Se reutiliza su estilo
  (`primaryContainer` + borde `primary`) para el título del ejercicio, pero la etiqueta es «Ahora toca»: la fila de la
  serie ya dice «Ahora» y dos etiquetas iguales en la misma pantalla competirían.
- La maqueta mueve el foco a «Siguiente» en su guía de primer uso; aquí el foco sigue la regla de la barra (ADR 0053) y el
  lector recibe el anuncio.

## Consecuencias

- El estado de la sesión gana un contador; la pantalla solo pinta, desplaza y anuncia.
- Tests: `live_next_exercise_test.dart` (resaltado, anuncio único con y sin descanso, tira sin anuncio, desplazamiento con
  y sin animación, 320 px al 200 %), `check_in_saved_test.dart` (tarjeta y pantalla: guardado, anuncio, fallo con
  «Reintentar», 320 px al 200 %) y los de bloc (`live_session_bloc_test`, `check_in_bloc_test`).
