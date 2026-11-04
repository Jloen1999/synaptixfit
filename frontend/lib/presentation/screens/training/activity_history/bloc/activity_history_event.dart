part of 'activity_history_bloc.dart';

@freezed
sealed class ActivityHistoryEvent with _$ActivityHistoryEvent {
  const factory ActivityHistoryEvent.started() = ActivityHistoryStarted;

  const factory ActivityHistoryEvent.moreRequested() =
      ActivityHistoryMoreRequested;
}
