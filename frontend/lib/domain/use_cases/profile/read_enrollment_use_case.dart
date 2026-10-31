import '../../models/academic/subject_file.dart';
import '../../models/profile/enrollment_proposal.dart';
import '../../models/result/app_result.dart';
import '../../repositories/enrollment_repository_contract.dart';

/// Lee la matrícula de un PDF (con permiso expreso) y propone qué añadir.
abstract interface class ReadEnrollmentUseCaseContract {
  Future<AppResult<EnrollmentProposal>> call(
    FileUploadPayload file, {
    required bool consent,
  });
}

class ReadEnrollmentUseCase implements ReadEnrollmentUseCaseContract {
  const ReadEnrollmentUseCase(this._repository);

  final EnrollmentRepositoryContract _repository;

  @override
  Future<AppResult<EnrollmentProposal>> call(
    FileUploadPayload file, {
    required bool consent,
  }) => _repository.read(file, consent: consent);
}
