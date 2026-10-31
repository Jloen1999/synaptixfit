import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Apunta una actividad física que ya pasó (de los últimos 7 días): queda como
/// bloque de deporte completado con su esfuerzo y cuenta en la carga física.
abstract interface class LogPastActivityUseCaseContract {
  Future<AppResult<BlockCompletion>> call({
    required DateTime start,
    required int minutes,
    required int effort,
    String? title,
  });
}

class LogPastActivityUseCase implements LogPastActivityUseCaseContract {
  const LogPastActivityUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<BlockCompletion>> call({
    required DateTime start,
    required int minutes,
    required int effort,
    String? title,
  }) => _repository.logPastActivity(
    start: start,
    minutes: minutes,
    effort: effort,
    title: title?.trim(),
  );
}
