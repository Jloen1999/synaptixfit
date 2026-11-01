import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Sesiones sin terminar (en curso y abandonadas) con su rutina y día.
abstract interface class GetOpenSessionsUseCaseContract {
  Future<AppResult<List<OpenSession>>> call();
}

class GetOpenSessionsUseCase implements GetOpenSessionsUseCaseContract {
  const GetOpenSessionsUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<List<OpenSession>>> call() =>
      _repository.getOpenSessions();
}
