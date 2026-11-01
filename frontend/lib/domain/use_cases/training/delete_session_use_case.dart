import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/training_repository_contract.dart';

/// Elimina una sesión terminada: el servidor resta su XP y retira su carga, su
/// avance en retos y su bloque (el día vuelve a estar pendiente).
abstract interface class DeleteSessionUseCaseContract {
  Future<AppResult<Unit>> call(String sessionId);
}

class DeleteSessionUseCase implements DeleteSessionUseCaseContract {
  const DeleteSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String sessionId) =>
      _repository.deleteSession(sessionId);
}
