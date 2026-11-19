/// Qué preguntas se piden en «Crear preguntas» (ADR 0058). «Tarjetas» se
/// guardan como preguntas de respuesta corta.
enum QuestionFormat {
  singleChoice('SINGLE_CHOICE'),
  multipleAnswer('MULTIPLE_ANSWER'),
  fillInBlank('FILL_IN_BLANK'),
  flashcard('FLASHCARD'),
  mixed('MIXED');

  const QuestionFormat(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;
}

/// Qué pasa con las preguntas que ya tienes: se añaden las nuevas (sin
/// repetir) o se cambian por ellas.
enum BankUpdateMode {
  add('ADD'),
  replace('REPLACE');

  const BankUpdateMode(this.apiValue);

  final String apiValue;
}

/// Qué hacer con las preguntas que ya trae el documento.
enum DocumentQuestionUse {
  /// No usarlas.
  none,

  /// Usar solo esas.
  only,

  /// Mezclarlas con nuevas.
  mix,
}

/// Si una pregunta del documento se puede usar y por qué no.
enum DocumentQuestionStatus {
  /// Con la respuesta del propio documento.
  ready('READY'),

  /// El documento no traía la respuesta: la propone la IA («Revísala»).
  answerProposed('ANSWER_PROPOSED'),

  /// De desarrollo: no se puede corregir sola.
  longAnswer('LONG_ANSWER'),

  /// Sin respuesta válida.
  noAnswer('NO_ANSWER');

  const DocumentQuestionStatus(this.apiValue);

  final String apiValue;

  bool get usable => this == ready || this == answerProposed;

  static DocumentQuestionStatus fromApi(String? value) =>
      DocumentQuestionStatus.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => DocumentQuestionStatus.noAnswer,
      );
}
