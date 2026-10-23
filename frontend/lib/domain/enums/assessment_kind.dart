/// Tipo de prueba de la guía docente; decide qué se crea en el planificador.
enum AssessmentKind {
  exam('EXAM'),
  assignment('ASSIGNMENT'),
  presentation('PRESENTATION'),
  other('OTHER');

  const AssessmentKind(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static AssessmentKind fromApi(String? value) =>
      AssessmentKind.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => AssessmentKind.other,
      );
}
