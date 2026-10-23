/// Tipo de tema del temario de la guía docente.
enum SyllabusTopicKind {
  theory('THEORY'),
  practice('PRACTICE');

  const SyllabusTopicKind(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static SyllabusTopicKind fromApi(String? value) =>
      SyllabusTopicKind.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => SyllabusTopicKind.theory,
      );
}
