part of 'challenge_form_bloc.dart';

enum ChallengeFormStatus { loading, ready, saving, failure }

/// `create`: reto nuevo completo. `editMilestones`: reemplazar las tareas de un reto.
enum ChallengeFormMode { create, editMilestones }

@freezed
abstract class ChallengeFormState with _$ChallengeFormState {
  const factory ChallengeFormState({
    @Default(ChallengeFormStatus.loading) ChallengeFormStatus status,
    @Default(ChallengeFormMode.create) ChallengeFormMode mode,
    String? challengeId,
    @Default('') String title,
    @Default('') String goal,
    @Default(ChallengeType.academic) ChallengeType type,
    @Default(ChallengeDifficulty.medium) ChallengeDifficulty difficulty,
    @Default(Visibility.private) Visibility visibility,
    DateTime? startAt,
    DateTime? endAt,
    String? subjectId,

    /// Nombre de la asignatura recibida al abrir el formulario (aunque aún no
    /// estén cargadas las asignaturas).
    String? subjectName,
    ChallengeLink? link,
    String? linkLabel,
    @Default(<ChallengeSubjectOption>[]) List<ChallengeSubjectOption> subjects,
    @Default(<MilestoneFormItem>[]) List<MilestoneFormItem> milestones,

    /// «Hacer las tareas en orden»: cada tarea depende de la anterior. Es la
    /// forma simple de las dependencias; las demás solo se editan si el reto ya
    /// las tenía.
    @Default(false) bool inOrder,

    /// El reto que se edita avanza con las sesiones de entrenamiento (lo dice
    /// el servidor): añadirle tareas lo deja de hacer y hay que avisarlo.
    @Default(false) bool tracksTrainingSessions,

    /// Objetivo de sesiones de entrenamiento escrito (solo se envía si aplica).
    int? sessionTarget,

    /// Motivo de validación que impide guardar.
    ChallengeDraftIssue? issue,

    /// Error al cargar (status failure) o al guardar.
    AppError? error,
    ChallengeFormEffect? effect,
  }) = _ChallengeFormState;

  const ChallengeFormState._();

  /// El objetivo de sesiones solo tiene sentido en un reto nuevo de fitness
  /// sin tareas: con tareas, el progreso lo marcan ellas.
  bool get showsSessionTarget =>
      mode == ChallengeFormMode.create &&
      type == ChallengeType.fitness &&
      milestones.isEmpty;

  bool get canAddMilestone =>
      milestones.length < ChallengeDraftValidator.maxMilestones;

  /// Dependencias a medida (no «en orden») que ya tenía el reto: solo
  /// entonces se muestra su editor completo en cada tarea.
  bool get hasCustomDependencies =>
      !inOrder && milestones.any((m) => m.dependsOnKeys.isNotEmpty);

  String? get selectedSubjectName {
    final id = subjectId;
    if (id == null) return null;
    for (final s in subjects) {
      if (s.id == id) return s.name;
    }
    return subjectName;
  }
}

/// Tarea en edición dentro del formulario. Las dependencias se guardan por
/// [key] para que sobrevivan a reordenaciones; al guardar se pasan a posiciones.
@freezed
abstract class MilestoneFormItem with _$MilestoneFormItem {
  const factory MilestoneFormItem({
    required String key,

    /// Id de la tarea existente (modo edición).
    String? id,
    required String title,
    @Default(ChallengeDifficulty.medium) ChallengeDifficulty difficulty,
    String? noteId,
    String? noteTitle,
    String? fileId,
    String? fileName,
    ChallengeLink? link,
    String? linkLabel,
    @Default(<String>[]) List<String> dependsOnKeys,
    @Default(MilestoneCondition.all) MilestoneCondition condition,
    @Default(1) int conditionN,
    @Default(false) bool completed,
  }) = _MilestoneFormItem;
}

@freezed
sealed class ChallengeFormEffect with _$ChallengeFormEffect {
  /// Guardado correcto. [account] es la cuenta refrescada si cambió la XP.
  const factory ChallengeFormEffect.saved({
    required String challengeId,
    @Default(0) int xpDelta,
    Account? account,
  }) = ChallengeFormSaved;

  const factory ChallengeFormEffect.failure(AppError error) =
      ChallengeFormSaveFailed;
}
