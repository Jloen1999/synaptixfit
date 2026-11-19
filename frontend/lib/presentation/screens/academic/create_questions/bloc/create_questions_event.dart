part of 'create_questions_bloc.dart';

@freezed
sealed class CreateQuestionsEvent with _$CreateQuestionsEvent {
  /// Desde un apunte o archivo ([materialId]) o desde la asignatura
  /// ([subjectId]): con uno solo se elige solo; con varios, se pregunta.
  const factory CreateQuestionsEvent.started({
    String? materialId,
    String? title,
    String? subjectId,
  }) = CreateQuestionsStarted;

  /// «Cambiar»: volver a la lista de apuntes y archivos.
  const factory CreateQuestionsEvent.sourcePickRequested() =
      CreateQuestionsSourcePickRequested;

  const factory CreateQuestionsEvent.sourceChosen(QuestionSourceOption source) =
      CreateQuestionsSourceChosen;

  /// Reintentar lo que falló al preparar (apuntes, material o banco).
  const factory CreateQuestionsEvent.retried() = CreateQuestionsRetried;

  /// Volver a mirar si el documento trae preguntas.
  const factory CreateQuestionsEvent.scanRetried() = CreateQuestionsScanRetried;

  const factory CreateQuestionsEvent.formatChosen(QuestionFormat format) =
      CreateQuestionsFormatChosen;

  const factory CreateQuestionsEvent.countChanged(int count) =
      CreateQuestionsCountChanged;

  const factory CreateQuestionsEvent.documentUseChosen(
    DocumentQuestionUse use,
  ) = CreateQuestionsDocumentUseChosen;

  const factory CreateQuestionsEvent.modeChosen(BankUpdateMode mode) =
      CreateQuestionsModeChosen;

  /// «Crear N preguntas»: con preguntas del documento abre la revisión; sin
  /// ellas, crea directamente.
  const factory CreateQuestionsEvent.submitted() = CreateQuestionsSubmitted;

  /// Casilla «Usar» de la pregunta [index] del documento.
  const factory CreateQuestionsEvent.reviewToggled(int index) =
      CreateQuestionsReviewToggled;

  /// «Cambiar la respuesta» de la pregunta [index].
  const factory CreateQuestionsEvent.answerChanged(
    int index,
    List<String> answers,
  ) = CreateQuestionsAnswerChanged;

  /// «Guardar N preguntas» en la revisión (o reintentar el guardado).
  const factory CreateQuestionsEvent.saveRequested() =
      CreateQuestionsSaveRequested;
}
