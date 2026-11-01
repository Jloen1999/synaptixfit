part of 'reminders_bloc.dart';

@freezed
sealed class RemindersEvent with _$RemindersEvent {
  /// Entrada en el armazón con el enfoque de la cuenta y los textos ya
  /// traducidos. El enfoque solo sirve para saber cuándo cambia: el plan ya
  /// llega filtrado del servidor.
  const factory RemindersEvent.started({
    required UsageFocus focus,
    required ReminderTexts texts,
  }) = RemindersStarted;

  /// La cuenta ha cambiado de enfoque (estudio, deporte o ambos): el plan del
  /// servidor cambia y hay que reprogramar.
  const factory RemindersEvent.focusChanged(UsageFocus focus) =
      RemindersFocusChanged;

  /// Han cambiado datos o la preferencia del dispositivo: reprogramar.
  const factory RemindersEvent.syncRequested() = RemindersSyncRequested;

  /// Se ha cerrado la sesión: borrar los avisos de este usuario.
  const factory RemindersEvent.signedOut() = RemindersSignedOut;

  /// El usuario ha tocado un aviso.
  const factory RemindersEvent.opened(OpenedReminder reminder) =
      RemindersOpened;

  /// La página ya ha navegado al destino del aviso.
  const factory RemindersEvent.openHandled() = RemindersOpenHandled;

  /// Se ha guardado algo de estudio o del planificador: ¿toca ofrecer los
  /// recordatorios?
  const factory RemindersEvent.offerCheckRequested() =
      RemindersOfferCheckRequested;

  /// Respuesta al ofrecimiento ([accepted]: activar y pedir permiso).
  const factory RemindersEvent.offerAnswered({required bool accepted}) =
      RemindersOfferAnswered;
}
