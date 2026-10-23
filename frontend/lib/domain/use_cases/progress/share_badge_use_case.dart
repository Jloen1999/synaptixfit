import '../../models/progress/badge.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/progress_repository_contract.dart';

/// Comparte en el muro social una insignia obtenida.
abstract interface class ShareBadgeUseCaseContract {
  Future<AppResult<Unit>> call({required Badge badge, String? message});
}

class ShareBadgeUseCase implements ShareBadgeUseCaseContract {
  const ShareBadgeUseCase(this._repository);

  final ProgressRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required Badge badge, String? message}) {
    final trimmed = message?.trim();
    return _repository.shareBadge(
      badge: badge,
      message: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }
}
