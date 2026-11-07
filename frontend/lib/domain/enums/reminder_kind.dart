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
  weeklySummary('WEEKLY_SUMMARY'),

  /// «Tocaba ayer»: el día de rutina previsto pasó sin entrenar.
  routineDayMissed('ROUTINE_DAY_MISSED'),

  /// «¿Terminaste la sesión?»: sesión abierta horas después de empezar.
  openSession('OPEN_SESSION'),

  /// «Tu reto vence mañana».
  challengeDue('CHALLENGE_DUE'),

  /// «Tu racha está en riesgo»: hoy aún no hay actividad (por la tarde).
  streakAtRisk('STREAK_AT_RISK'),

  /// «¿Qué tal estás hoy?»: el registro diario, por la mañana.
  checkIn('CHECK_IN'),

  /// Clase a punto de empezar, con el aula (la antelación la elige la persona).
  classSoon('CLASS_SOON'),

  /// Evento personal (dentista, trabajo…) a punto de empezar.
  personalEvent('PERSONAL_EVENT'),

  /// Tarea de reto con fecha que ningún otro aviso menciona (ADR 0035).
  challengeTask('CHALLENGE_TASK'),

  /// Resumen de la mañana: lo que trae el día; solo si hay algo (ADR 0035).
  morningSummary('MORNING_SUMMARY');

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
