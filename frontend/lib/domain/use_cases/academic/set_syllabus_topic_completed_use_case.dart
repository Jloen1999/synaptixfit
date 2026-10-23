import '../../models/academic/teaching_guide.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Marca o desmarca un tema del temario.
abstract interface class SetSyllabusTopicCompletedUseCaseContract {
  Future<AppResult<TeachingGuide>> call(
    String subjectId,
    int index,
    bool completed,
  );
}

class SetSyllabusTopicCompletedUseCase
    implements SetSyllabusTopicCompletedUseCaseContract {
  const SetSyllabusTopicCompletedUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<TeachingGuide>> call(
    String subjectId,
    int index,
    bool completed,
  ) => _repository.setTopicCompleted(subjectId, index, completed);
}
