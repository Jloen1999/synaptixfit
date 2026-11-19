# ADR 0058 — «Crear preguntas»: tipo y cantidad, preguntas del propio apunte, tandas y «Varias correctas»

- **Fecha:** 2026-11-19
- **Estado:** aceptado (maqueta aprobada por el propietario el 19 nov 2026, fase 4B)

## Contexto

Crear preguntas de un apunte o archivo era un solo botón: `POST /study-materials/{id}/question-bank` pedía a la IA
exactamente 10 (5 de opción múltiple y 5 de hueco) y **sustituía** las anteriores, con su historial. No se podía elegir
el tipo ni cuántas, ni aprovechar las preguntas que muchos apuntes ya traen (autoevaluaciones, exámenes de otros años).
Pedir 30 de una vez se acercaba al tope de tokens de salida (8.192) y, si la respuesta se cortaba, el JSON no servía y
se perdía todo. Desde Resumen › Practicar, «Crear preguntas» abría «Crear material» (ADR 0057).

## Decisión

- **Hoja «Crear preguntas»** (desde la práctica de un material y desde Resumen › Practicar, que primero pide el apunte
  si hay varios; con uno solo lo elige sola): tipo (Elegir una · Varias correctas · Completar la frase · Tarjetas ·
  Mezcla), cuántas (de 5 a 30, de 5 en 5, 10 por defecto) y, **solo si aplican**, «Tu apunte ya trae N preguntas» (No
  usarlas / Usar solo esas / Mezclarlas con nuevas) y «Ya tienes N de este apunte» (Añadir a las que tienes / Cambiarlas
  por las nuevas). «Tarjetas» se guarda como respuesta corta (`FILL_IN_BLANK`): es lo que pinta el modo Tarjetas.
  «Mezcla» alterna elegir una, completar la frase y varias correctas.
- **Preguntas del documento** (`POST /study-materials/{id}/document-questions`, no guarda nada): la IA **copia** las
  preguntas ya escritas, no las inventa, con su tipo, opciones y respuesta. Si el documento no trae la respuesta, la
  propone y se marca `ANSWER_PROPOSED` («Revísala»); las de desarrollo son `LONG_ANSWER` y las que quedan sin respuesta
  válida, `NO_ANSWER` (ninguna de las dos se usa; se ven atenuadas con el motivo). Un apunte sin señales de preguntas
  (ni «?», ni huecos, ni «Ejercicio 3», ni opciones «a)») no se manda a la IA (`DocumentQuestion.mayContainQuestions`);
  los archivos siempre se miran. Como mucho 40 por documento.
- **Revisión antes de guardar** («Revisa las de tu apunte»): casilla «Usar» por pregunta, «Cambiar la respuesta» y
  «Guardar N preguntas» con «X de tu apunte y Y nuevas». Al mezclar se marcan de entrada como mucho las pedidas; las
  nuevas son las que faltan hasta la cantidad elegida (`QuestionCount.newQuestions`).
- **Guardar** (`POST /study-materials/{id}/question-bank` con cuerpo `CreateQuestionsRequest`: `format`,
  `newQuestions` 0-30, `mode` `ADD`/`REPLACE`, `documentQuestions`): «Añadir» conserva las que hay (y su historial) y no
  guarda un enunciado que ya exista (igual sin contar mayúsculas, tildes ni espacios, `QuestionDraft.withoutRepeats`);
  «Cambiar» sustituye como antes. Sin cuerpo (apps anteriores) se hace lo de siempre: 10 mezcladas que sustituyen.
- **Por tandas de 10** (`QuestionBatch.SIZE`): diez preguntas son unos 2.000 tokens de salida, lejos del tope; cada
  tanda recibe los enunciados que ya existen para no repetirlos. Una tanda que falla (`AI_UNAVAILABLE`: JSON cortado o
  proveedor caído) se **reintenta una vez** (`AiBatches.ATTEMPTS`); si vuelve a fallar, se guardan las tandas anteriores
  y la respuesta dice cuántas se pidieron y cuántas se guardaron (`requestedQuestions`, `createdQuestions`); si no se
  consiguió ninguna, el error llega al cliente y el banco queda como estaba. La lectura del documento va igual, por
  posiciones («de la 11 a la 20») y con el total; si una tanda falla, se devuelven las leídas con `complete: false`.
- **«Varias correctas»** (`MULTIPLE_ANSWER`, `varias_correctas`, migración `V1078`): varias opciones correctas,
  guardadas en `respuesta_correcta` una por línea con el texto exacto de la opción. Se corrige **todo o nada**
  (`Question.isCorrect`): cuenta solo si se marcan todas las correctas y ninguna incorrecta (decisión del propietario;
  con puntos parciales, marcarlo todo saldría a cuenta). En práctica, simulacro y corrección se pinta con casillas y
  «Elige todas las correctas». La API manda `correctAnswers` (lista) en preguntas, correcciones y sesiones y acepta
  `answers` (lista) al responder; `correctAnswer` lleva todas unidas con « · ».
- **Apps anteriores:** cada llamada de preguntas de una app al día declara en la cabecera `X-Question-Types` los tipos
  que sabe pintar. Sin la cabecera el servidor no le manda «Varias correctas»: ni en el banco, ni en un simulacro nuevo,
  ni en la lectura de una sesión empezada en otro dispositivo, ni las cuenta al cerrar la práctica libre. Así una app
  vieja nunca enseña una de varias correctas como si fuera de elegir una.

- **Sin transacción mientras habla la IA** (como la importación de la guía, ADR 0015): «Crear preguntas» y la lectura
  del documento no llevan transacción envolvente (`QuestionCreationService`), para no retener una conexión de la base
  de datos durante minutos ni repetir llamadas a la IA si un bloqueo optimista reintenta el caso de uso. El guardado es
  un caso de uso aparte, corto y transaccional (`SaveCreatedQuestionsUseCase`), que vuelve a quitar los repetidos con
  lo que haya en ese momento. Si todas las del documento ya estaban y no se piden nuevas, no es un error: se guardan 0
  y el cliente lo dice («Se han guardado 0 de N: las demás ya las tenías…»).

## Consecuencias

- Crear 30 preguntas son tres llamadas a la IA (hasta seis con reintentos): el cliente espera hasta 16 minutos en esas
  dos llamadas (el peor caso del servidor: cuatro tandas con reintento y 2 min de tope cada una) y enseña «Creando
  preguntas… Puede tardar un minuto.». Mientras se guarda, la hoja no se cierra.
- Abrir la hoja lee las preguntas del documento con la IA (salvo apuntes sin señales). No se guarda el resultado: si
  se cierra la hoja, la siguiente vez se vuelve a leer (pendiente: guardarlo por material si el coste lo pide).
- Una sesión de simulacro empezada en una app al día y abierta en una vieja enseña menos preguntas que su total.
- Sin códigos de error nuevos: cantidad fuera de rango es `VALIDATION_ERROR` (`newQuestions`), la IA que falla sigue
  siendo `AI_UNAVAILABLE`/`AI_QUOTA_EXCEEDED`, con su texto y «Reintentar» en la hoja y en la revisión.
