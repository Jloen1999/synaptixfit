part of 'weekly_load_bloc.dart';

@freezed
sealed class WeeklyLoadEvent with _$WeeklyLoadEvent {
  const factory WeeklyLoadEvent.started(DateTime weekStart) = WeeklyLoadStarted;

  const factory WeeklyLoadEvent.wellbeingSaved({
    required int stressLevel,
    required double sleepHours,
    String? notes,
  }) = WeeklyLoadWellbeingSaved;

  const factory WeeklyLoadEvent.syncRequested() = WeeklyLoadSyncRequested;
}
