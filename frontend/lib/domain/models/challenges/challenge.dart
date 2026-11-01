import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_difficulty.dart';
import '../../enums/challenge_link_type.dart';
import '../../enums/challenge_status.dart';
import '../../enums/challenge_type.dart';
import '../../enums/milestone_condition.dart';
import '../../enums/milestone_status.dart';
import '../../enums/visibility.dart';

part 'challenge.freezed.dart';

/// Vínculo de un reto o tarea con una entrega o examen del planificador.
@freezed
abstract class ChallengeLink with _$ChallengeLink {
  const factory ChallengeLink({
    required ChallengeLinkType type,
    required String entityId,
  }) = _ChallengeLink;
}

/// Reto con sus tareas opcionales.
@freezed
abstract class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required String ownerId,
    required bool owned,
    String? ownerName,
    required String title,
    required ChallengeType type,
    String? goal,
    required Visibility visibility,
    required ChallengeDifficulty difficulty,
    required int xpReward,
    required int xpAwarded,
    required bool completed,
    required ChallengeStatus status,

    /// Progreso ponderado 0-100.
    required double progress,

    /// Si ahora se puede actuar a mano (entre inicio y fin). Lo decide el
    /// servidor (ADR 0028); el cliente no repite la regla.
    @Default(true) bool open,
    required DateTime startAt,
    required DateTime endAt,
    String? subjectId,
    ChallengeLink? link,

    /// Entrega o examen vinculado (solo en retos propios): título, fecha y si
    /// ya está hecho. Lo manda el servidor para no tener que pedirlo aparte.
    String? linkTitle,
    DateTime? linkDueAt,
    bool? linkCompleted,

    /// Sin tareas y vinculado: lo completa su entrega, no un toque (lo decide
    /// el servidor; ADR 0028).
    @Default(false) bool completedByLink,

    /// Racha vigente hoy (0 si se rompió), calculada por el servidor.
    required int currentStreak,
    required int bestStreak,
    DateTime? lastActiveDay,
    required bool hasDependencies,
    required int milestoneCount,
    required int completedMilestoneCount,
    @Default(<Milestone>[]) List<Milestone> milestones,
    String? originId,
    String? originOwnerName,
    DateTime? createdAt,

    /// Sesiones de entrenamiento que completan el reto (solo fitness sin tareas).
    int? sessionTarget,

    /// Sesiones completadas dentro del periodo del reto (las cuenta el servidor).
    @Default(0) int sessionsCompleted,

    /// Si el reto avanza solo con las sesiones de Rutinas. Lo decide el
    /// servidor (fitness, con objetivo y sin tareas); el cliente no lo recalcula.
    @Default(false) bool tracksTrainingSessions,
  }) = _Challenge;

  const Challenge._();

  bool get hasMilestones => milestoneCount > 0 || milestones.isNotEmpty;

  /// Progreso entre 0 y 1.
  double get progressFraction => (progress / 100).clamp(0, 1).toDouble();

  bool get isCloned => originId != null;

  /// XP total que se restaría al borrar el reto (reto + tareas).
  int get totalXpAwarded =>
      xpAwarded + milestones.fold(0, (sum, m) => sum + m.xpAwarded);

  /// Siguiente tarea que se puede marcar ya: la primera, en el orden del reto,
  /// sin completar, sin bloquear y que no complete su vínculo (esas avanzan
  /// solas). `null` si no hay ninguna.
  Milestone? get nextMilestone {
    final open =
        milestones
            .where((m) => !m.completed && !m.isLocked && !m.completedByLink)
            .toList()
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
          });
    return open.isEmpty ? null : open.first;
  }

  /// Sesiones que faltan para el objetivo (0 si no sigue sesiones o ya llegó).
  int get sessionsRemaining {
    if (!tracksTrainingSessions) return 0;
    final left = (sessionTarget ?? 0) - sessionsCompleted;
    return left < 0 ? 0 : left;
  }

  Milestone? milestoneById(String id) {
    for (final m in milestones) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// Tarea de un reto.
@freezed
abstract class Milestone with _$Milestone {
  const factory Milestone({
    required String id,
    required String title,
    required double weight,
    required int order,

    /// Progreso 0-100 de la tarea.
    required double progress,
    required bool completed,
    required MilestoneStatus status,
    @Default(<String>[]) List<String> dependencies,
    required MilestoneCondition condition,
    required int conditionN,
    required ChallengeDifficulty difficulty,

    /// XP real con el tope del reto (la que dio si está completada).
    required int xpReward,
    required int xpAwarded,
    String? subjectId,
    ChallengeLink? link,
    String? linkTitle,
    DateTime? linkDueAt,
    bool? linkCompleted,

    /// La completa su entrega/examen o sus bloques del calendario, no un toque.
    @Default(false) bool completedByLink,
    @Default(0) int studyBlocksTotal,
    @Default(0) int studyBlocksCompleted,
    String? noteId,
    String? fileId,
  }) = _Milestone;

  const Milestone._();

  bool get isLocked => status == MilestoneStatus.locked;

  bool get hasAttachment => noteId != null || fileId != null;

  /// Avanza con bloques del calendario asignados a la tarea.
  bool get hasStudyBlocks => studyBlocksTotal > 0;
}
