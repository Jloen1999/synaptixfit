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

    /// Qué abre al tocarlo: id del bloque, sesión, día de rutina o reto.
    String? refId,

    /// Botones dentro de la notificación: «Empezar» y «Posponer» (nulos si
    /// el aviso no los lleva). Posponer lo vuelve a mostrar a los
    /// [snoozeMinutes] minutos sin abrir la app.
    String? startLabel,
    String? snoozeLabel,
    @Default(10) int snoozeMinutes,
  }) = _Reminder;

  const Reminder._();

  /// `payload` de la notificación: «tipo|referencia» (solo el tipo si no hay).
  String get payload => refId == null ? kind.payload : '${kind.payload}|$refId';

  /// Lleva los botones «Empezar» y «Posponer».
  bool get hasActions => startLabel != null && snoozeLabel != null;
}

/// Aviso tocado: a qué pantalla ir ([kind]) y qué abrir en ella ([refId]).
/// [start]: se pulsó «Empezar» en la notificación (no el aviso en sí).
@freezed
abstract class OpenedReminder with _$OpenedReminder {
  const factory OpenedReminder({
    required ReminderKind kind,
    String? refId,
    @Default(false) bool start,
  }) = _OpenedReminder;

  /// Nulo si el `payload` no es de un aviso conocido (p. ej. de otra versión).
  /// Admite «tipo», «tipo|referencia» y «tipo|referencia|extra» (el extra lo
  /// usa el teléfono para volver a mostrar un aviso pospuesto).
  static OpenedReminder? fromPayload(String? payload, {bool start = false}) {
    if (payload == null) return null;
    final parts = payload.split('|');
    final kind = ReminderKind.fromPayload(parts.first);
    if (kind == null) return null;
    final ref = parts.length > 1 ? parts[1] : null;
    return OpenedReminder(
      kind: kind,
      refId: ref == null || ref.isEmpty ? null : ref,
      start: start,
    );
  }
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
