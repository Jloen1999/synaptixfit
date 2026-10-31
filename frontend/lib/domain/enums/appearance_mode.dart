/// Cómo se ve la app: la dirección de marca es oscura; el claro y el del
/// sistema son elecciones del usuario en Ajustes (se guardan en el dispositivo).
enum AppearanceMode {
  dark('dark'),
  light('light'),
  system('system');

  const AppearanceMode(this.storageValue);

  final String storageValue;

  /// Oscuro si no hay nada guardado o el valor no se reconoce.
  static AppearanceMode fromStorage(String? value) => values.firstWhere(
    (m) => m.storageValue == value,
    orElse: () => AppearanceMode.dark,
  );
}
