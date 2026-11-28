import '../../models/result/app_result.dart';
import '../../models/training/routine_template.dart';
import '../../repositories/routine_repository_contract.dart';

/// Detalle de una plantilla de rutina (días y ejercicios) para decidir antes
/// de usarla.
abstract interface class GetRoutineTemplateUseCaseContract {
  Future<AppResult<RoutineTemplateDetail>> call(String templateId);
}

/// Implementa [GetRoutineTemplateUseCaseContract] con
/// [RoutineRepositoryContract].
class GetRoutineTemplateUseCase implements GetRoutineTemplateUseCaseContract {
  const GetRoutineTemplateUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<RoutineTemplateDetail>> call(String templateId) =>
      _repository.getTemplate(templateId);
}
