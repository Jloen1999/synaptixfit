part of 'shared_notes_bloc.dart';

@freezed
sealed class SharedNotesEvent with _$SharedNotesEvent {
  const factory SharedNotesEvent.started({
    @Default(SharedNotesScope.all) SharedNotesScope scope,
    String? authorId,
  }) = SharedNotesStarted;

  const factory SharedNotesEvent.refreshed() = SharedNotesRefreshed;

  const factory SharedNotesEvent.moreRequested() = SharedNotesMoreRequested;
}
