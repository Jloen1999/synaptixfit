part of 'training_home_bloc.dart';

enum HomeStatus { loading, ready, failure }

@freezed
abstract class TrainingHomeState with _$TrainingHomeState {
  const factory TrainingHomeState({
    @Default(HomeStatus.loading) HomeStatus status,
    AppError? error,

    /// Recarga en segundo plano (pull-to-refresh).
    @Default(false) bool refreshing,
    PendingDay? pendingDay,
    @Default(<RoutineSummary>[]) List<RoutineSummary> routines,
    CheckIn? todayCheckIn,
    @Default(<Recommendation>[]) List<Recommendation> recommendations,

    /// Sugerencias con una acción en curso.
    @Default(<String>{}) Set<String> busyIds,
    @Default(false) bool startingSession,
    TrainingEffect? effect,
  }) = _TrainingHomeState;
}
