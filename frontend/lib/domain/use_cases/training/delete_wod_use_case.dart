import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/wod_repository_contract.dart';

/// Borra un WOD mío con sus marcas (ADR 0069).
abstract interface class DeleteWodUseCaseContract {
  Future<AppResult<Unit>> call(String wodId);
}

class DeleteWodUseCase implements DeleteWodUseCaseContract {
  const DeleteWodUseCase(this._repository);

  final WodRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String wodId) => _repository.delete(wodId);
}
