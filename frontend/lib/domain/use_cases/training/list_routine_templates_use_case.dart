import '../../models/result/app_result.dart';
import '../../models/training/routine_template.dart';
import '../../repositories/routine_repository_contract.dart';

/// Lista las plantillas de rutina listas para usar.
abstract interface class ListRoutineTemplatesUseCaseContract {
  Future<AppResult<List<RoutineTemplate>>> call();
}

class ListRoutineTemplatesUseCase
    implements ListRoutineTemplatesUseCaseContract {
  const ListRoutineTemplatesUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<List<RoutineTemplate>>> call() =>
      _repository.listTemplates();
}
