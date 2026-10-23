import '../../models/academic/subject_file.dart';
import '../../models/academic/teaching_guide_import.dart';
import '../../models/result/app_result.dart';
import '../../repositories/teaching_guide_import_repository_contract.dart';

/// Sube el plan docente y pide a la IA que lo analice.
abstract interface class StartTeachingGuideImportUseCaseContract {
  Future<AppResult<TeachingGuideImport>> call(
    FileUploadPayload payload, {
    String? targetSubjectId,
    void Function(double progress)? onProgress,
  });
}

class StartTeachingGuideImportUseCase
    implements StartTeachingGuideImportUseCaseContract {
  const StartTeachingGuideImportUseCase(this._repository);

  final TeachingGuideImportRepositoryContract _repository;

  @override
  Future<AppResult<TeachingGuideImport>> call(
    FileUploadPayload payload, {
    String? targetSubjectId,
    void Function(double progress)? onProgress,
  }) => _repository.start(
    payload,
    targetSubjectId: targetSubjectId,
    onProgress: onProgress,
  );
}
