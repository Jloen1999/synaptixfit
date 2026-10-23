/// Modo de notificaciones: normal, exámenes (solo lo urgente) o descanso.
enum NotificationMode {
  normal('NORMAL'),
  exams('EXAMS'),
  rest('REST');

  const NotificationMode(this.apiValue);

  final String apiValue;

  static NotificationMode fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => NotificationMode.normal,
  );
}
