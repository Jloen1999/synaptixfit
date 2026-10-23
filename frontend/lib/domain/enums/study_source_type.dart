/// Origen de un material de estudio: apunte o archivo.
enum StudySourceType {
  note('NOTE'),
  file('FILE');

  const StudySourceType(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static StudySourceType fromApi(String? value) =>
      StudySourceType.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => StudySourceType.note,
      );
}
