import '../models/challenges/challenge_references.dart';
import '../models/result/app_result.dart';

/// Datos de otros módulos que necesitan los retos: asignaturas, material
/// adjuntable y entregas/bloques vinculables.
abstract interface class ChallengeReferencesRepositoryContract {
  /// Asignaturas activas del usuario.
  Future<AppResult<List<ChallengeSubjectOption>>> subjects();

  /// Apuntes y archivos de una asignatura; sin asignatura, los apuntes sin asignar.
  Future<AppResult<ChallengeAttachmentOptions>> attachments(String? subjectId);

  /// Entregas y exámenes pendientes y bloques de estudio futuros.
  Future<AppResult<List<ChallengeLinkOption>>> linkTargets({
    String? subjectId,
    required DateTime from,
    required DateTime to,
  });

  /// URL firmada para abrir un archivo adjunto.
  Future<AppResult<String>> fileUrl(String fileId);
}
