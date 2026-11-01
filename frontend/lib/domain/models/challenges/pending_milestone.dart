import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_type.dart';
import 'challenge.dart';

part 'pending_milestone.freezed.dart';

/// Tarea pendiente de un reto en curso (sección «Tareas pendientes»).
@freezed
abstract class PendingMilestone with _$PendingMilestone {
  const factory PendingMilestone({
    required String challengeId,
    required String challengeTitle,
    required DateTime challengeEndAt,
    @Default(ChallengeType.fitness) ChallengeType challengeType,
    required Milestone milestone,
  }) = _PendingMilestone;
}
