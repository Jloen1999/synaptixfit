import '../models/academic/subject_file.dart';
import '../models/academic/teaching_guide_import.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Importación de planes docentes: subida del PDF, análisis con IA en el
/// servidor, revisión y aplicación a una asignatura.
abstract interface class TeachingGuideImportRepositoryContract {
  /// Sube el PDF (URL firmada) y pide su análisis. [onProgress] va de 0 a 1.
  Future<AppResult<TeachingGuideImport>> start(
    FileUploadPayload payload, {
    String? targetSubjectId,
    void Function(double progress)? onProgress,
  });

  Future<AppResult<TeachingGuideImport>> get(String importId);

  Future<AppResult<TeachingGuideImport>> retry(String importId);

  /// [subjectId] nulo crea una asignatura nueva.
  Future<AppResult<TeachingGuideImportResult>> apply(
    String importId, {
    String? subjectId,
    required GuideDraft draft,
    required bool createDeadlines,
  });

  Future<AppResult<Unit>> discard(String importId);
}
