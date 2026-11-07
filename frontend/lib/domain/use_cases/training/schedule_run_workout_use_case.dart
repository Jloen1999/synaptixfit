import '../../models/result/app_result.dart';
import '../../repositories/run_repository_contract.dart';

/// «Poner en el calendario»: crea un evento de tipo Entreno ligado al entreno de carrera.
abstract interface class ScheduleRunWorkoutUseCaseContract {
  Future<AppResult<String>> call(String workoutId, DateTime start);
}

class ScheduleRunWorkoutUseCase implements ScheduleRunWorkoutUseCaseContract {
  const ScheduleRunWorkoutUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<String>> call(String workoutId, DateTime start) =>
      _repository.scheduleWorkout(workoutId, start);
}
