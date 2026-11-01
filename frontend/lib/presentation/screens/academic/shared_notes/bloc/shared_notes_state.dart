part of 'shared_notes_bloc.dart';

@freezed
abstract class SharedNotesState with _$SharedNotesState {
  const factory SharedNotesState({
    @Default(SharedNotesScope.all) SharedNotesScope scope,
    String? authorId,
    @Default(true) bool loading,
    AppError? error,
    @Default(<SharedNoteSummary>[]) List<SharedNoteSummary> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,

    /// Error al pedir la página siguiente (se reintenta desde el final).
    AppError? loadMoreError,

    /// Recarga en curso (tirar para actualizar).
    @Default(false) bool refreshing,
  }) = _SharedNotesState;
}
