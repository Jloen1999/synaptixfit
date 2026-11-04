import '../../models/academic/mock_exam_options.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Apuntes y archivos de una asignatura que pueden entrar en un simulacro.
abstract interface class GetMockExamOptionsUseCaseContract {
  Future<AppResult<MockExamOptions>> call(String subjectId);
}

class GetMockExamOptionsUseCase implements GetMockExamOptionsUseCaseContract {
  const GetMockExamOptionsUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<MockExamOptions>> call(String subjectId) =>
      _repository.getMockExamOptions(subjectId);
}
