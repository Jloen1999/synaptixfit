part of 'past_study_bloc.dart';

@freezed
sealed class PastStudyEvent with _$PastStudyEvent {
  /// Carga las asignaturas para elegir.
  const factory PastStudyEvent.started() = PastStudyStarted;

  const factory PastStudyEvent.submitted({
    required DateTime start,
    required int minutes,
    String? subjectId,
    String? title,
  }) = PastStudySubmitted;
}
