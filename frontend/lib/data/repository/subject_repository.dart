import '../../domain/enums/evaluation_mode.dart';
import '../../domain/models/academic/subject.dart';
import '../../domain/models/academic/subject_timeline_item.dart';
import '../../domain/models/academic/teaching_guide.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/subject_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/subjects_remote_data_source.dart';

class SubjectRepository implements SubjectRepositoryContract {
  SubjectRepository(this._remote);

  final SubjectsRemoteDataSource _remote;

  @override
  Future<AppResult<List<Subject>>> getSubjects({required bool archived}) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getSubjects(
          archived: archived,
        )).map((s) => s.toDomain()).toList(),
      );

  @override
  Future<AppResult<Subject>> getSubject(String subjectId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getSubject(subjectId)).toDomain(),
      );

  @override
  Future<AppResult<Subject>> createSubject(SubjectInput input) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.createSubject(_body(input))).toDomain(),
      );

  @override
  Future<AppResult<Subject>> updateSubject(
    String subjectId,
    SubjectInput input, {
    bool clearNextAssessment = false,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.updateSubject(subjectId, {
      ..._body(input),
      if (clearNextAssessment) 'clearNextAssessment': true,
    })).toDomain(),
  );

  @override
  Future<AppResult<Subject>> setArchived(String subjectId, bool archived) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.updateSubject(subjectId, {
          'archived': archived,
        })).toDomain(),
      );

  @override
  Future<AppResult<Unit>> deleteSubject(String subjectId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteSubject(subjectId);
        return unit;
      });

  @override
  Future<AppResult<List<SubjectSemester>>> getSemesters() =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.getSemesters()).map((s) => s.toDomain()).toList(),
      );

  @override
  Future<AppResult<SubjectSemester>> assignSemester(
    String subjectId, {
    required int course,
    required int semester,
  }) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.assignSemester(subjectId, course, semester)).toDomain(),
  );

  @override
  Future<AppResult<Unit>> clearSemester(String subjectId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.clearSemester(subjectId);
        return unit;
      });

  @override
  Future<AppResult<Retention>> getRetention(String subjectId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getRetention(subjectId)).toDomain(),
      );

  @override
  Future<AppResult<TeachingGuide>> getTeachingGuide(String subjectId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getTeachingGuide(subjectId)).toDomain(),
      );

  @override
  Future<AppResult<TeachingGuide>> setTeachingGuideMode(
    String subjectId,
    EvaluationMode mode,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.setTeachingGuideMode(
      subjectId,
      mode.apiValue,
    )).toDomain(),
  );

  @override
  Future<AppResult<TeachingGuide>> setTopicCompleted(
    String subjectId,
    int index,
    bool completed,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.setTopicCompleted(
      subjectId,
      index,
      completed,
    )).toDomain(),
  );

  @override
  Future<AppResult<TeachingGuide>> setAssessmentGrade(
    String subjectId,
    int index,
    double? grade,
  ) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.setAssessmentGrade(subjectId, index, grade)).toDomain(),
  );

  @override
  Future<AppResult<List<SubjectTimelineItem>>> getTimeline(
    String subjectId, {
    required DateTime from,
    required DateTime to,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.getTimeline(
      subjectId,
      from,
      to,
    )).map((i) => i.toDomain()).toList(),
  );

  Map<String, dynamic> _body(SubjectInput input) => {
    'name': input.name,
    'code': ?input.code,
    'description': ?input.description,
    'credits': ?input.credits,
    'perceivedDifficulty': ?input.perceivedDifficulty,
    if (input.priority != null) 'priority': input.priority!.apiValue,
    'teacher': ?input.teacher,
    'room': ?input.room,
    if (input.nextAssessmentAt != null)
      'nextAssessmentAt': input.nextAssessmentAt!.toUtc().toIso8601String(),
  };
}
