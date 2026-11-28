import '../../models/result/app_result.dart';
import '../../models/training/wod.dart';
import '../../repositories/wod_repository_contract.dart';

/// Los WOD de ejemplo (ADR 0069).
abstract interface class ListWodTemplatesUseCaseContract {
  Future<AppResult<List<Wod>>> call();
}

class ListWodTemplatesUseCase implements ListWodTemplatesUseCaseContract {
  const ListWodTemplatesUseCase(this._repository);

  final WodRepositoryContract _repository;

  @override
  Future<AppResult<List<Wod>>> call() => _repository.listTemplates();
}
