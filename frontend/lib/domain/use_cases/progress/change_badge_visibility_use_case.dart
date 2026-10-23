import '../../models/progress/badge.dart';
import '../../models/result/app_result.dart';
import '../../repositories/badge_repository_contract.dart';

/// Muestra u oculta en el perfil público una insignia obtenida.
abstract interface class ChangeBadgeVisibilityUseCaseContract {
  Future<AppResult<Badge>> call({
    required String badgeId,
    required bool visible,
  });
}

class ChangeBadgeVisibilityUseCase
    implements ChangeBadgeVisibilityUseCaseContract {
  const ChangeBadgeVisibilityUseCase(this._repository);

  final BadgeRepositoryContract _repository;

  @override
  Future<AppResult<Badge>> call({
    required String badgeId,
    required bool visible,
  }) => _repository.changeVisibility(badgeId: badgeId, visible: visible);
}
