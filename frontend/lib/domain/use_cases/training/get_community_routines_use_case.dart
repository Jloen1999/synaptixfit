import '../../enums/training_enums.dart';
import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../models/training/training_page.dart';
import '../../repositories/routine_repository_contract.dart';

/// Rutinas públicas y de amigos.
abstract interface class GetCommunityRoutinesUseCaseContract {
  Future<AppResult<TrainingPage<RoutineSummary>>> call({
    String? query,
    TrainingGoal? goal,
    int page = 0,
    int size = 20,
  });
}

class GetCommunityRoutinesUseCase
    implements GetCommunityRoutinesUseCaseContract {
  const GetCommunityRoutinesUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<RoutineSummary>>> call({
    String? query,
    TrainingGoal? goal,
    int page = 0,
    int size = 20,
  }) => _repository.getCommunityRoutines(
    query: query,
    goal: goal,
    page: page,
    size: size,
  );
}
