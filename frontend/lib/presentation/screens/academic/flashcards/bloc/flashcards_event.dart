part of 'flashcards_bloc.dart';

@freezed
sealed class FlashcardsEvent with _$FlashcardsEvent {
  const factory FlashcardsEvent.started(String materialId) = FlashcardsStarted;

  /// Gira la tarjeta para ver la respuesta (o volver a la pregunta).
  const factory FlashcardsEvent.flipped() = FlashcardsFlipped;

  const factory FlashcardsEvent.rated(FlashcardRating rating) = FlashcardsRated;

  const factory FlashcardsEvent.restarted() = FlashcardsRestarted;

  /// Reintenta registrar la ronda si falló el envío.
  const factory FlashcardsEvent.submitRetried() = FlashcardsSubmitRetried;
}
