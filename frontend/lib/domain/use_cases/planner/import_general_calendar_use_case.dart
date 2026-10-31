import '../../models/planner/planner_ai.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Importa un calendario general como el del Campus Virtual: solo exámenes y
/// entregas, cada uno en la asignatura que mencione (o sin asignatura).
abstract interface class ImportGeneralCalendarUseCaseContract {
  Future<AppResult<IcsImportResult>> call({required String url});
}

class ImportGeneralCalendarUseCase
    implements ImportGeneralCalendarUseCaseContract {
  const ImportGeneralCalendarUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<IcsImportResult>> call({required String url}) =>
      _repository.importGeneralCalendar(url: url);
}
