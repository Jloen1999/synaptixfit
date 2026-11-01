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
  }) = _Reminder;

  const Reminder._();

  /// `payload` de la notificación: «tipo|referencia» (solo el tipo si no hay).
  String get payload => refId == null ? kind.payload : '${kind.payload}|$refId';
}

/// Aviso tocado: a qué pantalla ir ([kind]) y qué abrir en ella ([refId]).
@freezed
abstract class OpenedReminder with _$OpenedReminder {
  const factory OpenedReminder({required ReminderKind kind, String? refId}) =
      _OpenedReminder;

  /// Nulo si el `payload` no es de un aviso conocido (p. ej. de otra versión).
  static OpenedReminder? fromPayload(String? payload) {
    if (payload == null) return null;
    final cut = payload.indexOf('|');
    final kind = ReminderKind.fromPayload(
      cut < 0 ? payload : payload.substring(0, cut),
    );
    if (kind == null) return null;
    final ref = cut < 0 ? null : payload.substring(cut + 1);
    return OpenedReminder(
      kind: kind,
      refId: ref == null || ref.isEmpty ? null : ref,
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
