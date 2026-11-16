import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_calibration.freezed.dart';

/// Respuesta a «¿Cuántas más podrías haber hecho?» tras la primera serie de un
/// ejercicio nuevo (ADR 0054).
enum CalibrationAnswer {
  none('NONE'),
  oneTwo('ONE_TWO'),
  three('THREE'),
  fourPlus('FOUR_PLUS');

  const CalibrationAnswer(this.api);

  final String api;

  static CalibrationAnswer? fromApi(String? value) =>
      values.where((a) => a.api == value).firstOrNull;
}

/// Qué hacer con el peso en la serie siguiente (lo decide el servidor).
enum CalibrationStep {
  up('UP'),
  keep('KEEP'),
  down('DOWN');

  const CalibrationStep(this.api);

  final String api;

  static CalibrationStep? fromApi(String? value) =>
      values.where((s) => s.api == value).firstOrNull;
}

/// Ejercicio de la sesión en vivo que se calibra (primera vez con kilos, ADR
/// 0054). Hasta que se responde, [answer] es nulo; después, el servidor manda
/// el paso y el peso de la serie siguiente ([nextWeightKg], nulo si la serie
/// no llevaba kilos).
@freezed
abstract class ExerciseCalibration with _$ExerciseCalibration {
  const factory ExerciseCalibration({
    required String plannedExerciseId,
    required String exerciseId,
    CalibrationAnswer? answer,
    int? setNumber,
    CalibrationStep? step,
    double? nextWeightKg,
  }) = _ExerciseCalibration;

  const ExerciseCalibration._();

  bool get answered => answer != null;
}
