/// Tipo de un evento de hoy (bloques del calendario y entregas).
enum HomeEventType {
  study,
  classSession,
  review,
  sport,
  rest,
  meal,
  sleep,
  exam,
  delivery,
  presentation,
  other;

  static HomeEventType fromApi(String? value) => switch (value) {
    'STUDY' => study,
    'CLASS' => classSession,
    'REVIEW' => review,
    'SPORT' => sport,
    'REST' => rest,
    'MEAL' => meal,
    'SLEEP' => sleep,
    'EXAM' => exam,
    'DELIVERY' => delivery,
    'PRESENTATION' => presentation,
    _ => other,
  };
}
