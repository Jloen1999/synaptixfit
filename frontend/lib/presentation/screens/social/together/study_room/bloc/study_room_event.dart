part of 'study_room_bloc.dart';

@freezed
sealed class StudyRoomEvent with _$StudyRoomEvent {
  const factory StudyRoomEvent.started(String id) = StudyRoomStarted;

  /// Consulta periódica (y al acabar la cuenta atrás de una fase).
  const factory StudyRoomEvent.polled() = StudyRoomPolled;

  /// «Unirme» (o «Deshacer» tras salir).
  const factory StudyRoomEvent.joined() = StudyRoomJoined;

  const factory StudyRoomEvent.declined() = StudyRoomDeclined;

  /// «Salir de la sala»: se aplaza hasta que se cierra el aviso.
  const factory StudyRoomEvent.left() = StudyRoomLeft;

  /// «Deshacer» en el aviso de salir: se sigue dentro, sin tocar el servidor.
  const factory StudyRoomEvent.leaveUndone() = StudyRoomLeaveUndone;

  /// El aviso de salir se cerró: ahora se sale de verdad.
  const factory StudyRoomEvent.leaveCommitted() = StudyRoomLeaveCommitted;

  /// «Empezar»: el temporizador común arranca para todos.
  const factory StudyRoomEvent.startRequested() = StudyRoomStartRequested;

  /// Mi asignatura para las rondas (`null`: ninguna).
  const factory StudyRoomEvent.subjectChosen(String? subjectId) =
      StudyRoomSubjectChosen;

  const factory StudyRoomEvent.reacted(StudyRoomReaction reaction) =
      StudyRoomReacted;
}
