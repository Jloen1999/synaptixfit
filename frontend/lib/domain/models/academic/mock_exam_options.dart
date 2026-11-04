import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/study_source_type.dart';

part 'mock_exam_options.freezed.dart';

/// Qué se puede meter en un simulacro de una asignatura: los apuntes y
/// archivos que ya tienen preguntas y los límites que pone el servidor.
@freezed
abstract class MockExamOptions with _$MockExamOptions {
  const factory MockExamOptions({
    @Default(<MockExamSource>[]) List<MockExamSource> sources,
    required int maxMaterials,
    required int suggestedQuestions,
    required int maxQuestions,
  }) = _MockExamOptions;

  const MockExamOptions._();

  /// Preguntas disponibles entre los materiales elegidos.
  int questionsIn(Set<String> materialIds) => sources
      .where((s) => materialIds.contains(s.materialId))
      .fold(0, (sum, s) => sum + s.questionCount);
}

/// Material con preguntas que puede entrar en el simulacro.
@freezed
abstract class MockExamSource with _$MockExamSource {
  const factory MockExamSource({
    required String materialId,
    required String title,
    required StudySourceType originType,
    required int questionCount,
  }) = _MockExamSource;
}
