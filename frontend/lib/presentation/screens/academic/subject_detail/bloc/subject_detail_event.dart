part of 'subject_detail_bloc.dart';

@freezed
sealed class SubjectDetailEvent with _$SubjectDetailEvent {
  const factory SubjectDetailEvent.started(String subjectId) =
      SubjectDetailStarted;

  const factory SubjectDetailEvent.refreshed() = SubjectDetailRefreshed;

  const factory SubjectDetailEvent.archiveToggled() =
      SubjectDetailArchiveToggled;

  const factory SubjectDetailEvent.deleteRequested() =
      SubjectDetailDeleteRequested;
}
