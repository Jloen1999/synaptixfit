/// Enums del módulo planner. Cada uno sabe convertirse desde/hacia el valor
/// UPPER_SNAKE_CASE de la API.
library;

/// Tipo de evento del calendario. La persona lo ve por su nombre («Estudio»,
/// «Personal»…) o, en genérico, como «evento» (`docs/05-design/vocabulario.md`).
enum BlockType {
  study('STUDY'),
  sport('SPORT'),
  classSession('CLASS'),
  rest('REST'),
  meal('MEAL'),
  sleep('SLEEP'),
  exam('EXAM'),
  delivery('DELIVERY'),
  review('REVIEW'),

  /// El día a día que no es estudio ni deporte (médico, trabajo, recados…),
  /// con nombre libre. Sin XP ni carga de estudio; se ve con cualquier modo
  /// de uso (ADR 0035; lo decide `ActivityType` del servidor).
  personal('PERSONAL');

  const BlockType(this.apiValue);

  final String apiValue;

  /// Exámenes y entregas generan su entrega asociada.
  bool get createsDeadline => this == exam || this == delivery;

  /// Tipos que suelen ir ligados a una asignatura.
  bool get usesSubject =>
      this == study ||
      this == classSession ||
      this == exam ||
      this == delivery ||
      this == review;

  static BlockType fromApi(String? value) => BlockType.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => BlockType.study,
  );

  /// Se ofrece «Repetir cada semana» (exámenes y entregas no; mismo criterio
  /// que `ActivityType.canRepeatWeekly` del servidor, que es quien decide).
  bool get canRepeatWeekly =>
      this != BlockType.exam && this != BlockType.delivery;

  /// Estudio o repaso: se puede abrir el Pomodoro desde el bloque.
  bool get isStudy => this == BlockType.study || this == BlockType.review;

  /// Cómo se pide la hora en el editor: una entrega es un momento (la hora
  /// límite); examen, comida y descanso tienen duraciones típicas; el resto,
  /// inicio y fin.
  BlockTimeInput get timeInput => switch (this) {
    delivery => BlockTimeInput.moment,
    exam || meal || rest => BlockTimeInput.duration,
    _ => BlockTimeInput.range,
  };

  /// Duraciones que se ofrecen (minutos) con [BlockTimeInput.duration]; la
  /// propuesta es [defaultDuration]. Nunca menos de 30 min, el
  /// mínimo de un bloque.
  List<int> get durationOptions => switch (this) {
    exam => const [60, 90, 120, 180],
    meal => const [30, 45, 60, 90],
    rest => const [30, 45, 60],
    _ => const [],
  };

  int get defaultDuration => switch (this) {
    exam => 120,
    meal => 45,
    rest => 30,
    delivery => momentDurationMinutes,
    _ => 60,
  };

  /// Hueco que ocupa en el calendario una entrega (termina a su hora límite).
  static const momentDurationMinutes = 30;

  /// Minuto de inicio real: una entrega ocupa la media hora anterior a su
  /// hora límite ([endMin]); el resto empieza donde se eligió.
  int startMinuteFor(int startMin, int endMin) =>
      timeInput == BlockTimeInput.moment
      ? (endMin - momentDurationMinutes).clamp(0, endMin)
      : startMin;

  /// Temas o notas: lo que se va a estudiar, repasar o entra en el examen. En
  /// un evento personal es su nombre («Dentista»).
  bool get usesTopics =>
      this == study ||
      this == review ||
      this == exam ||
      this == classSession ||
      this == personal;

  /// Necesita un nombre propio (va en los temas): lo valida también el servidor.
  bool get requiresName => this == personal;

  /// Lugar: donde hay que ir (aula, biblioteca, gimnasio, consulta).
  bool get usesLocation =>
      this == study ||
      this == classSession ||
      this == exam ||
      this == sport ||
      this == personal;

  /// Prioridad: lo que compite por el tiempo (no clases, comidas ni sueño).
  bool get usesPriority =>
      this == study ||
      this == review ||
      this == exam ||
      this == delivery ||
      this == sport;

  /// Se puede vincular a un reto.
  bool get usesChallenge =>
      this == study ||
      this == review ||
      this == sport ||
      this == exam ||
      this == delivery;

  /// Se puede vincular a una entrega o examen.
  bool get usesDeadlineLink =>
      this == study || this == review || this == exam || this == delivery;
}

/// Forma de pedir la hora de un bloque en el editor (ver [BlockType.timeInput]).
enum BlockTimeInput { range, duration, moment }

/// Prioridad de un bloque o dificultad de una entrega.
enum PlannerPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const PlannerPriority(this.apiValue);

  final String apiValue;

  static PlannerPriority? fromApiOrNull(String? value) {
    for (final v in PlannerPriority.values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}

/// Teoría o práctica (solo clases).
enum ClassKind {
  theory('THEORY'),
  practice('PRACTICE');

  const ClassKind(this.apiValue);

  final String apiValue;

  static ClassKind? fromApiOrNull(String? value) {
    for (final v in ClassKind.values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}

/// Tipo de entrega o evaluación.
enum DeadlineType {
  exam('EXAM'),
  assignment('ASSIGNMENT'),
  presentation('PRESENTATION'),
  other('OTHER');

  const DeadlineType(this.apiValue);

  final String apiValue;

  static DeadlineType fromApi(String? value) => DeadlineType.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => DeadlineType.other,
  );
}

/// Estado del balance estudio/deporte de la semana.
enum BalanceState {
  inactive('INACTIVE'),
  balanced('BALANCED'),
  studyHeavy('STUDY_HEAVY'),
  sportHeavy('SPORT_HEAVY');

  const BalanceState(this.apiValue);

  final String apiValue;

  static BalanceState fromApi(String? value) => BalanceState.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => BalanceState.inactive,
  );
}

/// Origen de una propuesta semanal.
enum SuggestionSource {
  ai('AI'),
  heuristic('HEURISTIC');

  const SuggestionSource(this.apiValue);

  final String apiValue;

  static SuggestionSource fromApi(String? value) =>
      value == 'AI' ? SuggestionSource.ai : SuggestionSource.heuristic;
}

/// Coincidencia del calendario ICS con la asignatura.
enum IcsMatch {
  full('FULL'),
  partial('PARTIAL'),
  none('NONE');

  const IcsMatch(this.apiValue);

  final String apiValue;

  static IcsMatch fromApi(String? value) => IcsMatch.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => IcsMatch.none,
  );
}

/// Fase del temporizador Pomodoro.
enum FocusPhase {
  focus('FOCUS'),
  shortBreak('SHORT_BREAK'),
  longBreak('LONG_BREAK');

  const FocusPhase(this.apiValue);

  final String apiValue;

  bool get isBreak => this != focus;

  static FocusPhase fromApi(String? value) => FocusPhase.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => FocusPhase.focus,
  );
}

/// Elemento de la línea de tiempo: bloque o entrega.
enum TimelineKind {
  block('BLOCK'),
  deadline('DEADLINE');

  const TimelineKind(this.apiValue);

  final String apiValue;

  static TimelineKind fromApi(String? value) =>
      value == 'DEADLINE' ? TimelineKind.deadline : TimelineKind.block;
}

/// Qué pasó con la XP al registrar una fase Pomodoro. Lo decide el servidor,
/// que es quien conoce la duración mínima premiada y el tope diario.
enum FocusXpStatus {
  awarded('AWARDED'),
  dailyCapReached('DAILY_CAP_REACHED'),
  notEligible('NOT_ELIGIBLE');

  const FocusXpStatus(this.apiValue);

  final String apiValue;

  static FocusXpStatus fromApi(String? value) => FocusXpStatus.values
      .firstWhere((v) => v.apiValue == value, orElse: () => notEligible);
}
