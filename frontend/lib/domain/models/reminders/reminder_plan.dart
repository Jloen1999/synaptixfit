import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/reminder_kind.dart';

part 'reminder_plan.freezed.dart';

/// Aviso ya decidido por el servidor (`GET /notifications/reminder-plan`):
/// qué, cuándo y con qué datos. [ReminderComposer] le pone textos e id.
@freezed
abstract class PlannedReminder with _$PlannedReminder {
  const factory PlannedReminder({
    required ReminderKind kind,

    /// Instante en que debe sonar.
    required DateTime at,

    /// Referencia estable: id del bloque o día del aviso de repasos.
    required String refId,

    /// Repasos vencidos (solo [ReminderKind.dueReviews]).
    int? count,

    /// Título o asignatura del bloque; puede faltar.
    String? title,

    /// Inicio del bloque (solo bloques).
    DateTime? startsAt,

    /// Aula de la clase (solo [ReminderKind.classSoon]).
    String? place,
  }) = _PlannedReminder;
}
