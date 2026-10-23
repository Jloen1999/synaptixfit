part of 'session_completed_bloc.dart';

enum CompletedStatus { loading, ready, failure }

@freezed
abstract class SessionCompletedState with _$SessionCompletedState {
  const factory SessionCompletedState({
    @Default(CompletedStatus.loading) CompletedStatus status,
    TrainingSession? session,
    ExperienceChange? experience,
    @Default(<Recommendation>[]) List<Recommendation> recommendations,
    @Default(<String>{}) Set<String> busyIds,
    AppError? error,
    TrainingEffect? effect,
  }) = _SessionCompletedState;
}
