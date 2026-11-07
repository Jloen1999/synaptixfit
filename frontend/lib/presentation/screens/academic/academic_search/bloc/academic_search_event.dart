part of 'academic_search_bloc.dart';

@freezed
sealed class AcademicSearchEvent with _$AcademicSearchEvent {
  /// Texto escrito (ya con la espera de teclear aplicada).
  const factory AcademicSearchEvent.queryChanged(String query) =
      AcademicSearchQueryChanged;

  /// «Reintentar» tras un fallo.
  const factory AcademicSearchEvent.retried() = AcademicSearchRetried;
}
