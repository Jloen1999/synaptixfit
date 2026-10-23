/// Nivel de actividad física habitual.
enum ActivityLevel {
  sedentary('SEDENTARY'),
  light('LIGHT'),
  moderate('MODERATE'),
  high('HIGH');

  const ActivityLevel(this.apiValue);

  final String apiValue;

  static ActivityLevel? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
