/// Tipo de pregunta de práctica.
enum QuestionType {
  multipleChoice('MULTIPLE_CHOICE'),
  fillInBlank('FILL_IN_BLANK');

  const QuestionType(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static QuestionType fromApi(String? value) => QuestionType.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => QuestionType.multipleChoice,
  );
}
