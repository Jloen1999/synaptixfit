import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Empieza el temporizador común (cualquiera de dentro, una vez).
abstract interface class StartStudyRoomUseCaseContract {
  Future<AppResult<StudyRoom>> call(String id);
}

/// Implementa [StartStudyRoomUseCaseContract] con [TogetherRepositoryContract].
class StartStudyRoomUseCase implements StartStudyRoomUseCaseContract {
  const StartStudyRoomUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<StudyRoom>> call(String id) =>
      _repository.startStudyRoom(id);
}
