import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../models/training/training_page.dart';
import '../../repositories/training_repository_contract.dart';

/// Historial de sesiones.
abstract interface class GetSessionsUseCaseContract {
  Future<AppResult<TrainingPage<TrainingSession>>> call({
    bool? completed,
    int page = 0,
    int size = 20,
  });
}

class GetSessionsUseCase implements GetSessionsUseCaseContract {
  const GetSessionsUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<TrainingSession>>> call({
    bool? completed,
    int page = 0,
    int size = 20,
  }) => _repository.getSessions(completed: completed, page: page, size: size);
}
