import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Elige mi asignatura para las rondas (`null`: ninguna); solo la veo yo.
abstract interface class ChooseStudyRoomSubjectUseCaseContract {
  Future<AppResult<StudyRoom>> call(String id, {String? subjectId});
}

/// Implementa [ChooseStudyRoomSubjectUseCaseContract] con [TogetherRepositoryContract].
class ChooseStudyRoomSubjectUseCase
    implements ChooseStudyRoomSubjectUseCaseContract {
  const ChooseStudyRoomSubjectUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<StudyRoom>> call(String id, {String? subjectId}) =>
      _repository.chooseStudyRoomSubject(id, subjectId: subjectId);
}
