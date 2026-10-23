import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Retención por estado de dominio.
abstract interface class GetSubjectRetentionUseCaseContract {
  Future<AppResult<Retention>> call(String subjectId);
}

class GetSubjectRetentionUseCase implements GetSubjectRetentionUseCaseContract {
  const GetSubjectRetentionUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<Retention>> call(String subjectId) =>
      _repository.getRetention(subjectId);
}
