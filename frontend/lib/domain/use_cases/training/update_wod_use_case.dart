import '../../models/result/app_result.dart';
import '../../models/training/wod.dart';
import '../../repositories/wod_repository_contract.dart';

/// Cambia la pizarra de un WOD mío (ADR 0069).
abstract interface class UpdateWodUseCaseContract {
  Future<AppResult<Wod>> call(Wod wod);
}

class UpdateWodUseCase implements UpdateWodUseCaseContract {
  const UpdateWodUseCase(this._repository);

  final WodRepositoryContract _repository;

  @override
  Future<AppResult<Wod>> call(Wod wod) => _repository.update(wod);
}
