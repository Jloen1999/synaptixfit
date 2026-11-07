import '../../enums/reminder_kind.dart';
import 'reminder_plan.dart';

/// Textos de los avisos locales. El dominio no conoce idiomas: presentation
/// implementa esta interfaz con sus traducciones y la pasa al sincronizar.
abstract interface class ReminderTexts {
  /// Nombre del canal de notificaciones (visible en los ajustes de Android).
  String get channelName;

  String dueReviewsTitle(int count);

  String dueReviewsBody(int count);

  String blockTitle(ReminderKind kind);

  /// [name] es el título del evento o su asignatura (puede faltar: entonces
  /// va un nombre de reserva según el tipo); [start] llega en hora local.
  String blockBody(ReminderKind kind, String? name, DateTime start);

  /// Evento personal: «Dentista a las 17:00».
  String personalTitle(String? name, DateTime start);

  /// Cuánto falta para que empiece el evento personal ([minutes], calculado
  /// con la hora del aviso: la antelación la elige la persona).
  String personalBody(int minutes);

  String get weeklySummaryTitle;

  String get weeklySummaryBody;

  /// Examen o entrega que vence en [daysBefore] días.
  String deadlineTitle(ReminderKind kind, int daysBefore);

  /// [name] es el título de la entrega (puede faltar); [due] en hora local.
  String deadlineBody(ReminderKind kind, String? name, DateTime due);

  /// Avisos de seguimiento (día de rutina atrasado, sesión abierta, reto que
  /// vence): título y cuerpo con el nombre (rutina o reto) si lo hay.
  String followUpTitle(ReminderKind kind);

  String followUpBody(ReminderKind kind, String? name);

  /// Tarea de reto con fecha: «Mañana: Repasar tema 3 · reto Aprobar Física».
  /// [daysLeft] 0 = hoy; [task] nulo = el propio reto.
  String get challengeTaskTitle;

  String challengeTaskBody(int daysLeft, String? task, String? challenge);

  /// Resumen de la mañana: «Hoy: 2 estudios, 1 entreno y entrega de Física».
  String get morningSummaryTitle;

  String morningSummaryBody(ReminderDaySummary summary);

  /// Añade a [body] las tareas de reto que van con ese aviso («… · tarea
  /// «Repasar tema 3» del reto Aprobar Física»). Con [tasks] vacía, [body].
  String withTasks(String body, List<ReminderTask> tasks);

  /// Botón «Empezar» de la notificación de un evento.
  String startAction(ReminderKind kind);

  /// Botón «Posponer 10 min» de la notificación.
  String snoozeAction(int minutes);

  /// Racha en riesgo, registro diario y clase a punto de empezar. En la
  /// clase, [minutes] es cuánto falta (nulo si no se sabe).
  String wellbeingTitle(ReminderKind kind, {String? name, int? minutes});

  String wellbeingBody(
    ReminderKind kind, {
    int? count,
    String? name,
    String? place,
    DateTime? start,
  });
}
