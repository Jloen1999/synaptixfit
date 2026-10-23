import '../../models/planner/planner_ai.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Escanea un horario (PDF o imagen) y crea las clases del semestre.
abstract interface class ScanScheduleUseCaseContract {
  Future<AppResult<ScheduleScanResult>> call(
    ScheduleFile file, {
    void Function(double progress)? onProgress,
  });
}

class ScanScheduleUseCase implements ScanScheduleUseCaseContract {
  const ScanScheduleUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<ScheduleScanResult>> call(
    ScheduleFile file, {
    void Function(double progress)? onProgress,
  }) => _repository.scanSchedule(file, onProgress: onProgress);
}
