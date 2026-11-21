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

  /// Marca de «todo hecho» dentro de un círculo ya relleno («Tu semana»).
  static const IconData check = Icons.check_rounded;

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

  /// Asignatura de un evento o de una entrega (el birrete de Académico).
  static const IconData subject = Icons.school_outlined;

  /// Rutina de entreno (un evento que es un día de rutina).
  static const IconData routine = Icons.fitness_center_rounded;

  /// Lugar de algo (aula, gimnasio).
  static const IconData location = Icons.place_outlined;

  /// Nota o temas escritos a mano en un evento.
  static const IconData note = Icons.notes_rounded;

  /// Aviso de algo que conviene revisar (no es un error).
  static const IconData warning = Icons.warning_amber_rounded;

  /// Dos eventos que coinciden a la misma hora (choque de horario).
  static const IconData conflict = Icons.compare_arrows_rounded;

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

  /// Repasar (repaso espaciado): aviso de Académico, tarjeta y Resumen.
  static const IconData review = Icons.replay_rounded;

  /// Escribir un correo (profesorado de la guía docente).
  static const IconData email = Icons.mail_outline_rounded;

  /// Importar la guía docente (PDF de la asignatura).
  static const IconData importGuide = Icons.description_rounded;

  /// Más detalles de algo pequeño (p. ej. los créditos de una foto). No es la
  /// «?» de las ayudas opcionales.
  static const IconData info = Icons.info_outline_rounded;

  /// Lo que propone la app (IA o reglas, se ven igual: vocabulario).
  static const IconData proposal = Icons.lightbulb_outline_rounded;

  /// Empezar (una sesión, un entreno).
  static const IconData start = Icons.play_arrow_rounded;

  /// Reto (Progreso › Retos y sus plantillas).
  static const IconData challenge = Icons.flag_outlined;

  /// Racha (días seguidos): la llama, solo para la racha.
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

  /// Pestaña «Tú» (antes «Progreso», ADR 0061): tu progreso, retos,
  /// insignias y comunidad.
  static const IconData tabYou = Icons.person_outline_rounded;
  static const IconData tabYouSelected = Icons.person_rounded;

  /// Tú › Resumen (la semana, el nivel y la racha).
  static const IconData progressSummary = Icons.insights_rounded;

  /// Tú › Comunidad (el grupo: distinto de [friends], que es tu lista).
  static const IconData communityTab = Icons.diversity_3_outlined;

  /// Retos que publica la comunidad («De otros», «Retos de otros»).
  static const IconData communityChallenges = Icons.public_rounded;

  /// Invitaciones de amigos por contestar.
  static const IconData invitation = Icons.mail_outline_rounded;

  /// Una sección que no se pudo cargar (sin conexión o error).
  static const IconData unavailable = Icons.cloud_off_rounded;

  /// Desplegar y plegar un bloque («Ver más cifras» / «Ver menos»).
  static const IconData expand = Icons.expand_more_rounded;
  static const IconData collapse = Icons.expand_less_rounded;

  /// Una lista de ejercicios (rutina compartida en el muro).
  static const IconData routineList = Icons.list_alt_rounded;

  // Perfil (tarjetitas y fichas «Físico» y «Académico», ADR 0061).
  static const IconData onboarding = Icons.flag_circle_rounded;
  static const IconData birthday = Icons.cake_outlined;
  static const IconData admin = Icons.admin_panel_settings_outlined;
  static const IconData bodyHeight = Icons.height_rounded;
  static const IconData activityLevel = Icons.directions_run_rounded;
  static const IconData goal = Icons.flag_outlined;
  static const IconData weightHistory = Icons.show_chart_rounded;
  static const IconData university = Icons.account_balance_outlined;
  static const IconData semester = Icons.timeline_rounded;
  static const IconData modality = Icons.location_city_outlined;
  static const IconData degrees = Icons.workspace_premium_outlined;
  static const IconData pickSubjects = Icons.playlist_add_check_rounded;
  static const IconData enrollment = Icons.upload_file_rounded;

  // Fotos (apuntes y foto de perfil, ADR 0051 y 0052).
  static const IconData camera = Icons.photo_camera_rounded;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData imageUnavailable = Icons.image_not_supported_outlined;
  static const IconData zoomIn = Icons.zoom_in_rounded;
  static const IconData zoomOut = Icons.zoom_out_rounded;
}
