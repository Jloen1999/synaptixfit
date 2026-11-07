import 'package:flutter/material.dart';

/// Mapa central de iconos de la app: la misma acción lleva el mismo icono en
/// todas las pantallas. Se usan iconos de significado común (papelera = borrar,
/// lápiz = editar, más = añadir, campana = avisos) y todo botón que solo lleve
/// icono va con `tooltip` (que también es lo que oye el lector de pantalla).
abstract final class AppIcons {
  // Acciones sobre un elemento.
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_outlined;

  /// Borrar algo guardado (con confirmación o «Deshacer»).
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

  // Ir a otro sitio.
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData previous = Icons.chevron_left_rounded;
  static const IconData next = Icons.chevron_right_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData calendar = Icons.calendar_month_rounded;
  static const IconData today = Icons.today_rounded;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData friends = Icons.people_alt_outlined;
  static const IconData community = Icons.forum_outlined;
  static const IconData sharedNotes = Icons.groups_outlined;
  static const IconData focusTimer = Icons.timer_outlined;
  static const IconData howTo = Icons.ondemand_video_rounded;
  static const IconData help = Icons.help_outline_rounded;

  /// Lo que propone la app (IA o reglas, se ven igual: vocabulario).
  static const IconData proposal = Icons.lightbulb_outline_rounded;

  // Pestañas (contorno sin elegir, relleno elegida).
  static const IconData tabHome = Icons.home_outlined;
  static const IconData tabHomeSelected = Icons.home_rounded;
  static const IconData tabAcademic = Icons.school_outlined;
  static const IconData tabAcademicSelected = Icons.school_rounded;
  static const IconData tabTraining = Icons.fitness_center_outlined;
  static const IconData tabTrainingSelected = Icons.fitness_center_rounded;
  static const IconData tabChallenges = Icons.flag_outlined;
  static const IconData tabChallengesSelected = Icons.flag_rounded;
  static const IconData tabProgress = Icons.insights_outlined;
  static const IconData tabProgressSelected = Icons.insights_rounded;
}
