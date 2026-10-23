part of 'quick_challenge_bloc.dart';

enum QuickChallengeStatus { loading, ready, saving, saved }

@freezed
abstract class QuickChallengeState with _$QuickChallengeState {
  const factory QuickChallengeState({
    @Default(QuickChallengeStatus.loading) QuickChallengeStatus status,
    @Default(<ChallengeSubjectOption>[]) List<ChallengeSubjectOption> subjects,

    /// Reto creado o actualizado (status saved).
    Challenge? saved,
    AppError? error,
  }) = _QuickChallengeState;
}
