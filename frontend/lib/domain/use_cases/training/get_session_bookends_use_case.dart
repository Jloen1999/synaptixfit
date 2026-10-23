import '../../models/result/app_result.dart';
import '../../models/training/exercise.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Calentamiento (movilidad) y vuelta a la calma (estiramientos) de una sesión.
abstract interface class GetSessionBookendsUseCaseContract {
  Future<AppResult<SessionBookends>> call(List<String> exerciseIds);
}

class GetSessionBookendsUseCase implements GetSessionBookendsUseCaseContract {
  const GetSessionBookendsUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<SessionBookends>> call(List<String> exerciseIds) =>
      _repository.getBookends(exerciseIds);
}
