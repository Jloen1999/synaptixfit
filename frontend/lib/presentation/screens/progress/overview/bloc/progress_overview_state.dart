part of 'progress_overview_bloc.dart';

@freezed
sealed class ProgressOverviewState with _$ProgressOverviewState {
  const factory ProgressOverviewState.loading() = ProgressOverviewLoading;

  const factory ProgressOverviewState.loaded(
    ProgressOverview overview, {

    /// Resumen de hoy para «Tu equilibrio»; nulo si no se pudo leer.
    HomeDashboard? today,

    /// No se pudo leer «Tu equilibrio» (y no había uno anterior): la tarjeta
    /// lo dice y deja reintentar, en vez de desaparecer sin más.
    AppError? todayError,
    @Default(false) bool refreshing,

    /// Error de una recarga: se conservan los datos anteriores.
    AppError? refreshError,
  }) = ProgressOverviewLoaded;

  const factory ProgressOverviewState.failure(AppError error) =
      ProgressOverviewFailure;
}
