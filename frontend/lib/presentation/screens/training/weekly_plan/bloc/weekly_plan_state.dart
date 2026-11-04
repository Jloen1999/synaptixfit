part of 'weekly_plan_bloc.dart';

enum PlanLoadStatus { loading, ready, failure }

@freezed
abstract class WeeklyPlanState with _$WeeklyPlanState {
  const factory WeeklyPlanState({
    @Default(PlanLoadStatus.loading) PlanLoadStatus status,

    /// Lunes de la semana mostrada y de la semana actual.
    DateTime? weekStart,
    DateTime? currentWeek,

    /// Plan guardado de la semana (o `null`).
    WeeklyPlan? plan,
    @Default(WeeklyPlanInput()) WeeklyPlanInput input,
    @Default(<WeeklyPlan>[]) List<WeeklyPlan> history,
    @Default(false) bool saving,
    AppError? error,
    TrainingEffect? effect,

    /// Días de la semana en curso de la rutina activa y su nombre (nulos sin
    /// rutina en curso).
    int? routineSessions,
    String? routineName,
  }) = _WeeklyPlanState;
}
