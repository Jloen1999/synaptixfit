/// Qué mide un reto que se cuenta solo (ADR 0043). Lo decide el servidor; el
/// cliente solo elige el texto de cada uno.
enum ChallengeRuleMetric {
  reviews('REVIEWS'),
  focusMinutes('FOCUS_MINUTES'),
  earlyFocus('EARLY_FOCUS'),
  workouts('WORKOUTS'),
  studyAndMove('STUDY_AND_MOVE'),
  tests('TESTS'),
  checkIns('CHECK_INS'),
  plannedWeeks('PLANNED_WEEKS'),
  runs('RUNS'),
  unknown('');

  const ChallengeRuleMetric(this.apiValue);

  final String apiValue;

  static ChallengeRuleMetric fromApi(String? value) =>
      values.firstWhere((m) => m.apiValue == value, orElse: () => unknown);
}

/// Cómo se cuenta un reto que se cuenta solo: días, semanas o la suma.
enum ChallengeRuleUnit {
  day('DAY'),
  week('WEEK'),
  total('TOTAL');

  const ChallengeRuleUnit(this.apiValue);

  final String apiValue;

  static ChallengeRuleUnit fromApi(String? value) =>
      values.firstWhere((u) => u.apiValue == value, orElse: () => total);
}
