import '../../models/academic/teaching_guide_import.dart';
import '../../models/result/app_result.dart';
import '../../repositories/teaching_guide_import_repository_contract.dart';

/// Aplica el plan docente revisado: crea o completa la asignatura, guarda la
/// guía y, si se pide, crea las pruebas con fecha en el planificador.
abstract interface class ApplyTeachingGuideImportUseCaseContract {
  Future<AppResult<TeachingGuideImportResult>> call(
    String importId, {
    String? subjectId,
    required GuideDraft draft,
    required bool createDeadlines,
  });
}

class ApplyTeachingGuideImportUseCase
    implements ApplyTeachingGuideImportUseCaseContract {
  const ApplyTeachingGuideImportUseCase(this._repository);

  final TeachingGuideImportRepositoryContract _repository;

  @override
  Future<AppResult<TeachingGuideImportResult>> call(
    String importId, {
    String? subjectId,
    required GuideDraft draft,
    required bool createDeadlines,
  }) => _repository.apply(
    importId,
    subjectId: subjectId,
    draft: draft,
    createDeadlines: createDeadlines,
  );
}
