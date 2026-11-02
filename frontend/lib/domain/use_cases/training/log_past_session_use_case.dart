import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Registra un día de la rutina entrenado sin la app (hoy o hasta 7 días antes).
abstract interface class LogPastSessionUseCaseContract {
  Future<AppResult<PastSessionResult>> call({
    required String routineId,
    required String dayId,
    required DateTime date,
    required int durationMinutes,
    required int rpe,
  });
}

class LogPastSessionUseCase implements LogPastSessionUseCaseContract {
  const LogPastSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<PastSessionResult>> call({
    required String routineId,
    required String dayId,
    required DateTime date,
    required int durationMinutes,
    required int rpe,
  }) => _repository.logPastSession(
    routineId: routineId,
    dayId: dayId,
    date: date,
    durationMinutes: durationMinutes,
    rpe: rpe,
  );
}
