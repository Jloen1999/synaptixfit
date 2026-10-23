import '../../enums/training_enums.dart';
import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../models/training/training_page.dart';
import '../../repositories/routine_repository_contract.dart';

/// Rutinas del usuario, opcionalmente filtradas por estado.
abstract interface class GetMyRoutinesUseCaseContract {
  Future<AppResult<TrainingPage<RoutineSummary>>> call({
    RoutineStatus? status,
    int page = 0,
    int size = 20,
  });
}

class GetMyRoutinesUseCase implements GetMyRoutinesUseCaseContract {
  const GetMyRoutinesUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<RoutineSummary>>> call({
    RoutineStatus? status,
    int page = 0,
    int size = 20,
  }) => _repository.getMyRoutines(status: status, page: page, size: size);
}
