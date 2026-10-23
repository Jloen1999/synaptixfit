import '../../models/academic/subject_timeline_item.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Bloques y entregas de la asignatura en un rango.
abstract interface class GetSubjectTimelineUseCaseContract {
  Future<AppResult<List<SubjectTimelineItem>>> call(
    String subjectId, {
    required DateTime from,
    required DateTime to,
  });
}

class GetSubjectTimelineUseCase implements GetSubjectTimelineUseCaseContract {
  const GetSubjectTimelineUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<List<SubjectTimelineItem>>> call(
    String subjectId, {
    required DateTime from,
    required DateTime to,
  }) => _repository.getTimeline(subjectId, from: from, to: to);
}
