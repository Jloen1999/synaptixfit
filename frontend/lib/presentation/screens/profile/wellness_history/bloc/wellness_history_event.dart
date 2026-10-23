part of 'wellness_history_bloc.dart';

@freezed
sealed class WellnessHistoryEvent with _$WellnessHistoryEvent {
  /// Carga inicial y reintento.
  const factory WellnessHistoryEvent.started() = WellnessHistoryStarted;
}
