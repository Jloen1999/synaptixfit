import '../../models/academic/subject_questions.dart';
import '../../models/result/app_result.dart';
import '../../repositories/quiz_repository_contract.dart';

/// Todas las preguntas de una asignatura con cómo va cada una, para
/// «Practicar» (ADR 0063).
abstract interface class GetSubjectQuestionsUseCaseContract {
  Future<AppResult<SubjectQuestions>> call(String subjectId);
}

class GetSubjectQuestionsUseCase implements GetSubjectQuestionsUseCaseContract {
  const GetSubjectQuestionsUseCase(this._repository);

  final QuizRepositoryContract _repository;

  @override
  Future<AppResult<SubjectQuestions>> call(String subjectId) =>
      _repository.getSubjectQuestions(subjectId);
}
