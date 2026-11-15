import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Crea una sala de «Estudiamos juntos» con 1-4 amigos y los minutos de cada
/// ronda; quien la crea queda dentro.
abstract interface class CreateStudyRoomUseCaseContract {
  Future<AppResult<StudyRoom>> call({
    required StudyRoomTimes times,
    required int rounds,
    required List<String> friendIds,
    String? subjectId,
  });
}

/// Implementa [CreateStudyRoomUseCaseContract] con [TogetherRepositoryContract].
class CreateStudyRoomUseCase implements CreateStudyRoomUseCaseContract {
  const CreateStudyRoomUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<StudyRoom>> call({
    required StudyRoomTimes times,
    required int rounds,
    required List<String> friendIds,
    String? subjectId,
  }) => _repository.createStudyRoom(
    times: times,
    rounds: rounds,
    friendIds: friendIds,
    subjectId: subjectId,
  );
}
