/// Tipo de pregunta de práctica. `multipleAnswer` («Varias correctas», ADR
/// 0058) se corrige todo o nada en el servidor.
enum QuestionType {
  multipleChoice('MULTIPLE_CHOICE'),
  fillInBlank('FILL_IN_BLANK'),
  multipleAnswer('MULTIPLE_ANSWER');

  const QuestionType(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  /// Se contesta eligiendo entre opciones.
  bool get hasOptions => this != fillInBlank;

  static QuestionType fromApi(String? value) => QuestionType.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => QuestionType.multipleChoice,
  );
}

/// Respuesta con varias opciones elegidas («Varias correctas»): viajan unidas
/// por un salto de línea, como las guarda el servidor (las opciones nunca lo
/// llevan).
abstract final class QuestionAnswers {
  static const separator = '\n';

  static String join(Iterable<String> answers) =>
      answers.map((a) => a.trim()).where((a) => a.isNotEmpty).join(separator);

  static List<String> split(String? answer) => answer == null
      ? const []
      : answer
            .split(separator)
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList();
}
