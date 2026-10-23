import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_difficulty.dart';
import '../../enums/challenge_link_type.dart';
import '../../enums/challenge_status.dart';
import '../../enums/challenge_type.dart';
import '../../enums/milestone_condition.dart';
import '../../enums/milestone_status.dart';
import '../../enums/visibility.dart';

part 'challenge.freezed.dart';

/// Vínculo de un reto o tarea con una entrega, examen o bloque del planificador.
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
    required DateTime startAt,
    required DateTime endAt,
    String? subjectId,
    ChallengeLink? link,
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
    required int xpReward,
    required int xpAwarded,
    String? subjectId,
    ChallengeLink? link,
    String? noteId,
    String? fileId,
  }) = _Milestone;

  const Milestone._();

  bool get isLocked => status == MilestoneStatus.locked;

  bool get hasAttachment => noteId != null || fileId != null;
}
