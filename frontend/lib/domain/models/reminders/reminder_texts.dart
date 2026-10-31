import '../../enums/reminder_kind.dart';

/// Textos de los avisos locales. El dominio no conoce idiomas: presentation
/// implementa esta interfaz con sus traducciones y la pasa al sincronizar.
abstract interface class ReminderTexts {
  /// Nombre del canal de notificaciones (visible en los ajustes de Android).
  String get channelName;

  String dueReviewsTitle(int count);

  String dueReviewsBody(int count);

  String blockTitle(ReminderKind kind);

  /// [name] es el título del bloque o su asignatura (puede faltar);
  /// [start] llega en hora local.
  String blockBody(ReminderKind kind, String? name, DateTime start);

  String get weeklySummaryTitle;

  String get weeklySummaryBody;

  /// Examen o entrega que vence en [daysBefore] días.
  String deadlineTitle(ReminderKind kind, int daysBefore);

  /// [name] es el título de la entrega (puede faltar); [due] en hora local.
  String deadlineBody(ReminderKind kind, String? name, DateTime due);
}
