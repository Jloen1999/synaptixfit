part of 'wod_live_bloc.dart';

@freezed
sealed class WodLiveEvent with _$WodLiveEvent {
  const factory WodLiveEvent.started(Wod wod, WodDivision division) =
      WodLiveStarted;

  /// Un tic del reloj: recalcula los segundos activos.
  const factory WodLiveEvent.ticked() = WodLiveTicked;

  const factory WodLiveEvent.pauseToggled() = WodLivePauseToggled;

  const factory WodLiveEvent.finishRequested() = WodLiveFinishRequested;

  /// Se cerró la hoja de la marca sin guardar: se puede seguir.
  const factory WodLiveEvent.resumed() = WodLiveResumed;

  const factory WodLiveEvent.resultSubmitted(Wod wod, WodResultDraft draft) =
      WodLiveResultSubmitted;
}
