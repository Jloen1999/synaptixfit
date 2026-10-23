/// Tipo de evento de la línea de tiempo de un usuario.
enum AdminTimelineType {
  accountCreated,
  trainingSession,
  routineCreated,
  challengeCreated,
  challengeCompleted,
  badgeEarned,
  studyBlockCompleted,
  deadlineCompleted,
  noteCreated,
  focusSession,
  postPublished,
  commentPosted,
  adminAction;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminTimelineType fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminTimelineType.adminAction,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminTimelineType> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
