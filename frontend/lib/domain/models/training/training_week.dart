import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_week.freezed.dart';

/// Qué pasa un día de la semana de entreno: ya se entrenó, toca o nada.
enum TrainingDayState {
  done,
  planned,
  free;

  static TrainingDayState fromApi(String? value) => switch (value) {
    'DONE' => done,
    'PLANNED' => planned,
    _ => free,
  };
}

/// Un día de la semana de entreno. [sessionId] es el entreno hecho ese día.
@freezed
abstract class TrainingWeekDay with _$TrainingWeekDay {
  const factory TrainingWeekDay({
    required DateTime date,
    required TrainingDayState state,
    @Default(false) bool today,
    String? sessionId,
  }) = _TrainingWeekDay;
}

/// La semana de entreno, de lunes a domingo (ADR 0055): la calcula el servidor
/// y Gimnasio la pinta con siete puntos. [done] de [total]: días entrenados de
/// los que tocan esta semana.
@freezed
abstract class TrainingWeek with _$TrainingWeek {
  const factory TrainingWeek({
    @Default(<TrainingWeekDay>[]) List<TrainingWeekDay> days,
    @Default(0) int done,
    @Default(0) int total,
  }) = _TrainingWeek;
}
