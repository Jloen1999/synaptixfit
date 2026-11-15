part of 'study_invite_bloc.dart';

@freezed
sealed class StudyInviteEvent with _$StudyInviteEvent {
  /// Lo que trae el Pomodoro: sus minutos y su asignatura (opcionales).
  const factory StudyInviteEvent.started({
    StudyRoomTimes? times,
    String? subjectId,
  }) = StudyInviteStarted;

  /// Minutos de concentración y descanso de cada ronda (atajo o a medida).
  const factory StudyInviteEvent.timesChosen(StudyRoomTimes times) =
      StudyInviteTimesChosen;

  const factory StudyInviteEvent.roundsChosen(int rounds) =
      StudyInviteRoundsChosen;

  const factory StudyInviteEvent.submitted(List<String> friendIds) =
      StudyInviteSubmitted;
}
