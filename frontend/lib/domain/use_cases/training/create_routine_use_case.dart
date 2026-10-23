import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../models/training/routine_draft.dart';
import '../../repositories/routine_repository_contract.dart';

/// Crea una rutina completa (manual o desde una propuesta).
abstract interface class CreateRoutineUseCaseContract {
  Future<AppResult<Routine>> call(RoutineDraft draft);
}

class CreateRoutineUseCase implements CreateRoutineUseCaseContract {
  const CreateRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(RoutineDraft draft) =>
      _repository.createRoutine(draft);
}
