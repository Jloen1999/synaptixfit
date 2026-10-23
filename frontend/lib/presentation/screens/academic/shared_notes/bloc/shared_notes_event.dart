part of 'shared_notes_bloc.dart';

@freezed
sealed class SharedNotesEvent with _$SharedNotesEvent {
  const factory SharedNotesEvent.started() = SharedNotesStarted;

  const factory SharedNotesEvent.moreRequested() = SharedNotesMoreRequested;
}
