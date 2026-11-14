# ADR 0041 — Menos texto, Progreso con titular y Ajustes por uso

- **Estado:** aceptado
- **Fecha:** 2026-11-14

## Contexto

Fase 4 (la última) del plan de claridad (`docs/05-design/vocabulario.md` §4). El propietario: «hay mucho texto en la aplicación que incluso a mí me causa carga cognitiva y me pierdo en mi propia aplicación». La auditoría encontró:

1. **Textos largos:** 168 textos en español de más de 90 caracteres y unas 17 900 palabras visibles. Muchos explicaban lo que el botón ya decía o repetían el mismo consejo en dos pantallas.
2. **Progreso:** 9 tarjetas seguidas sin ninguna acción; jerga («comodines», minutos ponderados por esfuerzo); «Estudios hechos: Sin plan», que no se entendía.
3. **Perfil y Ajustes:** un subtítulo en cada fila que repetía el título; Ajustes empezaba por la contraseña y dejaba los avisos en medio de lo legal; Perfil tenía una fila «Ajustes» además del engranaje de la barra.
4. **Pendientes de las fases 1–3:** la regla «la tercera respuesta guarda» estaba escrita dos veces (y distinta) en dos páginas; el sentido de las escalas vivía en un widget; el estrés salía marcado en «Algo» sin contestarlo; la fatiga se enseñaba en cifras; «Añadir detalles» perdía lo ya contestado; saltar un día pedía confirmación aunque se puede recuperar.

## Decisión

### Menos texto

- Cada explicación cabe en **una línea** o va a un «?» (`AppHelpToggle`). Fuera los textos que repiten lo que dice el botón y los subtítulos de fila que repiten el título.
- Se quitaron del todo las claves sin uso (62). Los textos legales y los mensajes de error del catálogo no cambian de sentido: solo se acortan.
- Resultado en español: textos de más de 90 caracteres, de 168 a 69 (la mayoría que quedan son plurales ICU, instrucciones paso a paso o consentimientos); palabras, de 17 917 a unas 16 300.

### Progreso › Resumen

- **Arriba, un titular** (`WeekHeadlineCard`): «Esta semana: 4 h de estudio · 3 entrenos», según el modo de uso. Debajo, el nivel con su barra de XP (con «?» a «Cómo se gana XP») y la racha en una línea («Racha: 5 días · récord 36 días»).
- **Lo que sigue:** «Ver N repasos pendientes» (la única acción destacada) y la próxima insignia.
- **El resto, plegado en «Ver más cifras»:** «Tu equilibrio», la racha con sus hitos y días libres, «Tu estudio», por asignatura, la analítica, la carga física y la comunidad.
- Las horas salen de `StudyWeek.studyHours` y los entrenos de la semana que el servidor declara actual (`WeeklyAnalytics.toWeek` → `currentWeek`); el cliente no calcula semanas. Si una cifra no carga, el titular lo dice y ofrece «Reintentar»; con la semana a cero, «Añadir al calendario».
- **Sin jerga:** «comodines» → «días libres» (con «?»: se gana uno cada 7 días seguidos); la carga física dice «cuanto más alta la barra, más duro fue el día»; «Estudios hechos: Sin plan» → «Estudios del calendario: Ninguno planificado» / «6 de 8 hechos».
- Los hitos de racha alcanzados los dice el servidor (`reachedMilestones`); el cliente ya no los deduce del récord.

### Perfil y Ajustes

- **Ajustes, por frecuencia de uso:** «Avisos y permisos» (preferencias de notificaciones y permisos del móvil), Apariencia, Idioma, Cuenta (contraseña, editar cuenta y cerrar sesión) y, al final, «Privacidad y datos» (política, condiciones, datos de salud, exportar y eliminar la cuenta). Sin subtítulos.
- **Perfil:** cuenta, lo social, perfil físico y académico («Elegir asignaturas» e «Importar desde tu matrícula» en una sola tarjeta). Ajustes solo desde el engranaje (un camino por destino).

### Registro diario: la regla en un solo sitio

- `CheckInScale` y `CheckInQuestion` (dominio) dicen el sentido de cada escala; `CheckInAnswers` guarda lo contestado y la regla `savesOnLastAnswer` (la primera vez del día y sin detalles, la tercera respuesta guarda).
- La aplican los blocs (`QuickCheckInBloc` y `CheckInBloc`, evento `answered`): cuando toca guardar suben `saveRequest` y la página solo pide el permiso de salud y envía.
- «Añadir detalles» lleva lo ya contestado en la dirección (`TrainingPaths.checkInDetailsWith`).
- El estrés no sale marcado hasta que se contesta (`stressAnswered`). La fatiga se dice en palabras (icono y frase), sin cifra.

### Lo reversible no pregunta

Saltar un día de rutina (en Gimnasio y en la rutina) ya no se confirma: aviso «Día saltado» con «Deshacer» durante la ventana de deshacer (`TrainingHomeEvent.dayUnskipped`, `UnskipRoutineDayUseCase`). Siguen confirmándose «Quitar ejercicio» (con el verbo «Quitar del plan»), adelantarse saltando días anteriores y cerrar sesión.

### Otros pendientes de diseño

- Tokens `onSuccess`/`onWarning` para el ✓ de la serie hecha (contraste AA en claro y oscuro).
- La barra de la sesión libre (`_FreeBottomBar`) ya no arrastra el código de rutina que no se usaba.
- Pista «Corregir» para el lector en la fila de serie.
- Cada chip de la franja de entregas abre su entrega (la lista ya está en «Entregas y exámenes»).
- Una asignatura archivada se nombra «Asignatura archivada» en los desplegables.
- Las notas del registro usan `AppTextField`.
- La cuadrícula del calendario deja hueco al final para el botón flotante.
- El aviso «sin GPS» de la web va en tono informativo (`AppMessageTone.info`).
- Una línea sobre la primera entrega dice que se borra deslizando.
- Una sola acción destacada en Gimnasio y en la rutina: solo el día que toca va relleno; «Aplicar», «Continuar/Terminar» y «Guardar cambios» van como secundarios.
- Sin porcentajes en la adaptación de la sesión («Hoy harás menos series»).
- La barra de pestañas limita el tamaño de las etiquetas a 1,3× y recupera el tooltip; en francés, «Sport» y «Progrès».
- La insignia «Planificador nato» cuenta solo las semanas que dieron la XP de planificar (`xp_planificacion_otorgado`), como dice el ADR 0038.

## Consecuencias

- Menos texto que leer en toda la app, en los 4 idiomas.
- Progreso abre con lo esencial y una acción; el detalle sigue a un toque.
- La regla del registro diario y el sentido de las escalas están en un solo sitio y tienen test.
- Sin migraciones ni cambios de API. `openapi.yaml` lo regenera el propietario.
- Pendientes: un test de integración de la consulta de «Planificador nato» con un plan sin XP; «Repasar» desde Progreso abre Académico, no la cola de repasos (haría falta que el resumen trajera los ids).

## Tanda de cierre (14 nov 2026, antes del APK)

Repaso de todo lo pendiente de los ADR 0030–0041, de los planes de claridad y de una revisión visual en producción. Sin migraciones (V1059–V1062 siguen libres) ni campos nuevos en la API.

- **«Ver N repasos pendientes» abre la cola en un toque.** El resumen solo trae cuántos hay; al tocar, `ProgressOverviewBloc` pide los materiales con repaso (`GetDueStudyMaterialsUseCase`) y abre el primero con el resto en `?queue=` (la misma cola que «Repasar todos»). Si ya no queda ninguno, Académico.
- **Lo reversible no pregunta, también aquí:**
  - «Hacerla completa» (sesión adaptada): se hace y el aviso lleva «Deshacer», que vuelve a las series adaptadas.
  - Adelantarse a un día de la rutina: sin diálogo. Los días anteriores solo se saltan al terminar la sesión y quedan con «Recuperar» en la rutina; descartar la sesión no salta nada.
  - «Cerrar sesión»: solo confirma si hay en el teléfono algo que el servidor no tiene (series sin conexión, una carrera en curso o en cola), porque cerrar sesión lo borra (`HasUnsentDataUseCase`). Si no, cierra al momento.
  - Descartar una sugerencia de entreno: desaparece con «Deshacer» y se descarta en el servidor al cerrarse el aviso o al salir de la pantalla. Aplicarla lleva «Ver» a la rutina.
- **Las carreras y actividades cuentan en todas partes (vocabulario §3).** Las insignias (entrenos y días de entreno) y el panel de administración (plataforma y ficha de cada persona) suman las actividades hechas, con las mismas filas que Inicio, Progreso y los retos. Correr un entreno planificado antes de su hora pasa su reto y su tarea a la actividad nueva, que la sigue haciendo avanzar. Volver a marcar desde el calendario un evento con actividad usa sus minutos reales para la carga física (`ActivityMinutesPort`).
- **Reglas fuera de la interfaz:** el botón de «Tu día» y lo que toca ahora (`TodayAction.of`, `nextUp`) y el ciclo terminado (`finishedCycle`) en el dominio del cliente; el nivel cognitivo lo dice `CognitiveState` en el servidor, no el DTO.
- **Detalles:** «Deshacer» de una entrega funciona aunque el filtro «Por hacer» la haya sacado de la lista; el foco vuelve a la cabecera del día al saltarlo; el registro diario usa `AppSegmentedChoice`; racha (llama), kcal (rayo) y tramo más rápido tienen iconos propios en `AppIcons`; la entrega de tipo «otro» deja la bandera a las tareas de reto; «Descartar sesión» es rojo en la tarjeta y en la hoja; «pendiente» a secas pasa a «por hacer».
- **Barra de pestañas:** `ShellNavigationBar`, con un test en los 4 idiomas a 360 px y texto al 200 %.
- **Revisión visual en producción** (390 px en español, 360 px en francés y texto al 200 %):
  - Plurales en francés y portugués: su regla de plural mete el 0 en «one» y con 0 salía el texto de 1 («1 entraînement»). Cada plural con `=1{…}` sin el número lleva su `=0{…}`; un test lo comprueba.
  - Una dirección desconocida abre `NotFoundPage` («Ir a Inicio») en vez de la página de error de go_router en inglés.
  - Al volver a marcar una serie se cierra el aviso «Serie desmarcada · Deshacer» (dos «Deshacer» contradictorios).
  - Texto grande: la barra de pestañas ajusta sus etiquetas al hueco (token `largeTextScale`, el mismo umbral que `largeText`), las pestañas de Progreso se desplazan y el eje de horas y la cabecera del calendario crecen con el texto.
  - Retos con un solo estado («Hecho», «Vencido») en los 4 idiomas y sin repetirlo en la tarjeta; un solo «Crear entreno» en Correr; el Pomodoro sin empezar solo enseña «Empezar a concentrarme»; «Tocaba el lun 3 nov» en vez de un chip cortado; kilos con la coma del idioma; repaso vencido dicho como «Tocaba el …».
- **Reto heredado solo dentro de su periodo:** la actividad que sustituye a un evento planificado hereda su reto y su tarea solo si cae dentro del periodo del reto (como cualquier bloque de reto); si no, se apunta sin reto en vez de fallar la subida. La actividad se guarda antes de completar el evento, así la carga física sale ya con los minutos reales.
- Siguen fuera (funciones nuevas): CrossFit/WOD, Strava, Health Connect, nutrición y la publicación en Google Play.

