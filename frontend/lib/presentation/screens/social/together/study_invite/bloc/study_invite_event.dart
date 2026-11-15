part of 'study_invite_bloc.dart';

@freezed
sealed class StudyInviteEvent with _$StudyInviteEvent {
  /// Lo que trae el Pomodoro: su duración y su asignatura (opcionales).
  const factory StudyInviteEvent.started({
    StudyRoomLength? length,
    String? subjectId,
  }) = StudyInviteStarted;

  const factory StudyInviteEvent.lengthChosen(StudyRoomLength length) =
      StudyInviteLengthChosen;

  const factory StudyInviteEvent.roundsChosen(int rounds) =
      StudyInviteRoundsChosen;

  const factory StudyInviteEvent.submitted(List<String> friendIds) =
      StudyInviteSubmitted;
}
