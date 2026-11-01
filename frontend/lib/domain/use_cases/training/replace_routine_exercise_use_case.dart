import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Sustituye el ejercicio de un hueco de la rutina por otro del catálogo (misma
/// posición; el servidor adapta los parámetros a cómo se mide el nuevo).
abstract interface class ReplaceRoutineExerciseUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId,
    String plannedExerciseId,
    String exerciseId,
  );
}

/// Implementa [ReplaceRoutineExerciseUseCaseContract] con
/// [RoutineRepositoryContract].
class ReplaceRoutineExerciseUseCase
    implements ReplaceRoutineExerciseUseCaseContract {
  const ReplaceRoutineExerciseUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId,
    String plannedExerciseId,
    String exerciseId,
  ) => _repository.replaceExercise(routineId, plannedExerciseId, exerciseId);
}
