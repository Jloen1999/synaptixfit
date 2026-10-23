import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Registra una ronda de flashcards.
abstract interface class ReviewFlashcardsUseCaseContract {
  Future<AppResult<FlashcardReviewResult>> call(
    String materialId, {
    required int mastered,
    required int doubtful,
    required int failed,
  });
}

class ReviewFlashcardsUseCase implements ReviewFlashcardsUseCaseContract {
  const ReviewFlashcardsUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<FlashcardReviewResult>> call(
    String materialId, {
    required int mastered,
    required int doubtful,
    required int failed,
  }) => _repository.reviewFlashcards(
    materialId,
    mastered: mastered,
    doubtful: doubtful,
    failed: failed,
  );
}
