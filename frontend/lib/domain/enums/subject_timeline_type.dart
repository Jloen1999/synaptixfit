/// Tipo de elemento de la línea de tiempo de una asignatura (bloques del
/// calendario y entregas o exámenes).
enum SubjectTimelineType {
  study,
  classSession,
  review,
  exam,
  assignment,
  presentation,
  other;

  /// Traduce el `kind` + `blockType`/`deadlineType` de la API.
  static SubjectTimelineType fromApi({
    required String? kind,
    String? blockType,
    String? deadlineType,
  }) {
    if (kind == 'DEADLINE') {
      return switch (deadlineType) {
        'EXAM' => SubjectTimelineType.exam,
        'ASSIGNMENT' => SubjectTimelineType.assignment,
        'PRESENTATION' => SubjectTimelineType.presentation,
        _ => SubjectTimelineType.other,
      };
    }
    return switch (blockType) {
      'STUDY' => SubjectTimelineType.study,
      'CLASS' => SubjectTimelineType.classSession,
      'REVIEW' => SubjectTimelineType.review,
      'EXAM' => SubjectTimelineType.exam,
      'DELIVERY' => SubjectTimelineType.assignment,
      _ => SubjectTimelineType.other,
    };
  }
}
