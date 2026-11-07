# Vocabulario y coherencia de la app

Fuente única de los términos que ve la persona y de cómo se relacionan las partes de la app. Si una pantalla, un aviso, un correo o un texto legal contradice este documento, se corrige la pantalla o se actualiza este documento en el mismo cambio. Aplica a los 4 idiomas (es, en, fr, pt-PT): se traduce la idea, no la palabra.

Regla general: palabras cotidianas, verbos en los botones, una acción útil siguiente y nunca un mensaje que diga «se puede recuperar» sin decir **dónde** (con botón para ir allí).

## 1. Términos

| Concepto (interno) | Se dice | No se dice | Notas |
|---|---|---|---|
| Bloque del calendario (`CalendarBlock`) | Según su tipo: «Estudio de Física», «Entreno», «Repaso», «Clase», «Examen», «Entrega», «Descanso», «Comida», «Sueño», «Personal: Dentista». Genérico o mezcla: **evento** («Añadir al calendario», «3 eventos hoy», «Mover evento») | «bloque» | Los nombres internos (`CalendarBlock`, `BLOCK_*`, tablas) no cambian |
| Tipo `PERSONAL` (nuevo) | «Personal» (trabajo, médico, recados, quedadas…) con nombre libre | «otro» | No suma carga de estudio, ni kcal de estudio, ni XP; sí sale en Tu día, avisos, resumen de la mañana y calendario exportado |
| Hoja de crear/editar evento | Pasos «¿Qué es?», «¿Cuándo?», «Repetir y aviso»; lo demás en «Más opciones». Tipos poco usados en «Más tipos». Un personal pide «Nombre» | «Detalles», «Vínculos» como títulos de sección | El aviso no es por evento: se dice que llega «con la antelación que elegiste en Ajustes › Avisos», con botón «Ajustar los avisos» |
| Hito de un reto (`Milestone`) | **tarea** («Tarea del reto») | — | «Tarea» se reserva para los retos |
| Actividad hecha fuera del plan (`PastActivity`, carrera, partido…) | **actividad** («Apuntar una actividad», «Tus actividades») | — | «Actividad» se reserva para lo ya hecho/registrado |
| Carrera grabada con GPS | «Carrera» (o «Paseo», «Bici» según el tipo); origen: «GPS de la app» / «Apuntada a mano» / «Marcada en el calendario» | «workout», «run» en español | Es una **actividad**. Un entreno de carrera planificado que se graba deja su evento del calendario como **Hecho** (lo marca el planificador, su dueño) |
| Entreno de carrera por pasos | «Entreno de carrera»: pasos «Calentar», «Correr», «Recuperar», «Enfriar»; series «6 × 800 m» | «intervalos» sin explicar | Se pone en el calendario como evento de tipo Entreno |
| Sesión de gimnasio (`TrainingSession`) | «Sesión» / «Entreno» | — | |
| Estados de lo planificado | **Por hacer** (aún no ha llegado o es hoy), **Hecho**, **Sin hacer** (ya pasó y no se hizo) | «Planificado», «pendiente» a secas, «completado» mezclado con «hecho» | Mismos tres estados en Inicio, planificador, avisos y Progreso |
| Marcar / desmarcar | «Marcar como hecho» / «Desmarcar» + «Deshacer» en el aviso | «Retirar», «revertir» | Desmarcar devuelve exactamente el XP dado (anti-farmeo existente) |
| Propuestas generadas por el sistema (IA o reglas) | «Te proponemos…», «Te sugerimos…», «Mejorar la propuesta», «Proponer la siguiente», indicando **en qué datos** se basa («Según tu perfil, tu material y tu carga de estudio») | «IA», «inteligencia artificial», «generado/refinado con IA», «motor de reglas», el icono de chispas (`auto_awesome`) | Se ven igual vengan de la IA o de las reglas (icono `lightbulb_outline`). Excepciones: textos legales/privacidad (obligatorio informar del proveedor) y panel de administración. Avisos de error: «Revisa que esté bien antes de guardarlo» |
| Progresión de cargas | «Siguiente paso: prueba 42,5 kg» + porqué con lo que hiciste («Hiciste 3 × 10 con 40 kg sin llegar al fallo») | «progresión» sin explicar, «RIR», «1RM» sin explicar | |
| Plan por fases | «Semana 2 de 8» + qué toca esta semana en una frase | «mesociclo» | |
| Pestaña de entrenamiento | **Entreno**, con apartados «Gimnasio» y «Correr» (y en el futuro «CrossFit») | «Rutinas» como nombre de pestaña | «Rutinas» sigue siendo el nombre de las rutinas dentro de Gimnasio |
| Fecha de nacimiento | «Fecha de nacimiento (opcional)»; la edad se calcula | pedir «edad» | Nunca en el perfil público. Se pide en el primer paso del onboarding y en «Editar cuenta»; quien ya dio su edad recibe la sugerencia «Pon tu fecha de nacimiento…», sin bloquearle (ADR 0036) |
| Cumpleaños (`BIRTHDAY`) | «¡Feliz cumpleaños, Ana!» (nombre de pila) | «aniversario» | Por la mañana; si ese día hay resumen de la mañana, va dentro de él. Tarjeta en Inicio solo ese día |
| Buscador (`AppSearchField`) | «Buscar asignaturas, apuntes, archivos y entregas»; sin resultados: «No hay resultados para «x»» + una acción («Crear apunte «x»») | «query», «filtrar» como botón | Un solo widget en toda la app; resultados agrupados por tipo y lo buscado resaltado |
| Agenda de la asignatura | «Próxima clase: lun 10:00 · Aula 2.3», «Entrega mañana», «Examen en 3 días», «Clase: lun y mié», «Aula habitual» | «sesión» para una clase | Relevancia visual: nombre en grande, lo próximo en medio, profesor en pequeño |
| Pomodoro | «Concentración» / «Descanso»; botones «Pasar al descanso» / «Volver a concentrarme», «Empezar a concentrarme» / «Empezar el descanso», «Empezar de cero»; arriba «Concentración 2 de 4 · luego 5 min de descanso» | icono «siguiente» sin texto, «Saltar fase», «Ciclo 2 de 4» | |
| Resumen de la mañana (`MORNING_SUMMARY`) | «Hoy: 2 estudios, 1 entreno, entrega de Física y 1 tarea de reto» | «digest», «resumen diario» | Solo si hay algo; incluye el recordatorio del registro diario de ese día (ADR 0035) |
| Antelación de los avisos | «Avisarme antes de…»: «15 min antes», «1 y 3 días antes», «La tarde anterior», «La mañana del día» | «lead time», «offset» | Opciones cerradas en Perfil › Ajustes › Notificaciones › «Más avisos» |

## 2. Dueños de cada pieza compartida

Una pieza compartida la cambia solo su dueño; los demás la usan por su contrato.

| Pieza | Dueño | Lo usan |
|---|---|---|
| Tipos de evento (`ActivityType`), hoja de crear/editar evento, estados Por hacer/Hecho/Sin hacer | Planificador | Inicio, avisos, retos, entreno, carrera |
| Plan de avisos (`ReminderPlanner`, `ReminderKind`, `ReminderOptions`) y resumen de la mañana | Notificaciones | Todos los módulos aportan datos por sus puertos |
| Actividades (`PastActivity`) y carreras GPS | Entreno (bienestar/actividades) | Inicio («Esta semana»), Progreso, racha, XP, carga física, retos |
| Perfil (fecha de nacimiento, modo de uso) | Perfil | Kcal (edad calculada), avisos (cumpleaños, `BirthdayPort`), Inicio (tarjeta de cumpleaños), filtros por modo de uso |
| Buscador común (`AppSearchField`, `AppHighlightedText`, `AppSearchEmpty`) | Diseño | Académico, apuntes compartidos, ejercicios, retos, rutinas de la comunidad |
| Agenda de la asignatura (`SubjectAgenda`) | Académico (lee clases y entregas del planificador por `SubjectAgendaPort`) | Tarjeta y detalle de la asignatura |
| Vocabulario (este documento) | Diseño | Todos |

## 3. Relaciones que deben cumplirse siempre

- Lo que se marca como hecho en un sitio aparece hecho en todos (Inicio, planificador, retos ligados, Progreso, XP, racha) y se puede desmarcar desde cualquiera de ellos con el mismo efecto.
- Una carrera grabada o apuntada cuenta igual que cualquier actividad: racha, XP, carga física (ACWR), retos ligados y resumen semanal. Un entreno de carrera planificado que se hace con GPS queda **hecho** en el calendario.
- Los avisos nunca se duplican: una misma cosa (entrega, evento, tarea de reto) da un solo aviso con todo lo relevante. Una tarea de reto toma la fecha de lo que la hace avanzar (su entrega, su siguiente evento o su día de rutina) y se nombra en el aviso y en la fila de Inicio de eso mismo; solo si nada la avisa tiene aviso propio. El resumen de la mañana y el registro diario de ese día llegan en un solo aviso.
- «Tu semana» de Inicio cuenta lo que se marca (todo menos descanso, comida y sueño; lo personal sí) con los tres estados, y cada día abre ese día en el planificador.
- El modo de uso (estudio / deporte / ambos) filtra lo que se ve, pero «Personal» se ve siempre. Cualquier cambio del perfil (nombre, foto, privacidad, modo de uso, fecha de nacimiento) se ve en todas las pantallas al guardar, sin reiniciar (`SessionBloc` + `DataChangeInterceptor`).
- Lo que se busca se encuentra igual con o sin tildes y mayúsculas, y cada resultado abre la misma pantalla que abriría desde su lista.
- Todo dato personal nuevo (fecha de nacimiento, rutas GPS) se borra al borrar la cuenta, sale en la exportación de la persona, no sale en la exportación del administrador si es de salud o ubicación, y figura en la política de privacidad y en `docs/06-ops/google-play.md`.
