# ADR 0057 — Académico al grano: tarjeta con lo de hoy y asignatura en cinco pestañas

- **Fecha:** 2026-11-19
- **Estado:** aceptado (maqueta aprobada por el propietario el 19 nov 2026, fase 4A)

## Contexto

La tarjeta de asignatura enseñaba siglas, profesor y «N apuntes · N archivos», cosas que no ayudan a decidir qué
hacer hoy. El detalle tenía dos pestañas y «Progreso» lo mezclaba todo (eventos, retención, simulacro, temario,
simulador de nota, profesorado, bibliografía). El curso y el semestre salían en dos escalas para lo mismo: la cabecera
decía «2.º curso · 1.º semestre» (1-2) y el temario «Semestre 6» (el del grado), y la importación de la guía docente no
rellenaba el curso de la asignatura. Varias palabras eran jerga para un principiante («Flashcards», «Centro de
generación», «Retención», «Simulador de nota», «Modalidad de evaluación», «Fuentes», «No recuperable»).

## Decisión

- **Tarjeta (lista de Académico):** nombre; «6 ECTS · 2.º curso · 1.er cuatri» (cada parte que falta se omite); barra
  «Temas 4 de 10» si hay guía docente o «Sin temario: importa la guía» (botón aparte, fuera de la zona que abre la
  asignatura); píldora «3 repasos hoy» si hay; y «Lo próximo» (`nextUp`, ADR 0036). Arriba de la lista, «N repasos para
  hoy · Repasar» repasa todos seguidos. «Añadir» pasa a la barra; «Apuntes compartidos», al menú «Añadir».
- **Los datos los calcula el servidor** y llegan en `SubjectResponse` con campos nuevos y opcionales (las apps antiguas
  los ignoran): `course`, `term` (curso y cuatrimestre 1-2, de `asignaturas_usuario_semestre`), `topicsDone` y
  `topicsTotal` (del plan guardado en `documentos_ia`; nulos sin plan o sin temas) y `reviewsDueToday` (materiales con
  repaso vencido, la misma regla que `findDue`, `StudyMaterial.isDue`). Se leen por lotes: un `findAll` de documentos y
  un recuento agrupado de repasos, no una consulta por asignatura.
- **Un solo formato de curso:** «2.º curso · 1.er cuatri» (`CourseTerm`). La importación de la guía lo asigna al aplicar
  si la asignatura aún no lo tenía (nunca pisa lo que eligió el estudiante). `CourseTerm.fromGuide`: un semestre mayor
  que 2 es del grado (6 → 3.er curso, 2.º cuatrimestre); con 1 o 2 hace falta el curso; si la guía no lo deja claro, no
  se asigna (mejor nada que un curso equivocado). La revisión de la importación enseña el resultado (`course` y `term`
  en `ImportResponse`) y el temario deja de mostrar «Semestre N».
- **Profesorado:** el prompt de la guía extrae además el papel («Coordinadora · Teoría») y las tutorías en texto corto
  (`Professor.role`, `officeHours`, en el JSON `papel` y `tutorias`). La revisión de la importación los muestra y la
  pestaña Guía añade «Escribir» (abre el correo; sin email no hay botón).
- **Asignatura en cinco pestañas:** Resumen · Temario · Evaluación · Apuntes · Guía (`?tab=summary|topics|evaluation|
  notes|guide`; uno desconocido, como el antiguo `progress`, abre el Resumen).
  - Resumen: «Concentrarme» + «Nueva entrega», lo próximo (tres como mucho) con «Calendario», «N repasos para hoy» +
    «Repasar» y «Lo que dominas» con su «?», «Practicar» («Crear preguntas» abre por ahora «Crear material»; la fase 4B
    lo cambia) y «De un vistazo» (temas hechos → Temario, tu nota → Evaluación).
  - Temario: marcar temas (el `PATCH …/teaching-guide/topics/{index}` de siempre).
  - Evaluación: «Cómo te evalúan: Continua / Global (solo examen)», «Tu nota» en puntos («3,1 de 4,5 puntos») y una
    sola frase según `GradeEstimate.outlook`, que decide el servidor: `NO_GRADES`, `NEEDS_AVERAGE` («te basta un X de
    media en lo que queda»), `ALREADY_PASSED` o `OUT_OF_REACH` (haría falta más de un 10 de media, o ya no queda nada y
    no se llegó al 5). Los puntos son `earnedPoints` y `possiblePoints` (peso × nota / 10).
  - Apuntes: lo de antes, solo cambia el nombre de la pestaña.
  - Guía: profesorado, bibliografía y datos en desplegables, «Volver a importar la guía».
  - Sin guía docente, Temario, Evaluación y Guía enseñan un vacío con lo que se gana y «Importar guía docente».
- **Palabras:** Flashcards → Tarjetas; Centro de generación → Crear material; Retención → Lo que dominas; Simulador de
  nota → Tu nota; Modalidad de evaluación → Cómo te evalúan; Fuentes → De dónde sale; No recuperable → sin segunda
  oportunidad (también en la descripción de la entrega que crea la guía); «plan docente» → «guía docente».

## Consecuencias

- `GET /subjects` hace dos lecturas más por petición (planes y repasos), ambas por lotes.
- El cliente no recalcula nada: ni qué repaso vence, ni los temas, ni la frase de la nota. El Resumen filtra por
  asignatura la cola de repasos vencidos que da el servidor (hasta 100).
- La guía de la primera vez de la asignatura (ADR 0049) señala ahora las pestañas, los repasos de hoy y practicar.
- Sin migración: `asignaturas_usuario_semestre` ya existía; ahora también la rellena la importación.
- «Repaso de hoy» está en un solo sitio del dominio (`StudyMaterial.isPendingReview`: vencido y no abandonado); el SQL
  recibe el estado excluido como parámetro.
- Una app anterior devuelve el borrador revisado sin `role` ni `officeHours`: al aplicar se recuperan de lo extraído
  (`TeachingGuide.keepingProfessorDetailsOf`, por nombre).
- Con el texto grande, las filas con botón (repasos, «Tu nota», pruebas, curso y cuatrimestre del formulario, filtro de
  la lista) se apilan, y «Añadir» de la barra pasa a icono con su nombre completo para el lector.
