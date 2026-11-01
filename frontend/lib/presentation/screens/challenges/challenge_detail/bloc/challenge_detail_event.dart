part of 'challenge_detail_bloc.dart';

@freezed
sealed class ChallengeDetailEvent with _$ChallengeDetailEvent {
  const factory ChallengeDetailEvent.started(String challengeId) =
      ChallengeDetailStarted;

  const factory ChallengeDetailEvent.refreshed() = ChallengeDetailRefreshed;

  /// El reto se ha editado en otra pantalla (hoja rápida).
  const factory ChallengeDetailEvent.challengeReplaced(Challenge challenge) =
      ChallengeDetailChallengeReplaced;

  /// Completa o descompleta el reto (solo sin tareas).
  const factory ChallengeDetailEvent.completionToggled() =
      ChallengeDetailCompletionToggled;

  const factory ChallengeDetailEvent.milestoneToggled(String milestoneId) =
      ChallengeDetailMilestoneToggled;

  const factory ChallengeDetailEvent.progressRecorded({
    String? milestoneId,
    required double value,
  }) = ChallengeDetailProgressRecorded;

  const factory ChallengeDetailEvent.deleteRequested() =
      ChallengeDetailDeleteRequested;

  const factory ChallengeDetailEvent.cloneRequested() =
      ChallengeDetailCloneRequested;

  const factory ChallengeDetailEvent.visibilityChanged(Visibility visibility) =
      ChallengeDetailVisibilityChanged;

  const factory ChallengeDetailEvent.milestonesReordered(
    List<String> milestoneIds,
  ) = ChallengeDetailMilestonesReordered;

  /// Pide la URL firmada de un archivo adjunto para abrirlo.
  const factory ChallengeDetailEvent.fileRequested(String fileId) =
      ChallengeDetailFileRequested;
}
