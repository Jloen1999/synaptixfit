import '../../enums/guide_id.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/guide_progress_repository_contract.dart';

/// Apunta que la cuenta ya vio la guía (terminada o saltada): no vuelve a salir.
abstract interface class MarkGuideSeenUseCaseContract {
  Future<AppResult<Unit>> call({
    required String accountId,
    required GuideId guide,
  });
}

/// Implementa [MarkGuideSeenUseCaseContract] con
/// [GuideProgressRepositoryContract].
class MarkGuideSeenUseCase implements MarkGuideSeenUseCaseContract {
  const MarkGuideSeenUseCase(this._repository);

  final GuideProgressRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({
    required String accountId,
    required GuideId guide,
  }) async {
    if (accountId.isEmpty) return const Success(unit);
    return _repository.markSeen(accountId, guide);
  }
}
