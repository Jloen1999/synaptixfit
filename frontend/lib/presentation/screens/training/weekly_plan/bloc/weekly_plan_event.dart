part of 'weekly_plan_bloc.dart';

@freezed
sealed class WeeklyPlanEvent with _$WeeklyPlanEvent {
  const factory WeeklyPlanEvent.started() = WeeklyPlanStarted;

  /// Semana anterior (-1) o siguiente (+1).
  const factory WeeklyPlanEvent.weekChanged(int delta) = WeeklyPlanWeekChanged;

  const factory WeeklyPlanEvent.inputChanged(WeeklyPlanInput input) =
      WeeklyPlanInputChanged;

  const factory WeeklyPlanEvent.saved() = WeeklyPlanSaved;

  const factory WeeklyPlanEvent.deleted() = WeeklyPlanDeleted;
}
