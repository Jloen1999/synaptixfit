part of 'together_bloc.dart';

@freezed
sealed class TogetherEvent with _$TogetherEvent {
  const factory TogetherEvent.started() = TogetherStarted;

  /// Al volver de un reto o un entreno: vuelve a leer sin pantalla de carga.
  const factory TogetherEvent.refreshed() = TogetherRefreshed;

  const factory TogetherEvent.challengeJoined(String id) =
      TogetherChallengeJoined;

  const factory TogetherEvent.challengeDeclined(String id) =
      TogetherChallengeDeclined;

  const factory TogetherEvent.streakProposed(String friendId) =
      TogetherStreakProposed;

  const factory TogetherEvent.streakAccepted(String id) =
      TogetherStreakAccepted;

  const factory TogetherEvent.streakDeclined(String id) =
      TogetherStreakDeclined;

  const factory TogetherEvent.streakEnded(String id) = TogetherStreakEnded;

  /// Retirar una propuesta de racha (mismo caso de uso que terminar).
  const factory TogetherEvent.streakWithdrawn(String id) =
      TogetherStreakWithdrawn;

  /// «Recordárselo» (como mucho una vez al día, lo decide el servidor).
  const factory TogetherEvent.streakNudged(String id) = TogetherStreakNudged;

  const factory TogetherEvent.workoutJoined(String id) = TogetherWorkoutJoined;

  const factory TogetherEvent.workoutDeclined(String id) =
      TogetherWorkoutDeclined;
}
