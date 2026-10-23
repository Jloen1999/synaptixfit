import '../../enums/evaluation_mode.dart';
import '../../models/academic/teaching_guide.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Elige la modalidad de evaluación (continua o global) de la guía docente.
abstract interface class SetTeachingGuideModeUseCaseContract {
  Future<AppResult<TeachingGuide>> call(String subjectId, EvaluationMode mode);
}

class SetTeachingGuideModeUseCase
    implements SetTeachingGuideModeUseCaseContract {
  const SetTeachingGuideModeUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<TeachingGuide>> call(
    String subjectId,
    EvaluationMode mode,
  ) => _repository.setTeachingGuideMode(subjectId, mode);
}
