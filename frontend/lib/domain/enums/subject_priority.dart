/// Prioridad de una asignatura.
enum SubjectPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const SubjectPriority(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static SubjectPriority fromApi(String? value) =>
      SubjectPriority.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => SubjectPriority.medium,
      );
}
