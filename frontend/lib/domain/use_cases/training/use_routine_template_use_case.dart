import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Crea una rutina propia a partir de una plantilla.
abstract interface class UseRoutineTemplateUseCaseContract {
  Future<AppResult<Routine>> call(String templateId);
}

class UseRoutineTemplateUseCase implements UseRoutineTemplateUseCaseContract {
  const UseRoutineTemplateUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String templateId) =>
      _repository.useTemplate(templateId);
}
