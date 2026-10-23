part of 'shared_notes_bloc.dart';

@freezed
abstract class SharedNotesState with _$SharedNotesState {
  const factory SharedNotesState({
    @Default(true) bool loading,
    AppError? error,
    @Default(<SharedNote>[]) List<SharedNote> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
  }) = _SharedNotesState;
}
