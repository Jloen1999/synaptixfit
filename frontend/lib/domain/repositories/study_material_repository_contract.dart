import '../enums/study_source_type.dart';
import '../models/academic/study_material.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Materiales de estudio y repaso espaciado.
abstract interface class StudyMaterialRepositoryContract {
  /// Idempotente: si la fuente ya es material, devuelve el existente.
  Future<AppResult<StudyMaterial>> registerMaterial(
    StudySourceType originType,
    String originId,
  );

  Future<AppResult<List<StudyMaterial>>> getMaterials({String? subjectId});

  Future<AppResult<List<StudyMaterial>>> getDueMaterials({int limit = 20});

  Future<AppResult<StudyMaterial>> getMaterial(String materialId);

  Future<AppResult<Unit>> deleteMaterial(String materialId);

  /// Lo quita del repaso conservando su historial.
  Future<AppResult<Unit>> abandonMaterial(String materialId);

  Future<AppResult<ReviewPreview>> getReviewPreview(String materialId);

  Future<AppResult<ReviewOutcome>> review(String materialId, int quality);

  Future<AppResult<List<ReviewRecord>>> getReviewHistory(String materialId);
}
