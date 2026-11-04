import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_guide.freezed.dart';

/// «Las claves» y «Errores comunes» de un ejercicio en el idioma de la app
/// (ADR 0031). Vacío si el ejercicio aún no tiene: la sección no se enseña.
@freezed
abstract class ExerciseTips with _$ExerciseTips {
  const factory ExerciseTips({
    @Default(<String>[]) List<String> keyPoints,
    @Default(<String>[]) List<String> commonMistakes,
  }) = _ExerciseTips;

  const ExerciseTips._();

  bool get isEmpty => keyPoints.isEmpty && commonMistakes.isEmpty;
}

/// Nota propia sobre un ejercicio («asiento en el 4, agarre ancho»); solo la
/// ve quien la escribe.
@freezed
abstract class ExerciseNote with _$ExerciseNote {
  const factory ExerciseNote({
    required String text,
    required DateTime updatedAt,
  }) = _ExerciseNote;

  /// Largo máximo que acepta el servidor.
  static const maxLength = 500;
}
