import '../../models/result/app_result.dart';
import '../../models/training/session_history.dart';
import '../../repositories/training_history_repository_contract.dart';

/// Una sesión como en el historial (nombre, foto de su tarjeta y récords): la
/// usa el detalle abierto sin pasar por el historial. La foto la elige el
/// servidor (ADR 0042), no el cliente.
abstract interface class GetSessionHistoryEntryUseCaseContract {
  Future<AppResult<SessionHistoryEntry>> call(String sessionId);
}

/// Implementa [GetSessionHistoryEntryUseCaseContract] con
/// [TrainingHistoryRepositoryContract].
class GetSessionHistoryEntryUseCase
    implements GetSessionHistoryEntryUseCaseContract {
  const GetSessionHistoryEntryUseCase(this._repository);

  final TrainingHistoryRepositoryContract _repository;

  @override
  Future<AppResult<SessionHistoryEntry>> call(String sessionId) =>
      _repository.getHistoryEntry(sessionId);
}
