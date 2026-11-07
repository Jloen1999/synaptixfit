part of 'shared_notes_bloc.dart';

@freezed
sealed class SharedNotesEvent with _$SharedNotesEvent {
  const factory SharedNotesEvent.started({
    @Default(SharedNotesScope.all) SharedNotesScope scope,
    String? authorId,
  }) = SharedNotesStarted;

  const factory SharedNotesEvent.refreshed() = SharedNotesRefreshed;

  /// Texto buscado (ya con la espera de teclear); vacío quita la búsqueda.
  const factory SharedNotesEvent.searchChanged(String search) =
      SharedNotesSearchChanged;

  const factory SharedNotesEvent.moreRequested() = SharedNotesMoreRequested;
}
