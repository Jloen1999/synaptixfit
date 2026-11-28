import '../../models/result/app_result.dart';
import '../../models/training/wod.dart';
import '../../repositories/wod_repository_contract.dart';

/// La pizarra de hoy: mi WOD o una plantilla de ejemplo, con sus marcas (ADR 0069).
abstract interface class GetWodBoardUseCaseContract {
  Future<AppResult<WodBoard>> call({String? templateCode});
}

class GetWodBoardUseCase implements GetWodBoardUseCaseContract {
  const GetWodBoardUseCase(this._repository);

  final WodRepositoryContract _repository;

  @override
  Future<AppResult<WodBoard>> call({String? templateCode}) =>
      _repository.board(templateCode: templateCode);
}
