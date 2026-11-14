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

    /// Pidiendo la cola de repaso («Ver N repasos pendientes»).
    @Default(false) bool openingReview,

    /// Cola lista para abrir (ids de los materiales, en orden); vacía si ya no
    /// queda ninguno. Se consume una vez con `reviewHandled`.
    List<String>? reviewQueue,

    /// No se pudo leer la cola de repaso.
    AppError? reviewError,
  }) = ProgressOverviewLoaded;

  const factory ProgressOverviewState.failure(AppError error) =
      ProgressOverviewFailure;
}
