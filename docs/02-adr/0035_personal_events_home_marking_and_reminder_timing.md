# ADR 0035 — Eventos personales, marcar desde Inicio, «Tu semana» con tres estados y avisos a elección

- **Estado:** aceptado
- **Fecha:** 2026-11-07

## Contexto

1. El planificador solo servía para estudiar y entrenar: el médico, el trabajo o un recado no tenían sitio, y la hoja de crear un evento («bloque») era una lista larga de campos poco clara.
2. En Inicio no se podía marcar nada como hecho ni deshacerlo: había que ir al planificador. La gráfica «Tu semana» hablaba de «Planificado» y no dejaba claro qué faltaba ni qué se quedó sin hacer.
3. Una tarea de reto ligada a una entrega o a unos eventos no se veía en el día que tocaba, ni tenía aviso propio.
4. Los avisos tenían antelaciones fijas (15 min, 3 días y 1 día) y no había un resumen de lo que trae el día.
5. «Ver en el planificador» de una tarea de reto abría «Entregas y exámenes» sin decir cuál (fallo 10).

## Decisión

- **Tipo `PERSONAL`** (`ActivityType.PERSONAL`, código `personal`; `V1045` amplía `ck_horarios_tipo_actividad`). Su nombre libre va en los temas y es obligatorio (`VALIDATION_ERROR` en `topics`). No da XP, no es cognitivo, no cuenta como estudio (sin carga ni kcal de estudio), se ve con cualquier modo de uso, se marca como hecho y, si pasa sin marcar, queda «Sin hacer». Cuenta en el plan de la semana (`ActivityType.countsInWeekPlan`), sale en avisos, en el resumen de la mañana y en el calendario exportado (ICS), y no entra en el aviso de «eventos sin hacer» de Inicio (anima a recuperar estudio o entreno, no a reprochar un recado). Se reutiliza la columna `temas` en vez de crear `titulo`: es texto libre opcional de 1000 caracteres y ya sale como título en la línea de tiempo y el ICS.
- **Hoja de evento por pasos** en el cliente: «¿Qué es?», «¿Cuándo?» (con atajos de duración) y «Repetir y aviso»; lo avanzado, solo si aplica, en «Más opciones». El servidor no cambia: mismas reglas y códigos.
- **«Tu semana» con los tres estados del vocabulario**: Hecho (relleno), Sin hacer (rayado) y Por hacer (hueco), título «12 de 18 hechos esta semana» y lectura de pantalla igual a lo que se ve. Por hacer = planificado − hecho − sin hacer, con los números del servidor. Tocar un día abre ese día en el planificador (`/planner?week=…&day=…`).
- **Marcar desde Inicio**: estudio, repaso, evento personal y entrega llevan casilla «Marcar como hecho» con «Deshacer»; usan los mismos casos de uso que el planificador (`SetBlockCompletion`, `SetDeadlineCompletion`), así que XP (y su devolución exacta), racha y retos ligados se comportan igual en todas partes. Un entreno de rutina lleva «Empezar»; uno suelto, «Ya lo hice» (lo marca como hecho). Lo que aún no ha empezado no se marca (`BLOCK_IN_FUTURE`): el cliente lo explica con el estado que manda el servidor.
- **Tareas de reto con fecha** (`DatedTask`, en el dominio de retos): la fecha sale de su ancla — la entrega o examen ligado (fecha límite), el siguiente evento asignado sin hacer, o el día de rutina ligado (su evento de entreno si está en el calendario; si no, el día previsto). Inicio dice en cada evento qué tarea adelanta (`TodayEvent.tasks`, `TaskMention`) por el vínculo del propio evento (su tarea asignada o las tareas ligadas a esa entrega), también después de marcarlo, en lugar de repetirla aparte.
- **Avisos** (`ReminderPlanner`):
  - **Sin duplicados**: el aviso de una entrega o de un evento menciona las tareas que avanzan con él (`ReminderPlan.Item.tasks`). Solo una tarea sin aviso propio de su ancla tiene el suyo (`CHALLENGE_TASK`), la tarde anterior a las 18:00 o la mañana del día; al tocarlo se abre el reto. Categoría de hitos.
  - **Eventos personales** (`PERSONAL_EVENT`): sin categoría propia; se avisan si la persona admite alguna (`admitsAny`), también en época de exámenes, porque son sus citas.
  - **Resumen de la mañana** (`MORNING_SUMMARY`): a la hora elegida (8:00 por defecto, en punto o y media entre 5:00 y 12:00), solo si ese día hay algo después de esa hora; cuenta cada cosa una vez (una tarea que va con un evento ya contado no se suma). Respeta el silencio y cuenta en el límite diario. Al tocarlo se abre Inicio.
  - **Coordinación con el registro diario**: el resumen y el aviso del registro diario son los dos avisos de la mañana. Si un día hay resumen, el registro va dentro de él (`summary.checkIn`) y no llega aparte; sin resumen ese día, el registro llega solo a su hora. Se eligió fusionar en vez de separar por horas porque dos avisos seguidos por la mañana se perciben como ruido, el límite diario es pequeño y ambos llevan a Inicio.
  - **Antelación a elección** (`ReminderOptions`, `V1046`, `GET`/`PUT /notifications/reminder-options`): eventos y clases 5, 15, 30 o 60 min; entregas y exámenes uno o varios de 1, 3 y 7 días; tareas de reto la tarde anterior o la mañana del día; hora del resumen o apagado. Se eligen en Perfil › Ajustes › Notificaciones › «Más avisos». Opciones cerradas validadas en el dominio (`REMINDER_OPTIONS_INVALID`); el cliente copia las listas solo para pintarlas. Con el resumen apagado no se guarda hora: al encenderlo sin hora vuelve a las 8:00. Los valores por defecto repiten el comportamiento anterior. El `PUT` es parcial: una app anterior que solo manda los interruptores no borra lo elegido. Las tareas de reto y el resumen solo miran retos en curso del ámbito que usa la persona; una tarea de la mañana que vence antes del resumen conserva su aviso propio.
  - **Cumpleaños** (preparado, no implementado): el móvil descarta los `kind` que no conoce, así que un `BIRTHDAY` futuro, alimentado por la fecha de nacimiento del perfil por un puerto propio y sumado como los avisos de bienestar, no rompe las versiones anteriores.
- **Fallo 10**: «Ver en el planificador» abre la entrega concreta (`/planner/deadlines?focus=<id>`), que va la primera y destacada aunque esté en otra página, vencida hace más de 30 días o ya hecha. Lo mismo al tocar una entrega en la agenda de Inicio.
- **Vocabulario**: «bloque» desaparece de los textos que ve la persona (4 idiomas, avisos, correo semanal e insignia `V1047`); se nombra por su tipo o «evento» (`docs/05-design/vocabulario.md`). Los textos legales se dejan para su próxima versión.

## Consecuencias

- El plan de avisos lee siempre los retos activos y los eventos de la ventana cuando la persona admite alguna categoría: una lectura más, a cambio de no duplicar avisos.
- Un APK anterior sigue funcionando: campos nuevos opcionales, tipos de aviso desconocidos ignorados y `PUT` parcial.
- `docs/03-api/openapi.yaml` queda pendiente de regenerar (DTO de Inicio, plan y opciones de avisos).
- Pendiente: los textos legales que aún dicen «bloques de estudio» cambiarán con la próxima versión de la política.
