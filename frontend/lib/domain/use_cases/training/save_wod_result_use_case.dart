import '../../models/result/app_result.dart';
import '../../models/training/wod.dart';
import '../../repositories/wod_repository_contract.dart';

/// Guarda la marca de un WOD; el servidor la apunta como actividad (ADR 0069).
abstract interface class SaveWodResultUseCaseContract {
  Future<AppResult<WodMark>> call(Wod wod, WodResultDraft draft);
}

class SaveWodResultUseCase implements SaveWodResultUseCaseContract {
  const SaveWodResultUseCase(this._repository);

  final WodRepositoryContract _repository;

  @override
  Future<AppResult<WodMark>> call(Wod wod, WodResultDraft draft) =>
      _repository.saveResult(wod, draft);
}
