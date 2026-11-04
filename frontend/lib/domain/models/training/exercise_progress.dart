import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_progress.freezed.dart';

/// Punto de la gráfica de evolución de un ejercicio: el peso máximo estimado
/// ese día («lo máximo que podrías levantar una vez») y la serie que lo dio.
/// Lo calcula el servidor (ADR 0032).
@freezed
abstract class ExerciseProgressPoint with _$ExerciseProgressPoint {
  const factory ExerciseProgressPoint({
    required DateTime date,
    required double estimatedMaxKg,
    required double weightKg,
    required int reps,
  }) = _ExerciseProgressPoint;
}
