part of 'together_live_bloc.dart';

@freezed
sealed class TogetherLiveEvent with _$TogetherLiveEvent {
  /// Se entra en el armazón (la app está en primer plano).
  const factory TogetherLiveEvent.started() = TogetherLiveStarted;

  /// La app vuelve a primer plano: se abre el canal otra vez.
  const factory TogetherLiveEvent.foregrounded() = TogetherLiveForegrounded;

  /// La app pasa a segundo plano: se cierra el canal (sin push, ADR 0047).
  const factory TogetherLiveEvent.backgrounded() = TogetherLiveBackgrounded;

  const factory TogetherLiveEvent.signalReceived(TogetherLiveSignal signal) =
      TogetherLiveSignalReceived;

  /// El canal se cortó o falló.
  const factory TogetherLiveEvent.dropped() = TogetherLiveDropped;

  const factory TogetherLiveEvent.reconnectDue() = TogetherLiveReconnectDue;
}
