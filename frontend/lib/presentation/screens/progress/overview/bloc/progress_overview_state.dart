part of 'progress_overview_bloc.dart';

@freezed
sealed class ProgressOverviewState with _$ProgressOverviewState {
  const factory ProgressOverviewState.loading() = ProgressOverviewLoading;

  const factory ProgressOverviewState.loaded(
    ProgressOverview overview, {
    @Default(false) bool refreshing,

    /// Error de una recarga: se conservan los datos anteriores.
    AppError? refreshError,
  }) = ProgressOverviewLoaded;

  const factory ProgressOverviewState.failure(AppError error) =
      ProgressOverviewFailure;
}
