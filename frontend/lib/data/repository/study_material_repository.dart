import '../../domain/enums/study_source_type.dart';
import '../../domain/models/academic/study_material.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/study_material_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/study_materials_remote_data_source.dart';

class StudyMaterialRepository implements StudyMaterialRepositoryContract {
  StudyMaterialRepository(this._remote);

  final StudyMaterialsRemoteDataSource _remote;

  @override
  Future<AppResult<StudyMaterial>> registerMaterial(
    StudySourceType originType,
    String originId,
  ) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.register(originType.apiValue, originId)).toDomain(),
  );

  @override
  Future<AppResult<List<StudyMaterial>>> getMaterials({String? subjectId}) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getMaterials(
          subjectId: subjectId,
        )).map((m) => m.toDomain()).toList(),
      );

  @override
  Future<AppResult<List<StudyMaterial>>> getDueMaterials({int limit = 20}) =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.getDue(limit)).map((m) => m.toDomain()).toList(),
      );

  @override
  Future<AppResult<StudyMaterial>> getMaterial(String materialId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getMaterial(materialId)).toDomain(),
      );

  @override
  Future<AppResult<Unit>> deleteMaterial(String materialId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteMaterial(materialId);
        return unit;
      });

  @override
  Future<AppResult<Unit>> abandonMaterial(String materialId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.abandonMaterial(materialId);
        return unit;
      });

  @override
  Future<AppResult<ReviewPreview>> getReviewPreview(String materialId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getPreview(materialId)).toDomain(),
      );

  @override
  Future<AppResult<ReviewOutcome>> review(String materialId, int quality) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.review(materialId, quality)).toDomain(),
      );

  @override
  Future<AppResult<List<ReviewRecord>>> getReviewHistory(String materialId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getHistory(
          materialId,
        )).map((r) => r.toDomain()).toList(),
      );
}
