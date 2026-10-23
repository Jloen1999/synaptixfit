import 'package:freezed_annotation/freezed_annotation.dart';

import 'challenge.dart';

part 'challenge_outcome.freezed.dart';

/// Resultado de una acción que cambia el estado de un reto (XP y desbloqueos).
@freezed
abstract class ChallengeOutcome with _$ChallengeOutcome {
  const factory ChallengeOutcome({
    required Challenge challenge,

    /// XP ganada (positiva) o restada (negativa).
    required int xpDelta,
    @Default(<String>[]) List<String> unlockedMilestoneIds,

    /// `true` si la acción ha completado el reto.
    required bool challengeCompleted,
  }) = _ChallengeOutcome;
}
