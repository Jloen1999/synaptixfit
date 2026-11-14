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


## Inventario a cero (14 nov 2026, segunda tanda antes del APK)

Se resuelve todo lo que la tanda anterior dejó pendiente, salvo lo que necesita a alguien de fuera (el `Podfile` de iOS, que se genera en un Mac, y la revisión jurídica de los textos legales). Sin migraciones (V1059–V1062 siguen libres). La API solo gana un parámetro opcional (`zone` en `GET` y `PATCH /api/v1/me`); `openapi.yaml` lo regenera el propietario.

- **Simulacro sin «Abandonar».** En el servidor, abandonar cerraba la sesión sin nota ni XP, pero lo respondido ya contaba (cada respuesta queda como intento: ordena las preguntas y propone la nota del repaso). Como sí guarda, no es «Descartar»; y «Terminar» ya existe abajo. Se quita la ✕: la flecha de atrás deja el simulacro en curso para seguirlo después (se reanuda al volver, y un aviso lo dice al salir) y «Terminar» lo cierra con nota. El cliente deja de usar `POST /test-sessions/{id}/abandon` (el endpoint se mantiene por las apps anteriores).
- **«Necesita repaso» con la definición de la cola (vocabulario §3).** `RetentionMetrics.of(materiales, ahora)` cuenta como «Necesita repaso» todo material con su fecha SM-2 ya pasada (`StudyMaterial.isDue`, la misma regla que `findDue`, «Ver N repasos pendientes» y el aviso de repasos), esté como esté su dominio. Un fallado cuya fecha aún no ha llegado cuenta «En progreso». Antes contaba el estado SM-2 `NEEDS_REVIEW` (solo los fallados con nota 0-1), y la asignatura decía «Necesita repaso · 0» con tres repasos vencidos.
- **Definición única de «entreno hecho».** `CompletedWorkoutsSql` (adaptador de persistencia, SQL estándar, sin vista en la base de datos por el ADR 0012) une las sesiones terminadas y las actividades apuntadas de eventos de deporte hechos que no reflejan un día de rutina. La usan Inicio, Progreso, insignias, retos y las dos consultas del panel. Lo que difería se mantiene donde estaba: el mínimo de minutos (`COUNTED`, parámetro de `TrainingRewards`) solo en insignias y retos, y el panel sigue enseñando solo el esfuerzo de las sesiones de gimnasio. Resultado igual con datos reales (una actividad solo se apunta en deporte libre); deja fuera una fila suelta de un evento que ya no es deporte. `CompletedWorkoutsSqlIT` comprueba que los seis lectores cuentan lo mismo.
- **Edad en la zona del móvil.** `GET`/`PATCH /me` aceptan `zone` (como asignaturas) y la edad la calcula el caso de uso `GetAgeTodayUseCase` (la zona se decide en la aplicación, ADR 0012): cambia el mismo día que sale la tarjeta de cumpleaños de Inicio. Los días de clase ya usaban la zona del móvil (tanda 4b); el aviso de cumpleaños sigue la zona de la app, como todos los avisos.
- **Un icono, un significado:** `AppIcons.effort` (esfuerzo), `pace` (ritmo), `fastest` (tramo más rápido), `badge` (la medalla, solo insignias), `trendUp` (tendencia al alza), `bodyWeight` (peso), `bmi` (IMC), `explosive` (potencia y pliometría), `upNext` (próximo entreno, día fuerte), `appliesNow` (se aplica al momento), `activeUsers` (panel) y `decrease`/`increase` (selector − / +). El rayo queda solo para kcal y el velocímetro solo para el esfuerzo.
- **Una acción destacada por pantalla:** la tarjeta «¿Terminaste este bloque?» del Pomodoro lleva «Marcar como hecho» y, mientras está, el botón del reloj pasa a secundario; en Correr, con un entreno para hoy (`PlannedRunsToday.dueToday`), arriba va «Empezar: X» relleno y «Empezar a correr» pasa a secundario; la hoja de salir de la sesión pone el foco inicial en «Pausar y salir» (el botón relleno) y aparta «Descartar sesión».
- **Eliminar sin papelera en cada fila:** los entrenos de carrera se eliminan deslizando (`AppSwipeToDelete`, con la misma acción para el lector en su propio nodo) o con «Eliminar» en su editor, y siempre con «Deshacer» (vuelve a su sitio). `DeferredCommitMixin` reúne el «hacer al cerrarse el aviso» de entregas, entrenos de carrera y sugerencias; `showUndoSnack` cierra el aviso al salir de la pantalla, y `TrainingSectionBar` al cambiar entre Gimnasio y Correr (la ruta no cambia), así que su «Deshacer» nunca queda sin efecto. El calendario y el detalle de una carrera siguen con su propio aplazamiento (deshacen en el servidor, no al cerrar el aviso). «Borrar» pasa a «Eliminar» en los botones (y «Quitado del calendario» al quitar un evento).
- **`OpenSessionCard`:** «Descartar sesión» a un lado y «Terminar»/«Continuar» al otro.
- **Detalles:** «Más opciones» de la hoja de evento en una línea y con aire al final; una entrega desde el calendario vence a las 23:59, como desde Académico; «40 kg» no se parte en el panel de descanso; el lector dice «Reducir descanso»; con texto grande el saludo y la fecha de Inicio bajan a su línea (sin «Buenas noch…» ni la coma suelta en francés); el aviso de autoguardado del registro diario y «Días anteriores» son nodos separados para el lector; «Cuánto has entrenado» dice «Puntos de carga»; un solo texto «Día saltado»; «Ver N repasos» con la cola ya vacía lo avisa y recarga en vez de saltar a Académico; el contraste del segmento elegido está en `contrast_test`.
- **Datos de demo:** `tools/demo/shift_history.sql` mueve los repasos días enteros y conserva la hora que eligió el backend (ya no quedan a las 00:33). La demo publicada se corrige al volver a sembrarla.
- **Ejercicios sin consejos:** no se ha añadido ninguno al catálogo después de `V1033`; el ADR 0031 ya dice cómo generar la migración cuando se añadan.
- **Tests nuevos:** `RetentionMetricsTest`, `CompletedWorkoutsSqlIT` (también el evento de un día de rutina y la carrera con kcal y esfuerzo), `AccountServiceTest.ageCountsTodayInThePhoneZone`, `finishedCycle` y `dueToday` (`routine_rules_test`), `SessionDraftsCleaner.hasUnsent`, `adaptationRestored`, el descarte diferido de `SessionCompletedBloc` y de `RunHomeBloc`, `DeferredCommitMixin` y el aviso que se cierra al cambiar de apartado.
- **Tareas necesarias de un reto** usan `AppStepperField` (foco y valor anunciado); el simulacro reintenta de verdad tras un error.
