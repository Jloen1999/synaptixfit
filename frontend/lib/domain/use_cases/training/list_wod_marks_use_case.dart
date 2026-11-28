import '../../models/result/app_result.dart';
import '../../models/training/wod.dart';
import '../../repositories/wod_repository_contract.dart';

/// «Mis marcas», de la más reciente a la más antigua (ADR 0069).
abstract interface class ListWodMarksUseCaseContract {
  Future<AppResult<List<WodMark>>> call();
}

class ListWodMarksUseCase implements ListWodMarksUseCaseContract {
  const ListWodMarksUseCase(this._repository);

  final WodRepositoryContract _repository;

  @override
  Future<AppResult<List<WodMark>>> call() => _repository.listMarks();
}
