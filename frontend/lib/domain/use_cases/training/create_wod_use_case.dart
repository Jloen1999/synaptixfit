import '../../models/result/app_result.dart';
import '../../models/training/wod.dart';
import '../../repositories/wod_repository_contract.dart';

/// Crea un WOD mío, desde cero o partiendo de una plantilla (ADR 0069).
abstract interface class CreateWodUseCaseContract {
  Future<AppResult<Wod>> call(Wod wod);
}

class CreateWodUseCase implements CreateWodUseCaseContract {
  const CreateWodUseCase(this._repository);

  final WodRepositoryContract _repository;

  @override
  Future<AppResult<Wod>> call(Wod wod) => _repository.create(wod);
}
