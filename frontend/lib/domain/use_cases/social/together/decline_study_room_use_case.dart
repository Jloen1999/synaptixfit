import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Dice que no a la invitación a una sala.
abstract interface class DeclineStudyRoomUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [DeclineStudyRoomUseCaseContract] con [TogetherRepositoryContract].
class DeclineStudyRoomUseCase implements DeclineStudyRoomUseCaseContract {
  const DeclineStudyRoomUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.declineStudyRoom(id);
}
