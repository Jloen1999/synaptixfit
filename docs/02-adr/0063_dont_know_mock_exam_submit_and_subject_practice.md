# ADR 0063 — «No lo sé», entregar el simulacro y «Practicar» de la asignatura

- **Fecha:** 2026-11-24
- **Estado:** aceptado (plan UX del 19 nov 2026, tanda 5A «Académico: práctica»; referencia visual: maquetas
  `academico-fase4/` — Resumen, CrearPreguntas y RevisarPreguntas —, aprobadas en una fase anterior)
- **Completa:** ADR 0058 (crear preguntas y «Varias correctas») y ADR 0057 (pestañas de la asignatura).

## Contexto

Quien no sabía una pregunta solo podía inventarse una respuesta: no había forma de decir «no lo sé», ver la solución y
que esa pregunta volviera antes. En el simulacro, entregar sin contestar nada contaba como un test con nota 0 (historial,
carga cognitiva, insignias) y las preguntas sin contestar no dejaban rastro para el repaso. Además, las preguntas de una
asignatura estaban repartidas por apuntes: no había un sitio para verlas todas (incluidas las de «Varias correctas») ni
para elegir cómo practicar.

## Decisión

### «No lo sé» (servidor, regla de negocio)

- Es una respuesta más en **todos** los tipos de pregunta (elegir una, completar y «Varias correctas»), en la práctica
  libre, en la lista de «Practicar» y en el simulacro. El servidor la guarda como intento con `no_lo_se = true`
  (`QuestionAttempt.dontKnow`), siempre como fallo, y devuelve la solución (`AnswerResult.dontKnow`).
- **Cómo vuelve antes** (`QuestionStanding`, dominio): cada pregunta toma el estado de su último intento con una nota de
  la escala SM-2 — «No lo sé» 0, fallo 2, acierto 4, nueva sin nota — y se ordenan «No lo sé» → falladas → nuevas →
  acertadas al elegir las del simulacro, al dar el banco (práctica libre y tarjetas) y en la lista de la asignatura.
  Fórmula y motivos en `formulas.md`.
- En `PracticeScore` (nota propuesta al repasar el material) cuenta como fallo.
- API: `POST /questions/{id}/attempts` y `POST /test-sessions/{id}/answers` aceptan `dontKnow: true` sin respuesta;
  `POST /question-banks/{id}/practice-completions` recibe `dontKnow: [ids]`. Las respuestas llevan `dontKnow`.

### Entregar el simulacro (servidor)

- **0 respuestas no cuenta:** `TestSession.countsIfSubmitted()` es falso; la sesión queda **abandonada** (`ABANDONED`,
  no se borra) y la respuesta es 200 con `counted: false` y ese estado. No hay nota, XP, evento `TestSessionCompleted`
  ni intentos, y no sale en el historial (`TestSession.inHistory`; los lectores de carga, insignias y retos ya solo
  miran las completadas). Volver a entregarla da 409 (`QUIZ_SESSION_NOT_IN_PROGRESS`), como cualquier sesión cerrada.
  Cada sesión lleva `countsIfSubmitted` para que el cliente explique antes de entregar si contará.
- **Lo corregido no se cambia:** una pregunta del simulacro con resultado (respuesta o «No lo sé», que ya enseña la
  solución) no admite otra respuesta: 409 `QUIZ_QUESTION_ALREADY_ANSWERED`. Al cerrar la práctica libre manda el
  intento que dejó cada «Comprobar», no la respuesta que llegue al final.
- **Una sola «acertada»:** la del último intento, también en las cifras del banco (`QuestionBankView`).
- **Con respuestas**, las sin contestar pasan a «No lo sé» (`TestSession.complete` devuelve cuáles; se registra su
  intento) y se marcan `unanswered`. No cuentan como respondidas para la XP (`canClaimXp`).
- Migración `V1079__academic_dont_know.sql`: `intentos_pregunta.no_lo_se` y `test_sessions.no_lo_se` /
  `sin_contestar` (jsonb con ids).

### «Practicar» de la asignatura (cliente + `GET /subjects/{id}/questions`)

- Pantalla completa `/academic/subjects/:id/practice` (`SubjectPracticePage`, `SubjectPracticeBloc`), que se abre desde
  Resumen › Practicar («Ver todas tus preguntas»). El título lleva el nombre de la asignatura en una segunda línea
  (`subjectName` de la respuesta).
- Arriba, «N preguntas · M por repasar» con **una sola acción principal**: el repaso de hoy si toca (cola SM-2 de la
  asignatura); si no, la práctica libre (si hay varios apuntes con preguntas, «¿De qué apunte?»). Las demás formas
  (práctica libre, simulacro) son filas que se abren; «Crear preguntas» va con borde. Sin repasos, una nota lo dice sin
  flecha. Sin preguntas ni repasos, solo el estado vacío con «Crear preguntas».
- Debajo, «Tus preguntas»: todas (también «Varias correctas»), en el orden del servidor, con `AppSearchField`, «Cómo
  van» (Todas · Por repasar · Nuevas · Acertadas, `AppSegmentedChoice`) y, si hay más de uno, Tipo y Apunte
  (desplegables, uno al lado del otro solo si caben, medido con `context.textWidth`). Filtrar no es una regla: el estado de cada una lo da el servidor.
  Cada fila dice cómo va con icono y texto (`StandingPill`) y se abre en una hoja (`QuestionSheet`) que reutiliza
  `QuestionView`: «Comprobar» o «No lo sé» y, ya corregida, «Siguiente» (vuelve arriba y anuncia «Pregunta N de M») o,
  en la última, «Volver a la lista».
- `QuestionAnswerBar` (junto a `QuestionView`) pone «No lo sé» y la acción principal en fila si las dos etiquetas caben
  en su mitad (ancho real con `context.buttonWidth`) y, si no, una debajo de otra; ya corregida, pinta «Siguiente»,
  «Terminar» o «Entregar» en el mismo hueco y le pasa el foco (no se pierde al contestar). Lo usan la práctica libre,
  el simulacro y la hoja.
- Simulacro: «No lo sé» enseña la solución al momento (el resto se corrige al entregar) y en el navegador de preguntas
  tiene su propio estado; «Entregar» va aparte, con borde, y pasa a ser la acción principal cuando están todas
  contestadas. Antes de entregar («¿Entregar el simulacro?»), el diálogo explica qué pasa con las que faltan o, si
  `countsIfSubmitted` es falso, que no contará (relleno «Seguir contestando»; entregar, como texto). Si el servidor responde `counted: false`, la pantalla lo dice
  («Este simulacro no cuenta») con «Volver». En los resultados, «Respondiste «No lo sé»» y «Sin contestar: cuenta como
  «No lo sé»».

## Consecuencias

- **Diferencia con la maqueta aprobada** (`academico-fase4/Resumen.html`): la tarjeta «Practicar» de la maqueta lleva dos
  botones («Crear preguntas» y «Simulacro»); aquí lleva además «Ver todas tus preguntas», que abre el apartado nuevo (no
  existía al aprobarla). La pantalla «Practicar» no tiene maqueta: sigue el estilo de Resumen (tarjeta con un solo
  botón relleno, filas con flecha que se abren y botones con borde).

- Una app anterior no manda `dontKnow` y sigue funcionando; si entrega un simulacro vacío, abre sus resultados (la
  sesión sigue, abandonada).
- El banco ya no llega ordenado por `order`: el cliente conserva el orden del servidor.
- Código de error nuevo: `QUIZ_QUESTION_ALREADY_ANSWERED` (409). La lista usa `SUBJECT_NOT_FOUND`.
