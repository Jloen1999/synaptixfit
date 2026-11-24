part of 'subject_practice_bloc.dart';

/// Filtro de la lista por cómo va cada pregunta («Por repasar» junta «No lo
/// sé» y falladas, como `QuestionStanding.toReview`).
enum PracticeListFilter {
  all,
  toReview,
  fresh,
  correct;

  bool matches(QuestionStanding standing) => switch (this) {
    all => true,
    toReview => standing.toReview,
    fresh => standing == QuestionStanding.fresh,
    correct => standing == QuestionStanding.correct,
  };
}

/// Tema (apunte o archivo) con preguntas en la asignatura.
typedef PracticeMaterial = ({
  String id,
  String title,
  int count,
  int toReview,
});

@freezed
abstract class SubjectPracticeState with _$SubjectPracticeState {
  const factory SubjectPracticeState({
    @Default('') String subjectId,
    @Default(true) bool loading,
    AppError? error,
    SubjectQuestions? questions,

    /// Repasos de hoy de esta asignatura (el más antiguo primero).
    @Default(<StudyMaterial>[]) List<StudyMaterial> due,
    @Default('') String query,
    @Default(PracticeListFilter.all) PracticeListFilter standing,
    QuestionType? type,
    String? materialId,

    /// Respuestas ya mandadas y su corrección, por id de pregunta.
    @Default(<String, String>{}) Map<String, String> answers,
    @Default(<String, AnswerResult>{}) Map<String, AnswerResult> results,

    /// Pregunta que se está corrigiendo.
    String? checkingId,
    AppError? actionError,
  }) = _SubjectPracticeState;

  const SubjectPracticeState._();

  List<SubjectQuestion> get all => questions?.questions ?? const [];

  /// Lista filtrada, en el orden del servidor (las que vuelven antes primero).
  List<SubjectQuestion> get visible {
    final q = query.trim().toLowerCase();
    return [
      for (final item in all)
        if (standing.matches(item.standing) &&
            (type == null || item.question.type == type) &&
            (materialId == null || item.materialId == materialId) &&
            (q.isEmpty ||
                item.question.statement.toLowerCase().contains(q) ||
                item.materialTitle.toLowerCase().contains(q)))
          item,
    ];
  }

  /// Temas con preguntas, en el orden en que aparecen (el más urgente antes).
  List<PracticeMaterial> get materials {
    final order = <String>[];
    final titles = <String, String>{};
    final counts = <String, int>{};
    final review = <String, int>{};
    for (final item in all) {
      if (!titles.containsKey(item.materialId)) order.add(item.materialId);
      titles[item.materialId] = item.materialTitle;
      counts.update(item.materialId, (c) => c + 1, ifAbsent: () => 1);
      if (item.standing.toReview) {
        review.update(item.materialId, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    return [
      for (final id in order)
        (
          id: id,
          title: titles[id]!,
          count: counts[id]!,
          toReview: review[id] ?? 0,
        ),
    ];
  }

  /// Tipos de pregunta que hay (el filtro de tipo solo sale si hay varios).
  List<QuestionType> get types => [
    for (final t in QuestionType.values)
      if (all.any((i) => i.question.type == t)) t,
  ];

  bool get filtered =>
      query.trim().isNotEmpty ||
      standing != PracticeListFilter.all ||
      type != null ||
      materialId != null;
}
