import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/reminder_kind.dart';

part 'reminder.freezed.dart';

/// Aviso local programado en el dispositivo. Lo construye `ReminderComposer`
/// a partir del plan del servidor y lo programa la implementación de
/// `ReminderSchedulerRepositoryContract`.
@freezed
abstract class Reminder with _$Reminder {
  const factory Reminder({
    /// Identificador estable: el mismo bloque da siempre el mismo id.
    required int id,
    required ReminderKind kind,
    required String title,
    required String body,

    /// Instante en que debe sonar.
    required DateTime at,
  }) = _Reminder;
}

/// Estado de los recordatorios en este dispositivo: si la plataforma los
/// admite (móvil sí, web no), si el usuario los ha activado aquí y si el
/// sistema permite mostrarlos (se puede retirar desde los ajustes del teléfono).
@freezed
abstract class DeviceRemindersStatus with _$DeviceRemindersStatus {
  const factory DeviceRemindersStatus({
    required bool supported,
    required bool enabled,
    @Default(true) bool permissionGranted,
  }) = _DeviceRemindersStatus;
}
