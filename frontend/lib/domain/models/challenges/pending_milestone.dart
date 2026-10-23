import 'package:freezed_annotation/freezed_annotation.dart';

import 'challenge.dart';

part 'pending_milestone.freezed.dart';

/// Tarea pendiente de un reto activo (sección «Tareas de hoy»).
@freezed
abstract class PendingMilestone with _$PendingMilestone {
  const factory PendingMilestone({
    required String challengeId,
    required String challengeTitle,
    required DateTime challengeEndAt,
    required Milestone milestone,
  }) = _PendingMilestone;
}
