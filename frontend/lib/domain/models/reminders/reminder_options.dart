import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_options.freezed.dart';

/// Avisos opcionales del móvil que se apagan uno a uno: racha en riesgo,
/// registro diario y clase a punto de empezar. Todos encendidos por defecto.
@freezed
abstract class ReminderOptions with _$ReminderOptions {
  const factory ReminderOptions({
    @Default(true) bool streak,
    @Default(true) bool checkIn,
    @Default(true) bool classes,
  }) = _ReminderOptions;
}
