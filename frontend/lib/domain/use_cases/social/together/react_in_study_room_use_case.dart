import '../../../enums/together_enums.dart';
import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Pone (o cambia) mi reacción fija en la sala.
abstract interface class ReactInStudyRoomUseCaseContract {
  Future<AppResult<StudyRoom>> call(
    String id, {
    required StudyRoomReaction reaction,
  });
}

/// Implementa [ReactInStudyRoomUseCaseContract] con [TogetherRepositoryContract].
class ReactInStudyRoomUseCase implements ReactInStudyRoomUseCaseContract {
  const ReactInStudyRoomUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<StudyRoom>> call(
    String id, {
    required StudyRoomReaction reaction,
  }) => _repository.reactInStudyRoom(id, reaction: reaction);
}
