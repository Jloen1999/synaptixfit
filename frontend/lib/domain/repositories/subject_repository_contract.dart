import '../enums/evaluation_mode.dart';
import '../models/academic/subject.dart';
import '../models/academic/subject_timeline_item.dart';
import '../models/academic/teaching_guide.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Asignaturas, catálogo, semestres, guía docente, retención y línea de tiempo.
abstract interface class SubjectRepositoryContract {
  Future<AppResult<List<Subject>>> getSubjects({required bool archived});

  Future<AppResult<Subject>> getSubject(String subjectId);

  Future<AppResult<Subject>> createSubject(SubjectInput input);

  /// [clearNextAssessment] borra la fecha de la próxima evaluación.
  Future<AppResult<Subject>> updateSubject(
    String subjectId,
    SubjectInput input, {
    bool clearNextAssessment = false,
  });

  Future<AppResult<Subject>> setArchived(String subjectId, bool archived);

  Future<AppResult<Unit>> deleteSubject(String subjectId);

  Future<AppResult<List<SubjectSemester>>> getSemesters();

  Future<AppResult<SubjectSemester>> assignSemester(
    String subjectId, {
    required int course,
    required int semester,
  });

  Future<AppResult<Unit>> clearSemester(String subjectId);

  Future<AppResult<Retention>> getRetention(String subjectId);

  Future<AppResult<TeachingGuide>> getTeachingGuide(String subjectId);

  Future<AppResult<TeachingGuide>> setTeachingGuideMode(
    String subjectId,
    EvaluationMode mode,
  );

  Future<AppResult<TeachingGuide>> setTopicCompleted(
    String subjectId,
    int index,
    bool completed,
  );

  /// [grade] nulo borra la nota del criterio.
  Future<AppResult<TeachingGuide>> setAssessmentGrade(
    String subjectId,
    int index,
    double? grade,
  );

  Future<AppResult<List<SubjectTimelineItem>>> getTimeline(
    String subjectId, {
    required DateTime from,
    required DateTime to,
  });
}
