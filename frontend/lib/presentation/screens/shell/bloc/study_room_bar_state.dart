part of 'study_room_bar_bloc.dart';

@freezed
abstract class StudyRoomBarState with _$StudyRoomBarState {
  const factory StudyRoomBarState({
    /// Sala en la que estoy; nula si ninguna (la barra no ocupa nada).
    String? roomId,
    StudyRoomPhase? phase,
    @Default(0) int round,
    @Default(0) int rounds,

    /// Hora del móvil en la que acaba la fase; nula esperando a empezar.
    DateTime? endsAt,

    /// Segundos que quedan de la fase; nulo si no tiene cuenta atrás.
    int? remainingSeconds,
  }) = _StudyRoomBarState;
}
