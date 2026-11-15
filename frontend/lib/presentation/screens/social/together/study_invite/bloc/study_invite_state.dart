part of 'study_invite_bloc.dart';

@freezed
abstract class StudyInviteState with _$StudyInviteState {
  const factory StudyInviteState({
    @Default(StudyRoomLength.short) StudyRoomLength length,

    /// Dos rondas por defecto: una hora con el descanso, lo habitual.
    @Default(2) int rounds,
    String? subjectId,
    @Default(false) bool saving,

    /// Sala creada (efecto de un solo uso: se abre).
    StudyRoom? created,
    AppError? error,
  }) = _StudyInviteState;
}
