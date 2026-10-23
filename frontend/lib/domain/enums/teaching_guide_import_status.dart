/// Estado de una importación de plan docente. El servidor da por fallido un
/// análisis colgado, así que el cliente solo espera mientras sea [isRunning].
enum TeachingGuideImportStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  ready('READY'),
  failed('FAILED'),
  applied('APPLIED');

  const TeachingGuideImportStatus(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  bool get isRunning => this == pending || this == processing;

  static TeachingGuideImportStatus fromApi(String? value) =>
      TeachingGuideImportStatus.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => TeachingGuideImportStatus.failed,
      );
}
