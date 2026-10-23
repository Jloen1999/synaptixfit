import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/artifact_kind.dart';
import '../../enums/question_type.dart';
import '../../enums/study_source_type.dart';
import 'mind_map.dart';

part 'study_artifact.freezed.dart';

/// Referencia a una fuente (apunte o archivo) para la generación multi-fuente.
@freezed
abstract class StudySourceRef with _$StudySourceRef {
  const factory StudySourceRef({
    required StudySourceType type,
    required String id,
  }) = _StudySourceRef;
}

/// Resultado efímero del centro de generación.
@freezed
abstract class StudyArtifact with _$StudyArtifact {
  const factory StudyArtifact({
    required ArtifactKind kind,
    required String title,
    String? markdown,
    MindMap? mindMap,
    @Default(<Flashcard>[]) List<Flashcard> flashcards,
    @Default(<QuestionDraft>[]) List<QuestionDraft> questions,
  }) = _StudyArtifact;
}

/// Tarjeta pregunta/respuesta.
@freezed
abstract class Flashcard with _$Flashcard {
  const factory Flashcard({required String question, required String answer}) =
      _Flashcard;
}

/// Pregunta generada aún no guardada.
@freezed
abstract class QuestionDraft with _$QuestionDraft {
  const factory QuestionDraft({
    required QuestionType type,
    required String statement,
    @Default(<String>[]) List<String> options,
    required String correctAnswer,
    String? explanation,
  }) = _QuestionDraft;
}

/// Resultado de guardar preguntas generadas como banco de práctica.
@freezed
abstract class SavedQuiz with _$SavedQuiz {
  const factory SavedQuiz({
    required String noteId,
    required String materialId,
    required String questionBankId,
    required int questionCount,
  }) = _SavedQuiz;
}
