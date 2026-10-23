import '../../errors/app_error.dart';
import '../../models/academic/quiz.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Banco de preguntas del material o `null` si aún no tiene.
abstract interface class GetQuestionBankUseCaseContract {
  Future<AppResult<QuestionBank?>> call(String materialId);
}

class GetQuestionBankUseCase implements GetQuestionBankUseCaseContract {
  const GetQuestionBankUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<QuestionBank?>> call(String materialId) async {
    final result = await _repository.getQuestionBank(materialId);
    return switch (result) {
      Success(:final value) => Success(value),
      Failure(:final error)
          when error is NotFoundError ||
              error == const AppError.business('QUIZ_BANK_NOT_FOUND') =>
        const Success(null),
      Failure(:final error) => Failure(error),
    };
  }
}
