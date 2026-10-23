/// Estado de una sesión de test (simulacro).
enum TestSessionStatus {
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  abandoned('ABANDONED');

  const TestSessionStatus(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static TestSessionStatus fromApi(String? value) =>
      TestSessionStatus.values.firstWhere(
        (v) => v.apiValue == value,
        orElse: () => TestSessionStatus.inProgress,
      );
}
