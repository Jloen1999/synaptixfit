/// Tipo de documento de IA guardado sobre un apunte o archivo.
enum AiDocumentType {
  summary('SUMMARY'),
  mindMap('MIND_MAP'),
  practice('PRACTICE'),
  teachingGuide('TEACHING_GUIDE');

  const AiDocumentType(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static AiDocumentType fromApi(String? value) =>
      AiDocumentType.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => AiDocumentType.summary,
      );
}
