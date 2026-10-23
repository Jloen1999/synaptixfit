part of 'challenge_detail_bloc.dart';

enum ChallengeDetailStatus { loading, ready, failure }

@freezed
abstract class ChallengeDetailState with _$ChallengeDetailState {
  const factory ChallengeDetailState({
    @Default(ChallengeDetailStatus.loading) ChallengeDetailStatus status,
    Challenge? challenge,
    @Default(<ChallengeProgressEntry>[]) List<ChallengeProgressEntry> history,
    String? subjectName,

    /// Hay una acción en curso.
    @Default(false) bool busy,

    /// Tarea concreta que se está completando o descompletando.
    String? busyMilestoneId,
    AppError? error,
    ChallengeDetailEffect? effect,
  }) = _ChallengeDetailState;
}

@freezed
sealed class ChallengeDetailEffect with _$ChallengeDetailEffect {
  /// Resultado de completar/descompletar o registrar progreso.
  const factory ChallengeDetailEffect.outcome({
    required int xpDelta,
    @Default(<String>[]) List<String> unlockedTitles,
    required bool challengeCompleted,
    @Default(false) bool progressRecorded,
    Account? account,
  }) = ChallengeDetailOutcome;

  /// Reto borrado; [xpLost] es la XP que se ha restado.
  const factory ChallengeDetailEffect.deleted({
    required int xpLost,
    Account? account,
  }) = ChallengeDetailDeleted;

  const factory ChallengeDetailEffect.cloned(String challengeId) =
      ChallengeDetailCloned;

  const factory ChallengeDetailEffect.saved() = ChallengeDetailSaved;

  const factory ChallengeDetailEffect.openUrl(String url) =
      ChallengeDetailOpenUrl;

  const factory ChallengeDetailEffect.failure(AppError error) =
      ChallengeDetailActionFailed;
}
