import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Cierra la práctica libre y otorga la XP.
abstract interface class CompletePracticeUseCaseContract {
  Future<AppResult<PracticeResult>> call(
    String bankId,
    Map<String, String> answers,
  );
}

class CompletePracticeUseCase implements CompletePracticeUseCaseContract {
  const CompletePracticeUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<PracticeResult>> call(
    String bankId,
    Map<String, String> answers,
  ) => _repository.completePractice(bankId, answers);
}
