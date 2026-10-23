/// Prioridad de una notificación.
enum NotificationPriority {
  critical('CRITICAL'),
  recommended('RECOMMENDED'),
  informative('INFORMATIVE');

  const NotificationPriority(this.apiValue);

  final String apiValue;

  static NotificationPriority fromApi(String? value) =>
      NotificationPriority.values.firstWhere(
        (p) => p.apiValue == value,
        orElse: () => NotificationPriority.informative,
      );
}
