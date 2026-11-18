import 'package:flutter/material.dart';

/// Mapa central de iconos de la app: la misma acción lleva el mismo icono en
/// todas las pantallas. Se usan iconos de significado común (papelera = eliminar,
/// lápiz = editar, más = añadir, campana = avisos) y todo botón que solo lleve
/// icono va con `tooltip` (que también es lo que oye el lector de pantalla).
abstract final class AppIcons {
  // Acciones sobre un elemento.
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_outlined;

  /// Eliminar algo guardado (con confirmación o «Deshacer»).
  static const IconData delete = Icons.delete_outline_rounded;

  /// Quitar una fila de una lista que se está editando (serie, paso, tarea).
  static const IconData remove = Icons.remove_circle_outline_rounded;

  /// Cerrar una hoja o pantalla, o vaciar un campo.
  static const IconData close = Icons.close_rounded;
  static const IconData undo = Icons.undo_rounded;
  static const IconData share = Icons.share_rounded;

  /// Copiar algo de otra persona a lo tuyo («Añadir a mis rutinas/retos»).
  static const IconData copyToMine = Icons.library_add_outlined;

  /// Hacer una copia de algo tuyo («Duplicar»).
  static const IconData duplicate = Icons.content_copy_rounded;
  static const IconData moveUp = Icons.arrow_upward_rounded;
  static const IconData moveDown = Icons.arrow_downward_rounded;
  static const IconData archive = Icons.archive_outlined;
  static const IconData unarchive = Icons.unarchive_outlined;

  /// Reportar contenido. No es una bandera: la bandera es la de Retos.
  static const IconData report = Icons.report_outlined;
  static const IconData block = Icons.block_rounded;
  static const IconData send = Icons.send_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filters = Icons.tune_rounded;
  static const IconData clearFilters = Icons.filter_alt_off_rounded;
  static const IconData export = Icons.file_download_outlined;
  static const IconData openExternal = Icons.open_in_new_rounded;
  static const IconData markAllRead = Icons.done_all_rounded;
  static const IconData leave = Icons.logout_rounded;

  /// Acción «Marcar como hecho» (botón); el estado ya hecho es [done].
  static const IconData markDone = Icons.task_alt_rounded;

  /// Estado «Hecho» (casilla marcada, pastilla o insignia de algo terminado).
  static const IconData done = Icons.check_circle_rounded;

  /// Estado «Por hacer» (casilla sin marcar); se cambia por [done] al marcar.
  static const IconData todo = Icons.radio_button_unchecked_rounded;

  /// Prioridad de algo (asignatura, tarea). No es la bandera de Retos.
  static const IconData priority = Icons.priority_high_rounded;

  // Tipos de evento académico (mismo dibujo en Inicio, planificador y
  // Académico).
  static const IconData exam = Icons.quiz_outlined;
  static const IconData delivery = Icons.assignment_outlined;
  static const IconData presentation = Icons.slideshow_outlined;

  /// Entrega de tipo «otro»: la bandera ya marca las tareas de reto.
  static const IconData deadlineOther = Icons.event_note_outlined;

  /// Mostrar la contraseña escrita (ojo abierto).
  static const IconData showPassword = Icons.visibility_outlined;

  /// Ocultar la contraseña escrita (ojo tachado).
  static const IconData hidePassword = Icons.visibility_off_outlined;

  /// Ver cómo queda un texto antes de guardarlo (vista previa).
  static const IconData preview = Icons.preview_outlined;

  /// Algo que se puede ver pero no cambiar (solo lectura).
  static const IconData readOnly = Icons.lock_outline_rounded;

  /// Algo que no ven los demás o que no se muestra (oculto).
  static const IconData hidden = Icons.visibility_off_outlined;

  /// Cuánto dura algo (minutos de una sesión, de una actividad).
  static const IconData duration = Icons.schedule_rounded;

  // Ir a otro sitio.
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData previous = Icons.chevron_left_rounded;
  static const IconData next = Icons.chevron_right_rounded;
  static const IconData history = Icons.history_rounded;

  /// Entrenar sin rutina (sesión libre). No es `kcal` (el rayo).
  static const IconData freeSession = Icons.play_circle_outline_rounded;
  static const IconData calendar = Icons.calendar_month_rounded;
  static const IconData today = Icons.today_rounded;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData friends = Icons.people_alt_outlined;
  static const IconData community = Icons.forum_outlined;
  static const IconData sharedNotes = Icons.groups_outlined;
  static const IconData focusTimer = Icons.timer_outlined;

  /// Fases del temporizador: concentración y descanso.
  static const IconData focusPhase = Icons.psychology_rounded;
  static const IconData breakPhase = Icons.free_breakfast_rounded;
  static const IconData howTo = Icons.ondemand_video_rounded;
  static const IconData help = Icons.help_outline_rounded;

  /// Más detalles de algo pequeño (p. ej. los créditos de una foto). No es la
  /// «?» de las ayudas opcionales.
  static const IconData info = Icons.info_outline_rounded;

  /// Lo que propone la app (IA o reglas, se ven igual: vocabulario).
  static const IconData proposal = Icons.lightbulb_outline_rounded;

  /// Racha (días seguidos): la llama, solo para la racha.
  /// Empezar (una sesión, un entreno).
  static const IconData start = Icons.play_arrow_rounded;

  /// Reto (Progreso › Retos y sus plantillas).
  static const IconData challenge = Icons.flag_outlined;

  static const IconData streak = Icons.local_fire_department_rounded;

  /// Kilocalorías gastadas: energía, distinta de la llama de la racha.
  static const IconData kcal = Icons.bolt_rounded;

  /// Tramo más rápido de una carrera.
  static const IconData fastest = Icons.fast_forward_rounded;

  /// Insignia (la medalla, solo para insignias).
  static const IconData badge = Icons.military_tech_outlined;

  /// Algo que va a más (tendencia al alza, progresión de cargas).
  static const IconData trendUp = Icons.trending_up_rounded;

  /// Restar y sumar en un selector − / +.
  static const IconData decrease = Icons.remove_rounded;
  static const IconData increase = Icons.add_rounded;

  /// Esfuerzo percibido (RPE) de una sesión o actividad.
  static const IconData effort = Icons.speed_rounded;

  /// Ritmo de una carrera (minutos por kilómetro).
  static const IconData pace = Icons.av_timer_rounded;

  /// Peso corporal.
  static const IconData bodyWeight = Icons.monitor_weight_outlined;

  /// Índice de masa corporal.
  static const IconData bmi = Icons.balance_rounded;

  /// Ejercicio o meta explosiva (potencia, pliometría).
  static const IconData explosive = Icons.rocket_launch_outlined;

  /// Lo siguiente que toca (próximo entreno, día fuerte).
  static const IconData upNext = Icons.upcoming_outlined;

  /// Estado «En curso» (sesión abierta, día empezado).
  static const IconData inProgress = Icons.timelapse_rounded;

  /// «Con retraso»: tocaba antes y aún no está hecho (no es [duration]).
  static const IconData overdue = Icons.event_busy_outlined;

  /// Racha en pausa (ADR 0042).
  static const IconData paused = Icons.pause_circle_outline_rounded;

  /// Un cambio que se aplica al momento, sin pulsar «Guardar».
  static const IconData appliesNow = Icons.published_with_changes_rounded;

  /// Personas activas (panel de administración).
  static const IconData activeUsers = Icons.how_to_reg_outlined;

  // Pestañas (contorno sin elegir, relleno elegida).
  static const IconData tabHome = Icons.home_outlined;
  static const IconData tabHomeSelected = Icons.home_rounded;
  static const IconData tabCalendar = Icons.calendar_month_outlined;
  static const IconData tabCalendarSelected = Icons.calendar_month_rounded;
  static const IconData tabAcademic = Icons.school_outlined;
  static const IconData tabAcademicSelected = Icons.school_rounded;
  static const IconData tabTraining = Icons.fitness_center_outlined;
  static const IconData tabTrainingSelected = Icons.fitness_center_rounded;
  static const IconData tabProgress = Icons.insights_outlined;
  static const IconData tabProgressSelected = Icons.insights_rounded;

  // Fotos (apuntes y foto de perfil, ADR 0051 y 0052).
  static const IconData camera = Icons.photo_camera_rounded;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData imageUnavailable = Icons.image_not_supported_outlined;
  static const IconData zoomIn = Icons.zoom_in_rounded;
  static const IconData zoomOut = Icons.zoom_out_rounded;
}
