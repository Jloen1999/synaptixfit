import '../models/academic/subject_file.dart';
import '../models/profile/enrollment_proposal.dart';
import '../models/result/app_result.dart';

/// Importar la matrícula desde la carta de pago o el resguardo (PDF).
abstract interface class EnrollmentRepositoryContract {
  /// [consent]: el usuario ha dado permiso para leer el documento.
  Future<AppResult<EnrollmentProposal>> read(
    FileUploadPayload file, {
    required bool consent,
  });

  Future<AppResult<EnrollmentApplyResult>> apply({
    String? degreeId,
    required List<String> catalogSubjectIds,
    required List<EnrollmentSubject> customSubjects,
  });
}
