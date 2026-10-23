/// Categoría de notificación que el usuario puede activar o silenciar.
enum NotificationCategory {
  conflict('CONFLICT'),
  fatigueAlert('FATIGUE_ALERT'),
  milestone('MILESTONE'),
  social('SOCIAL'),
  academic('ACADEMIC');

  const NotificationCategory(this.apiValue);

  final String apiValue;

  static NotificationCategory? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
