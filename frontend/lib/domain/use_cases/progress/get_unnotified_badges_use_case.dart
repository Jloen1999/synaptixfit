import '../../models/progress/badge.dart';
import '../../models/result/app_result.dart';
import '../../repositories/badge_repository_contract.dart';

/// Insignias que el servidor ya ha otorgado y aún no se han celebrado. Las
/// otorga el backend al procesar cada acción, así que el cliente solo lee.
abstract interface class GetUnnotifiedBadgesUseCaseContract {
  Future<AppResult<List<Badge>>> call();
}

class GetUnnotifiedBadgesUseCase implements GetUnnotifiedBadgesUseCaseContract {
  const GetUnnotifiedBadgesUseCase(this._repository);

  final BadgeRepositoryContract _repository;

  @override
  Future<AppResult<List<Badge>>> call() => _repository.getUnnotified();
}
