import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Apunta estudio que ya se hizo sin la app (de los últimos 7 días): queda
/// como bloque de estudio completado y cuenta como cualquier otro (XP, semana
/// y carga cognitiva). Las reglas las decide el servidor.
abstract interface class LogPastStudyUseCaseContract {
  Future<AppResult<BlockCompletion>> call({
    required DateTime start,
    required int minutes,
    String? subjectId,
    String? title,
  });
}

class LogPastStudyUseCase implements LogPastStudyUseCaseContract {
  const LogPastStudyUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<BlockCompletion>> call({
    required DateTime start,
    required int minutes,
    String? subjectId,
    String? title,
  }) => _repository.logPastStudy(
    start: start,
    minutes: minutes,
    subjectId: subjectId,
    title: title?.trim(),
  );
}
