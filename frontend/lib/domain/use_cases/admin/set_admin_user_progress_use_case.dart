import '../../models/admin/admin_user.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Fija el nivel y la XP del nivel de un usuario.
abstract interface class SetAdminUserProgressUseCaseContract {
  Future<AppResult<AdminUserAccount>> call(
    String userId, {
    required int level,
    required int levelXp,
  });
}

class SetAdminUserProgressUseCase
    implements SetAdminUserProgressUseCaseContract {
  const SetAdminUserProgressUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminUserAccount>> call(
    String userId, {
    required int level,
    required int levelXp,
  }) => _repository.setUserProgress(userId, level: level, levelXp: levelXp);
}
