part of 'subject_practice_bloc.dart';

@freezed
sealed class SubjectPracticeEvent with _$SubjectPracticeEvent {
  const factory SubjectPracticeEvent.started(String subjectId) =
      SubjectPracticeStarted;

  /// Vuelve a leer sin esqueleto (al volver de practicar o cerrar una pregunta).
  const factory SubjectPracticeEvent.refreshed() = SubjectPracticeRefreshed;

  const factory SubjectPracticeEvent.queryChanged(String query) =
      SubjectPracticeQueryChanged;

  const factory SubjectPracticeEvent.standingChanged(
    PracticeListFilter filter,
  ) = SubjectPracticeStandingChanged;

  /// `null`: todos los tipos.
  const factory SubjectPracticeEvent.typeChanged(QuestionType? type) =
      SubjectPracticeTypeChanged;

  /// `null`: todos los temas (apuntes y archivos).
  const factory SubjectPracticeEvent.materialChanged(String? materialId) =
      SubjectPracticeMaterialChanged;

  const factory SubjectPracticeEvent.filtersCleared() =
      SubjectPracticeFiltersCleared;

  /// Contesta una pregunta de la lista (corrige el servidor).
  const factory SubjectPracticeEvent.answered({
    required String questionId,
    required String answer,
  }) = SubjectPracticeAnswered;

  /// «No lo sé» a una pregunta de la lista (ADR 0063).
  const factory SubjectPracticeEvent.dontKnow(String questionId) =
      SubjectPracticeDontKnow;
}
