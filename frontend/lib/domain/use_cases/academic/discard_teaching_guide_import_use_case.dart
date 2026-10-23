import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/teaching_guide_import_repository_contract.dart';

/// Descarta una importación (y el PDF subido si no se aplicó).
abstract interface class DiscardTeachingGuideImportUseCaseContract {
  Future<AppResult<Unit>> call(String importId);
}

class DiscardTeachingGuideImportUseCase
    implements DiscardTeachingGuideImportUseCaseContract {
  const DiscardTeachingGuideImportUseCase(this._repository);

  final TeachingGuideImportRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String importId) =>
      _repository.discard(importId);
}
