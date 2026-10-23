import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';
import '../../enums/visibility.dart';
import 'routine.dart';

part 'routine_draft.freezed.dart';

/// Ejercicio de una rutina en edición (aún sin guardar).
@freezed
abstract class DraftExercise with _$DraftExercise {
  const factory DraftExercise({
    required String exerciseId,
    required String exerciseName,
    String? thumbnailUrl,

    /// MET del ejercicio si se conoce (añadido desde el catálogo).
    double? met,
    @Default(ExerciseParameters()) ExerciseParameters parameters,
  }) = _DraftExercise;
}

/// Día de una rutina en edición (1 = lunes … 7 = domingo).
@freezed
abstract class DraftDay with _$DraftDay {
  const factory DraftDay({
    required int dayNumber,
    String? name,
    @Default(<DraftExercise>[]) List<DraftExercise> exercises,
  }) = _DraftDay;
}

/// Semana de una rutina en edición.
@freezed
abstract class DraftWeek with _$DraftWeek {
  const factory DraftWeek({
    String? name,
    WeekType? type,
    @Default(<DraftDay>[]) List<DraftDay> days,
  }) = _DraftWeek;
}

/// Rutina en edición: la misma forma sirve para crearla y para refinarla con IA.
@freezed
abstract class RoutineDraft with _$RoutineDraft {
  const factory RoutineDraft({
    @Default('') String name,
    String? description,
    TrainingGoal? goal,
    @Default(Visibility.private) Visibility visibility,
    DateTime? startDate,
    @Default(<DraftWeek>[]) List<DraftWeek> weeks,
  }) = _RoutineDraft;

  const RoutineDraft._();

  static const maxWeeks = 12;
  static const maxExercisesPerDay = 30;

  int get exerciseCount => weeks.fold(
    0,
    (sum, w) => sum + w.days.fold(0, (s, d) => s + d.exercises.length),
  );

  bool get hasEmptyDays =>
      weeks.any((w) => w.days.any((d) => d.exercises.isEmpty));
}

/// Propuesta de rutina generada (motor de reglas + IA).
@freezed
abstract class RoutineProposal with _$RoutineProposal {
  const factory RoutineProposal({
    required RoutineDraft draft,
    String? split,
    @Default(<String>[]) List<String> adjustmentReasons,
    double? totalLoadFactor,

    /// Si la IA refinó la propuesta.
    @Default(false) bool aiRefined,

    /// Por qué no se usó la IA (si cayó al motor de reglas).
    String? aiNotice,
  }) = _RoutineProposal;
}
