import '../../models/result/app_result.dart';
import '../../models/training/exercise_calibration.dart';
import '../../repositories/training_repository_contract.dart';

/// Responde «¿Cuántas más podrías haber hecho?» tras la serie [setNumber] (ya
/// guardada) de [plannedExerciseId]: el servidor devuelve el peso de la serie
/// siguiente y lo deja en la rutina (ADR 0054).
abstract interface class CalibrateExerciseUseCaseContract {
  Future<AppResult<ExerciseCalibration>> call({
    required String sessionId,
    required String plannedExerciseId,
    required int setNumber,
    required CalibrationAnswer answer,
  });
}

class CalibrateExerciseUseCase implements CalibrateExerciseUseCaseContract {
  const CalibrateExerciseUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<ExerciseCalibration>> call({
    required String sessionId,
    required String plannedExerciseId,
    required int setNumber,
    required CalibrationAnswer answer,
  }) => _repository.calibrate(
    sessionId: sessionId,
    plannedExerciseId: plannedExerciseId,
    setNumber: setNumber,
    answer: answer,
  );
}
