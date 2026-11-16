import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/guide_progress_repository_contract.dart';

/// «Ver las guías otra vez» (Ajustes › Ayuda): todas vuelven a salir al entrar
/// en su pantalla.
abstract interface class ResetGuidesUseCaseContract {
  Future<AppResult<Unit>> call({required String accountId});
}

/// Implementa [ResetGuidesUseCaseContract] con
/// [GuideProgressRepositoryContract].
class ResetGuidesUseCase implements ResetGuidesUseCaseContract {
  const ResetGuidesUseCase(this._repository);

  final GuideProgressRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String accountId}) async {
    if (accountId.isEmpty) return const Success(unit);
    return _repository.reset(accountId);
  }
}
