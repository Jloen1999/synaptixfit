part of 'wod_live_bloc.dart';

enum WodLiveStatus { idle, running, paused, finished }

@freezed
abstract class WodLiveState with _$WodLiveState {
  const factory WodLiveState({
    Wod? wod,
    @Default(WodDivision.rx) WodDivision division,
    @Default(WodLiveStatus.idle) WodLiveStatus status,

    /// Segundos activos (sin pausas).
    @Default(0) int elapsedSeconds,

    /// Terminó porque se acabó el tiempo, no porque se tocó «Terminar».
    @Default(false) bool timeUp,
    @Default(false) bool saving,
    WodMark? saved,
    AppError? error,
  }) = _WodLiveState;

  const WodLiveState._();

  /// Lo que enseña el reloj ahora; nulo sin WOD.
  WodTick? get tick =>
      wod == null ? null : WodTimer.of(wod!).at(elapsedSeconds);

  /// Hay una cuenta que se perdería al salir.
  bool get inProgress => saved == null && status != WodLiveStatus.idle;
}
