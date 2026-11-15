import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Entra en la sala (o vuelve tras salir: «Deshacer»).
abstract interface class JoinStudyRoomUseCaseContract {
  Future<AppResult<StudyRoom>> call(String id);
}

/// Implementa [JoinStudyRoomUseCaseContract] con [TogetherRepositoryContract].
class JoinStudyRoomUseCase implements JoinStudyRoomUseCaseContract {
  const JoinStudyRoomUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<StudyRoom>> call(String id) => _repository.joinStudyRoom(id);
}
