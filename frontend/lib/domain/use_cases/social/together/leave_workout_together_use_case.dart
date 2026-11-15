import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Sale de un «Entrenamos juntos»; la sesión sigue siendo mía.
abstract interface class LeaveWorkoutTogetherUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [LeaveWorkoutTogetherUseCaseContract] con [TogetherRepositoryContract].
class LeaveWorkoutTogetherUseCase
    implements LeaveWorkoutTogetherUseCaseContract {
  const LeaveWorkoutTogetherUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.leaveWorkout(id);
}
