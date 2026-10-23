part of 'scan_note_bloc.dart';

@freezed
abstract class ScanNoteState with _$ScanNoteState {
  const factory ScanNoteState({
    @Default(true) bool loading,
    @Default(<Subject>[]) List<Subject> subjects,
    String? initialSubjectId,
    @Default(false) bool saving,
    AppError? saveError,
    String? savedNoteId,
  }) = _ScanNoteState;
}
