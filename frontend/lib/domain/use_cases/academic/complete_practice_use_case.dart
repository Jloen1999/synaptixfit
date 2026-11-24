import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Cierra la práctica libre y otorga la XP; [dontKnow] son las preguntas
/// contestadas con «No lo sé» (ADR 0063).
abstract interface class CompletePracticeUseCaseContract {
  Future<AppResult<PracticeResult>> call(
    String bankId,
    Map<String, String> answers, {
    Set<String> dontKnow,
  });
}

class CompletePracticeUseCase implements CompletePracticeUseCaseContract {
  const CompletePracticeUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<PracticeResult>> call(
    String bankId,
    Map<String, String> answers, {
    Set<String> dontKnow = const {},
  }) => _repository.completePractice(bankId, answers, dontKnow: dontKnow);
}
