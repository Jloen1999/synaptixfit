part of 'study_room_bloc.dart';

enum StudyRoomStatus { loading, ready, failure }

@freezed
abstract class StudyRoomState with _$StudyRoomState {
  const factory StudyRoomState({
    String? id,
    @Default(StudyRoomStatus.loading) StudyRoomStatus status,
    StudyRoom? room,
    AppError? error,

    /// Hora del servidor − hora del móvil en la última lectura.
    @Default(Duration.zero) Duration clockOffset,

    /// Topes de la sala (minutos y atajos) para «Cambiar tiempos»; nulos
    /// hasta que llegan (o si fallan: entonces no se ofrece).
    TogetherLimits? limits,

    /// Mis asignaturas, para elegir con cuál cuentan las rondas.
    @Default(<SubjectOption>[]) List<SubjectOption> subjects,
    @Default(false) bool busy,

    /// La acción en curso es cambiar los minutos: «Empezar» no enseña su
    /// carga como si arrancara la sala.
    @Default(false) bool changingTimes,

    /// Ha dicho que no a la invitación: la pantalla se cierra.
    @Default(false) bool closed,

    /// Acaba de pulsar «Salir» (efecto de un solo uso: aviso con «Deshacer»).
    @Default(false) bool left,

    /// Salida aplazada mientras se ve el aviso: la pantalla ya no ofrece
    /// acciones de dentro.
    @Default(false) bool leaving,
    AppError? actionError,
  }) = _StudyRoomState;

  const StudyRoomState._();

  /// Estoy dentro y no me estoy yendo: puedo reaccionar, elegir asignatura y
  /// salir.
  bool get inside => (room?.joined ?? false) && !leaving;

  /// Lo que falta de la fase en curso con el reloj del móvil corregido; nulo
  /// si la fase no tiene final (sala terminada).
  Duration? remainingAt(DateTime deviceNow) {
    final ends = room?.phaseEndsAt;
    if (ends == null) return null;
    final left = ends.difference(deviceNow.add(clockOffset));
    return left.isNegative ? Duration.zero : left;
  }
}
