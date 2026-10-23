import '../../enums/training_enums.dart';
import '../../models/result/app_result.dart';
import '../../models/training/routine_draft.dart';
import '../../repositories/routine_repository_contract.dart';

/// Genera una propuesta de rutina (reglas + IA).
abstract interface class GenerateRoutineUseCaseContract {
  Future<AppResult<RoutineProposal>> call({
    required int durationWeeks,
    TrainingGoal? goal,
    bool useAi = true,
  });
}

class GenerateRoutineUseCase implements GenerateRoutineUseCaseContract {
  const GenerateRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<RoutineProposal>> call({
    required int durationWeeks,
    TrainingGoal? goal,
    bool useAi = true,
  }) => _repository.generateRoutine(
    durationWeeks: durationWeeks,
    goal: goal,
    useAi: useAi,
  );
}
