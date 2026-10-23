import '../../models/academic/teaching_guide_import.dart';
import '../../models/result/app_result.dart';
import '../../repositories/teaching_guide_import_repository_contract.dart';

/// Vuelve a pedir el análisis de un plan docente que falló.
abstract interface class RetryTeachingGuideImportUseCaseContract {
  Future<AppResult<TeachingGuideImport>> call(String importId);
}

class RetryTeachingGuideImportUseCase
    implements RetryTeachingGuideImportUseCaseContract {
  const RetryTeachingGuideImportUseCase(this._repository);

  final TeachingGuideImportRepositoryContract _repository;

  @override
  Future<AppResult<TeachingGuideImport>> call(String importId) =>
      _repository.retry(importId);
}
