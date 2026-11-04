part of 'generation_center_bloc.dart';

@freezed
sealed class GenerationCenterEvent with _$GenerationCenterEvent {
  const factory GenerationCenterEvent.started({String? subjectId}) =
      GenerationCenterStarted;

  const factory GenerationCenterEvent.subjectSelected(String subjectId) =
      GenerationCenterSubjectSelected;

  const factory GenerationCenterEvent.sourceToggled(StudySourceRef source) =
      GenerationCenterSourceToggled;

  /// Sube un archivo a la asignatura elegida para usarlo como fuente.
  const factory GenerationCenterEvent.fileUploadRequested(
    FileUploadPayload payload,
  ) = GenerationCenterFileUploadRequested;

  const factory GenerationCenterEvent.kindSelected(ArtifactKind kind) =
      GenerationCenterKindSelected;

  /// Genera (o regenera) con las fuentes y el tipo elegidos.
  const factory GenerationCenterEvent.generateRequested() =
      GenerationCenterGenerateRequested;

  const factory GenerationCenterEvent.discarded() = GenerationCenterDiscarded;

  /// Guarda como apunte (resumen y mapa) o como preguntas (flashcards y test).
  const factory GenerationCenterEvent.saveRequested({String? title}) =
      GenerationCenterSaveRequested;

  /// La persona corrige el texto del resumen antes de guardarlo.
  const factory GenerationCenterEvent.summaryEdited(String markdown) =
      GenerationCenterSummaryEdited;

  /// Corrige una tarjeta (pregunta y respuesta).
  const factory GenerationCenterEvent.flashcardEdited(
    int index,
    Flashcard card,
  ) = GenerationCenterFlashcardEdited;

  /// Corrige una pregunta del test (enunciado, opciones o respuesta buena).
  const factory GenerationCenterEvent.questionEdited(
    int index,
    QuestionDraft question,
  ) = GenerationCenterQuestionEdited;

  /// Quita una tarjeta o pregunta que sobra o está mal (se puede deshacer).
  const factory GenerationCenterEvent.itemRemoved(int index) =
      GenerationCenterItemRemoved;

  /// Deshace la última eliminación.
  const factory GenerationCenterEvent.removalUndone() =
      GenerationCenterRemovalUndone;
}
