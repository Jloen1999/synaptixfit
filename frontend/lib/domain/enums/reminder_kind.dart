/// Qué recuerda un aviso local del móvil. Viaja como `payload` de la
/// notificación para que, al tocarla, presentation sepa a qué pantalla ir.
/// [apiValue] es su nombre en el plan del servidor.
enum ReminderKind {
  /// Repasos espaciados (SM-2) vencidos.
  dueReviews('REVIEWS'),

  /// Bloque de deporte del planificador a punto de empezar.
  sportBlock('TRAINING'),

  /// Bloque de estudio o repaso del planificador a punto de empezar.
  studyBlock('STUDY'),

  /// Examen pendiente en pocos días.
  exam('EXAM'),

  /// Entrega pendiente en pocos días.
  deadline('DEADLINE'),

  /// «Tu semana»: el domingo por la tarde.
  weeklySummary('WEEKLY_SUMMARY');

  const ReminderKind(this.apiValue);

  final String apiValue;

  String get payload => name;

  static ReminderKind? fromPayload(String? value) =>
      value == null ? null : values.asNameMap()[value];

  static ReminderKind? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
