part of 'study_room_bar_bloc.dart';

@freezed
sealed class StudyRoomBarEvent with _$StudyRoomBarEvent {
  /// La pantalla de la sala acaba de leerla: [clockOffset] es la hora del
  /// servidor − la del móvil en esa lectura; [texts], los del aviso.
  const factory StudyRoomBarEvent.seen({
    required StudyRoom room,
    required Duration clockOffset,
    StudyRoomAlertTexts? texts,
  }) = StudyRoomBarSeen;

  /// Ya no estoy en la sala [roomId] (salí, dije que no o me sacaron).
  const factory StudyRoomBarEvent.cleared(String roomId) = StudyRoomBarCleared;

  const factory StudyRoomBarEvent.ticked() = StudyRoomBarTicked;

  /// El canal en directo avisa de que una sala cambió (ADR 0047).
  const factory StudyRoomBarEvent.liveChanged() = StudyRoomBarLiveChanged;

  /// Al cerrar sesión: fuera la barra y el aviso.
  const factory StudyRoomBarEvent.signedOut() = StudyRoomBarSignedOut;
}
