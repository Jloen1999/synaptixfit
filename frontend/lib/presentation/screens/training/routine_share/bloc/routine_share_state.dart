part of 'routine_share_bloc.dart';

enum RoutineShareStatus { loading, ready, failure }

@freezed
abstract class RoutineShareState with _$RoutineShareState {
  const factory RoutineShareState({
    @Default('') String routineId,
    @Default(RoutineShareStatus.loading) RoutineShareStatus status,

    /// Hasta cuándo vale el último enlace; `null` si no se comparte.
    DateTime? sharedUntil,

    /// Creando un enlace o dejando de compartir.
    @Default(false) bool busy,
    AppError? error,

    /// Fallo de la última acción; se pinta en la hoja hasta la siguiente.
    AppError? actionError,

    /// Se acaba de dejar de compartir (efecto de un solo uso: aviso).
    @Default(false) bool stopped,
  }) = _RoutineShareState;

  const RoutineShareState._();

  bool get isShared => sharedUntil != null;
}
