import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Cambia los minutos de concentración y descanso de una sala que aún no ha
/// empezado; cualquiera de dentro puede (ADR 0053).
abstract interface class ChangeStudyRoomTimesUseCaseContract {
  Future<AppResult<StudyRoom>> call(String id, StudyRoomTimes times);
}

/// Implementa [ChangeStudyRoomTimesUseCaseContract] con
/// [TogetherRepositoryContract].
class ChangeStudyRoomTimesUseCase
    implements ChangeStudyRoomTimesUseCaseContract {
  const ChangeStudyRoomTimesUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<StudyRoom>> call(String id, StudyRoomTimes times) =>
      _repository.changeStudyRoomTimes(id, times);
}
