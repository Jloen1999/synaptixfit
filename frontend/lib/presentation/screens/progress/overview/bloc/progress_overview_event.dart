part of 'progress_overview_bloc.dart';

@freezed
sealed class ProgressOverviewEvent with _$ProgressOverviewEvent {
  const factory ProgressOverviewEvent.started() = ProgressOverviewStarted;

  /// Pull-to-refresh o reintento: conserva los datos mientras recarga.
  const factory ProgressOverviewEvent.refreshed() = ProgressOverviewRefreshed;

  /// «Ver N repasos pendientes»: pide la cola de repaso para abrirla en un
  /// toque (la misma que «Repasar todos» de Académico).
  const factory ProgressOverviewEvent.reviewRequested() =
      ProgressOverviewReviewRequested;

  /// La página ya abrió la cola (o dijo el error): se olvida.
  const factory ProgressOverviewEvent.reviewHandled() =
      ProgressOverviewReviewHandled;

  /// «Pausar racha» en un toque (ADR 0042).
  const factory ProgressOverviewEvent.streakPaused() =
      ProgressOverviewStreakPaused;

  /// «Reanudar» la racha (también el «Deshacer» de pausarla).
  const factory ProgressOverviewEvent.streakResumed() =
      ProgressOverviewStreakResumed;

  /// La página ya avisó del cambio de la racha (o de su error): se olvida.
  const factory ProgressOverviewEvent.streakHandled() =
      ProgressOverviewStreakHandled;
}
