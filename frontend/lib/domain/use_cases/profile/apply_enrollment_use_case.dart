import '../../models/profile/enrollment_proposal.dart';
import '../../models/result/app_result.dart';
import '../../repositories/enrollment_repository_contract.dart';

/// Añade la carrera y las asignaturas elegidas de la propuesta: las del
/// catálogo por su id y el resto como asignaturas propias.
abstract interface class ApplyEnrollmentUseCaseContract {
  Future<AppResult<EnrollmentApplyResult>> call(
    EnrollmentProposal proposal,
    List<EnrollmentSubject> chosen,
  );
}

class ApplyEnrollmentUseCase implements ApplyEnrollmentUseCaseContract {
  const ApplyEnrollmentUseCase(this._repository);

  final EnrollmentRepositoryContract _repository;

  @override
  Future<AppResult<EnrollmentApplyResult>> call(
    EnrollmentProposal proposal,
    List<EnrollmentSubject> chosen,
  ) => _repository.apply(
    degreeId: proposal.degreeId,
    catalogSubjectIds: [
      for (final s in chosen)
        if (s.catalogSubjectId != null) s.catalogSubjectId!,
    ],
    customSubjects: [
      for (final s in chosen)
        if (s.catalogSubjectId == null) s,
    ],
  );
}
