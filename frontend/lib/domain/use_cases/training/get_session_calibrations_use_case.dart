import '../../models/result/app_result.dart';
import '../../models/training/exercise_calibration.dart';
import '../../repositories/training_repository_contract.dart';

/// Ejercicios de una sesión en curso que se calibran en su primera serie
/// (ADR 0054), con la respuesta si ya se dio.
abstract interface class GetSessionCalibrationsUseCaseContract {
  Future<AppResult<List<ExerciseCalibration>>> call(String sessionId);
}

class GetSessionCalibrationsUseCase
    implements GetSessionCalibrationsUseCaseContract {
  const GetSessionCalibrationsUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<List<ExerciseCalibration>>> call(String sessionId) =>
      _repository.getCalibrations(sessionId);
}
