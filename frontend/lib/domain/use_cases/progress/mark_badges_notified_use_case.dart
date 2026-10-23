import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/badge_repository_contract.dart';

/// Marca como celebradas las insignias mostradas para no repetir el aviso.
abstract interface class MarkBadgesNotifiedUseCaseContract {
  Future<AppResult<Unit>> call(List<String> badgeIds);
}

class MarkBadgesNotifiedUseCase implements MarkBadgesNotifiedUseCaseContract {
  const MarkBadgesNotifiedUseCase(this._repository);

  final BadgeRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(List<String> badgeIds) async {
    if (badgeIds.isEmpty) return const Success(unit);
    return _repository.markNotified(badgeIds);
  }
}
