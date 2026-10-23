part of 'subject_selector_bloc.dart';

enum SubjectSelectorStatus { loading, ready, failure }

@freezed
abstract class SubjectSelectorState with _$SubjectSelectorState {
  const factory SubjectSelectorState({
    @Default(SubjectSelectorStatus.loading) SubjectSelectorStatus status,
    @Default(<CatalogSubject>[]) List<CatalogSubject> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    int? course,
    int? semester,
    @Default('') String query,
    @Default(<String>{}) Set<String> selected,
    @Default(false) bool submitting,

    /// Asignaturas creadas en el último alta (señal de éxito).
    int? addedCount,
    AppError? error,
    AppError? actionError,
  }) = _SubjectSelectorState;
}
