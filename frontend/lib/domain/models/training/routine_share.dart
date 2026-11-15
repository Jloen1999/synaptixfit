import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';

part 'routine_share.freezed.dart';

/// Enlace recién creado para copiar una rutina (ADR 0043): la dirección que se
/// comparte y hasta cuándo vale. El token solo se ve esta vez.
@freezed
abstract class RoutineShareLink with _$RoutineShareLink {
  const factory RoutineShareLink({
    required String url,
    required DateTime expiresAt,
  }) = _RoutineShareLink;
}

/// Ejercicio del resumen de una rutina compartida.
@freezed
abstract class SharedRoutineExercise with _$SharedRoutineExercise {
  const factory SharedRoutineExercise({
    required String exerciseId,
    required String name,
    String? imageUrl,
    required int sets,
  }) = _SharedRoutineExercise;
}

/// Día de la primera semana de una rutina compartida.
@freezed
abstract class SharedRoutineDay with _$SharedRoutineDay {
  const factory SharedRoutineDay({
    required int dayNumber,
    String? name,
    @Default(0) int estimatedMinutes,
    @Default(<SharedRoutineExercise>[]) List<SharedRoutineExercise> exercises,
  }) = _SharedRoutineDay;
}

/// Lo que ve quien abre un enlace de rutina antes de copiarla: solo la
/// rutina, nada de quien la comparte (ADR 0043).
@freezed
abstract class SharedRoutinePreview with _$SharedRoutinePreview {
  const factory SharedRoutinePreview({
    required String name,
    String? description,
    TrainingGoal? goal,
    required int durationWeeks,
    required int daysPerWeek,
    required int exerciseCount,
    @Default(<SharedRoutineDay>[]) List<SharedRoutineDay> firstWeek,
  }) = _SharedRoutinePreview;
}
