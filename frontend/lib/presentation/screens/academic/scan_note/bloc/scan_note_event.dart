part of 'scan_note_bloc.dart';

@freezed
sealed class ScanNoteEvent with _$ScanNoteEvent {
  const factory ScanNoteEvent.started({String? subjectId}) = ScanNoteStarted;

  const factory ScanNoteEvent.submitted({
    required String title,
    required String text,
    String? subjectId,
  }) = ScanNoteSubmitted;
}
