import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Una sala en la que estoy invitada o dentro.
abstract interface class GetStudyRoomUseCaseContract {
  Future<AppResult<StudyRoom>> call(String id);
}

/// Implementa [GetStudyRoomUseCaseContract] con [TogetherRepositoryContract].
class GetStudyRoomUseCase implements GetStudyRoomUseCaseContract {
  const GetStudyRoomUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<StudyRoom>> call(String id) => _repository.studyRoom(id);
}
