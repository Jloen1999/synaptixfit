import '../../domain/models/academic/subject_file.dart';
import '../../domain/models/profile/enrollment_proposal.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/enrollment_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/profile/enrollment_remote_data_source.dart';

/// Implementa [EnrollmentRepositoryContract] con [EnrollmentRemoteDataSource].
class EnrollmentRepository implements EnrollmentRepositoryContract {
  EnrollmentRepository(this._remote);

  final EnrollmentRemoteDataSource _remote;

  @override
  Future<AppResult<EnrollmentProposal>> read(
    FileUploadPayload file, {
    required bool consent,
  }) =>
      RepositoryErrorHandler.guard(() => _remote.read(file, consent: consent));

  @override
  Future<AppResult<EnrollmentApplyResult>> apply({
    String? degreeId,
    required List<String> catalogSubjectIds,
    required List<EnrollmentSubject> customSubjects,
  }) => RepositoryErrorHandler.guard(
    () => _remote.apply(
      degreeId: degreeId,
      catalogSubjectIds: catalogSubjectIds,
      customSubjects: customSubjects,
    ),
  );
}
