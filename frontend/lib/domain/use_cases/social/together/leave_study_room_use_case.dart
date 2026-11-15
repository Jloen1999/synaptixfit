import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Sale de la sala; los demás siguen.
abstract interface class LeaveStudyRoomUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [LeaveStudyRoomUseCaseContract] con [TogetherRepositoryContract].
class LeaveStudyRoomUseCase implements LeaveStudyRoomUseCaseContract {
  const LeaveStudyRoomUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.leaveStudyRoom(id);
}
