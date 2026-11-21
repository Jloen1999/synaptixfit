import '../../models/progress/community_post_preview.dart';
import '../../models/result/app_result.dart';
import '../../repositories/progress_repository_contract.dart';

/// Últimas publicaciones del muro para Tú › Comunidad (ADR 0061).
abstract interface class GetCommunityPreviewUseCaseContract {
  Future<AppResult<List<CommunityPostPreview>>> call({int size = 3});
}

/// Implementa [GetCommunityPreviewUseCaseContract] con
/// [ProgressRepositoryContract].
class GetCommunityPreviewUseCase implements GetCommunityPreviewUseCaseContract {
  const GetCommunityPreviewUseCase(this._repository);

  final ProgressRepositoryContract _repository;

  @override
  Future<AppResult<List<CommunityPostPreview>>> call({int size = 3}) =>
      _repository.getCommunityPreview(size: size);
}
