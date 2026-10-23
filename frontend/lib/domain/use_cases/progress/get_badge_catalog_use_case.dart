import '../../models/progress/badge.dart';
import '../../models/result/app_result.dart';
import '../../repositories/badge_repository_contract.dart';

/// Catálogo completo de insignias con el progreso del usuario, en el orden del
/// catálogo.
abstract interface class GetBadgeCatalogUseCaseContract {
  Future<AppResult<List<Badge>>> call();
}

class GetBadgeCatalogUseCase implements GetBadgeCatalogUseCaseContract {
  const GetBadgeCatalogUseCase(this._repository);

  final BadgeRepositoryContract _repository;

  @override
  Future<AppResult<List<Badge>>> call() async =>
      (await _repository.getCatalog()).map(
        (badges) => [...badges]..sort((a, b) => a.order.compareTo(b.order)),
      );
}
