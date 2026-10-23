/// Origen de una notificación.
enum NotificationType {
  conflict('CONFLICT'),
  fatigueAlert('FATIGUE_ALERT'),
  milestone('MILESTONE'),
  social('SOCIAL'),
  academic('ACADEMIC');

  const NotificationType(this.apiValue);

  final String apiValue;

  static NotificationType fromApi(String? value) =>
      NotificationType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => NotificationType.social,
      );
}
