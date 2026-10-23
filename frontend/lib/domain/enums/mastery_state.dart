/// Estado de dominio de un material en el repaso espaciado.
enum MasteryState {
  notEvaluated('NOT_EVALUATED'),
  inProgress('IN_PROGRESS'),
  mastered('MASTERED'),
  needsReview('NEEDS_REVIEW'),
  abandoned('ABANDONED');

  const MasteryState(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static MasteryState fromApi(String? value) => MasteryState.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => MasteryState.notEvaluated,
  );
}
