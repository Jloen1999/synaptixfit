import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/reminder_task_timing.dart';
import '../profile/notification_preferences.dart';

part 'reminder_options.freezed.dart';

/// Opciones de los avisos del móvil (`/notifications/reminder-options`,
/// ADR 0033 y 0035): avisos que se apagan uno a uno (racha, registro diario y
/// clases) y cuándo llegan los de eventos, entregas, tareas de reto y el
/// resumen de la mañana. Los valores por defecto son los del servidor.
@freezed
abstract class ReminderOptions with _$ReminderOptions {
  const factory ReminderOptions({
    @Default(true) bool streak,
    @Default(true) bool checkIn,
    @Default(true) bool classes,

    /// Minutos antes de un evento o una clase.
    @Default(15) int eventLeadMinutes,

    /// Días antes de una entrega o un examen (uno o varios, ordenados).
    @Default(<int>[1, 3]) List<int> deadlineDaysBefore,
    @Default(ReminderTaskTiming.eveningBefore) ReminderTaskTiming taskTiming,
    @Default(true) bool morningSummary,

    /// Hora del resumen. Con el resumen apagado el servidor no la guarda:
    /// al volver a cargar vale la de por defecto (08:00).
    @Default(ClockTime(hour: 8, minute: 0)) ClockTime morningSummaryAt,
  }) = _ReminderOptions;

  /// Copia, solo para pintar la pantalla, de las opciones cerradas que acepta
  /// el servidor (`ReminderOptions` del backend; fuera de ellas responde
  /// `REMINDER_OPTIONS_INVALID`). Si cambian allí, se cambian aquí.
  static const leadMinuteChoices = [5, 15, 30, 60];
  static const deadlineDayChoices = [1, 3, 7];

  /// En punto o y media, de 05:00 a 12:00.
  static final summaryTimeChoices = [
    for (var half = 10; half <= 24; half++)
      ClockTime(hour: half ~/ 2, minute: half.isOdd ? 30 : 0),
  ];
}
