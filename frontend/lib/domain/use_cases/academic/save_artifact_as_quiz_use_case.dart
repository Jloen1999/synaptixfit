import '../../models/academic/study_artifact.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_assistant_repository_contract.dart';

/// Guarda preguntas generadas como banco de práctica.
abstract interface class SaveArtifactAsQuizUseCaseContract {
  Future<AppResult<SavedQuiz>> call({
    required String subjectId,
    String? title,
    required List<QuestionDraft> questions,
  });
}

class SaveArtifactAsQuizUseCase implements SaveArtifactAsQuizUseCaseContract {
  const SaveArtifactAsQuizUseCase(this._repository);

  final StudyAssistantRepositoryContract _repository;

  @override
  Future<AppResult<SavedQuiz>> call({
    required String subjectId,
    String? title,
    required List<QuestionDraft> questions,
  }) => _repository.saveArtifactAsQuiz(
    subjectId: subjectId,
    title: title,
    questions: questions,
  );
}
