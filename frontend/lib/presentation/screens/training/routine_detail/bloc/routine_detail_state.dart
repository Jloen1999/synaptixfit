part of 'routine_detail_bloc.dart';

enum RoutineDetailStatus { loading, ready, failure }

@freezed
abstract class RoutineDetailState with _$RoutineDetailState {
  const factory RoutineDetailState({
    @Default(RoutineDetailStatus.loading) RoutineDetailStatus status,
    String? routineId,
    Routine? routine,
    AppError? error,

    /// Peso del perfil para estimar calorías (`null` usa el de referencia).
    double? bodyWeightKg,

    /// Hay una operación de edición en curso.
    @Default(false) bool busy,
    TrainingEffect? effect,
  }) = _RoutineDetailState;
}
