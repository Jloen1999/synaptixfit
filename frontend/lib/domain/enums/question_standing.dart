/// Cómo va una pregunta según su último intento (ADR 0063). Lo calcula el
/// servidor, que también ordena la lista: primero las que vuelven antes.
enum QuestionStanding {
  /// La última vez se contestó «No lo sé»: vuelve la primera.
  dontKnow('DONT_KNOW'),

  /// La última vez se falló.
  wrong('WRONG'),

  /// Aún no se ha contestado.
  fresh('NEW'),

  /// La última vez se acertó.
  correct('CORRECT');

  const QuestionStanding(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  /// Toca repasarla: la última vez fue «No lo sé» o un fallo.
  bool get toReview => this == dontKnow || this == wrong;

  static QuestionStanding fromApi(String? value) => QuestionStanding.values
      .firstWhere((v) => v.apiValue == value, orElse: () => fresh);
}
