part of 'study_invite_bloc.dart';

@freezed
abstract class StudyInviteState with _$StudyInviteState {
  const factory StudyInviteState({
    /// 25 + 5, el Pomodoro clásico, hasta que se elija otra cosa.
    @Default(StudyRoomTimes(focusMinutes: 25, breakMinutes: 5))
    StudyRoomTimes times,

    /// Dos rondas por defecto: una hora con el descanso, lo habitual.
    @Default(2) int rounds,
    String? subjectId,
    @Default(false) bool saving,

    /// Sala creada (efecto de un solo uso: se abre).
    StudyRoom? created,
    AppError? error,
  }) = _StudyInviteState;
}
