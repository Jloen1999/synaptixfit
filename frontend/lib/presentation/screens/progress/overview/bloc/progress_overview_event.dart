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
}
