import '../../models/result/app_result.dart';
import '../../repositories/training_repository_contract.dart';

/// «Guardar como rutina»: crea una rutina con lo hecho en una sesión libre y
/// devuelve su id (ADR 0067).
abstract interface class SaveSessionAsRoutineUseCaseContract {
  Future<AppResult<String>> call(String sessionId, String name);
}

class SaveSessionAsRoutineUseCase
    implements SaveSessionAsRoutineUseCaseContract {
  const SaveSessionAsRoutineUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<String>> call(String sessionId, String name) =>
      _repository.saveSessionAsRoutine(sessionId, name);
}
