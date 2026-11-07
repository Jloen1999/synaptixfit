part of 'academic_search_bloc.dart';

/// [idle]: aún no hay texto suficiente para buscar.
enum AcademicSearchStatus { idle, loading, ready, failure }

@freezed
abstract class AcademicSearchState with _$AcademicSearchState {
  const factory AcademicSearchState({
    @Default('') String query,
    @Default(AcademicSearchStatus.idle) AcademicSearchStatus status,
    AcademicSearchResult? result,
    AppError? error,
  }) = _AcademicSearchState;
}
