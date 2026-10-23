import '../../models/academic/teaching_guide.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Pone (o borra) la nota de un criterio de evaluación.
abstract interface class SetAssessmentGradeUseCaseContract {
  Future<AppResult<TeachingGuide>> call(
    String subjectId,
    int index,
    double? grade,
  );
}

class SetAssessmentGradeUseCase implements SetAssessmentGradeUseCaseContract {
  const SetAssessmentGradeUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<TeachingGuide>> call(
    String subjectId,
    int index,
    double? grade,
  ) => _repository.setAssessmentGrade(subjectId, index, grade);
}
