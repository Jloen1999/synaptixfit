part of 'progress_overview_bloc.dart';

@freezed
sealed class ProgressOverviewEvent with _$ProgressOverviewEvent {
  const factory ProgressOverviewEvent.started() = ProgressOverviewStarted;

  /// Pull-to-refresh o reintento: conserva los datos mientras recarga.
  const factory ProgressOverviewEvent.refreshed() = ProgressOverviewRefreshed;
}
