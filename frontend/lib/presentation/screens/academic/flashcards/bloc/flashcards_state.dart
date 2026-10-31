part of 'flashcards_bloc.dart';

/// Clasificación de una tarjeta.
enum FlashcardRating { mastered, doubtful, failed }

@freezed
abstract class FlashcardsState with _$FlashcardsState {
  const factory FlashcardsState({
    @Default('') String materialId,
    @Default(true) bool loading,
    AppError? error,
    @Default(<Question>[]) List<Question> cards,
    @Default(0) int index,
    @Default(false) bool flipped,
    @Default(<FlashcardRating>[]) List<FlashcardRating> ratings,
    @Default(false) bool submitting,
    AppError? actionError,
    FlashcardReviewResult? result,
    Account? updatedAccount,

    /// Título del material: nombre del mazo de Anki.
    String? deckName,
    @Default(false) bool exportingAnki,

    /// Sube con cada mazo guardado (el aviso se muestra al cambiar).
    @Default(0) int ankiExports,
  }) = _FlashcardsState;

  const FlashcardsState._();

  Question? get current => index < cards.length ? cards[index] : null;

  bool get finished => cards.isNotEmpty && ratings.length >= cards.length;

  int count(FlashcardRating rating) => ratings.where((r) => r == rating).length;
}
