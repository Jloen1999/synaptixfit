/// Idioma de la app. Por defecto el del dispositivo si es uno de los
/// admitidos (si no, español); se puede fijar en Ajustes y se guarda en el
/// dispositivo.
enum AppLanguage {
  system('system', null),
  es('es', 'es'),
  en('en', 'en'),
  fr('fr', 'fr'),
  pt('pt', 'pt');

  const AppLanguage(this.storageValue, this.languageCode);

  final String storageValue;

  /// Código ISO 639-1, o nulo para «el del dispositivo».
  final String? languageCode;

  /// Idiomas con traducción completa.
  static const supportedCodes = ['es', 'en', 'fr', 'pt'];

  /// Idioma que se usa si el del dispositivo no está entre los admitidos.
  static const fallbackCode = 'es';

  /// El del dispositivo si no hay nada guardado o no se reconoce.
  static AppLanguage fromStorage(String? value) => values.firstWhere(
    (l) => l.storageValue == value,
    orElse: () => AppLanguage.system,
  );

  /// Código efectivo para un idioma del dispositivo ([deviceCode]).
  static String resolve(AppLanguage chosen, String? deviceCode) {
    final code = chosen.languageCode ?? deviceCode;
    return supportedCodes.contains(code) ? code! : fallbackCode;
  }
}
