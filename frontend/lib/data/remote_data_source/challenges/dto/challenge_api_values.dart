import '../../../../domain/enums/challenge_difficulty.dart';
import '../../../../domain/enums/challenge_link_type.dart';
import '../../../../domain/enums/challenge_status.dart';
import '../../../../domain/enums/challenge_tasks_filter.dart';
import '../../../../domain/enums/challenge_type.dart';
import '../../../../domain/enums/milestone_condition.dart';
import '../../../../domain/enums/milestone_status.dart';
import '../../../../domain/models/challenges/challenge.dart';

/// Traducción entre los enums de la API (UPPER_SNAKE_CASE) y los de dominio.
abstract final class ChallengeApiValues {
  static ChallengeType type(String? value) =>
      value == 'ACADEMIC' ? ChallengeType.academic : ChallengeType.fitness;

  static String typeToApi(ChallengeType value) => switch (value) {
    ChallengeType.fitness => 'FITNESS',
    ChallengeType.academic => 'ACADEMIC',
  };

  static ChallengeStatus status(String? value) => switch (value) {
    'UPCOMING' => ChallengeStatus.upcoming,
    'COMPLETED' => ChallengeStatus.completed,
    'EXPIRED' => ChallengeStatus.expired,
    _ => ChallengeStatus.active,
  };

  static String statusToApi(ChallengeStatus value) => value.name.toUpperCase();

  static ChallengeDifficulty difficulty(String? value) => switch (value) {
    'LOW' => ChallengeDifficulty.low,
    'HIGH' => ChallengeDifficulty.high,
    _ => ChallengeDifficulty.medium,
  };

  static String difficultyToApi(ChallengeDifficulty value) =>
      value.name.toUpperCase();

  static MilestoneStatus milestoneStatus(String? value) => switch (value) {
    'LOCKED' => MilestoneStatus.locked,
    'IN_PROGRESS' => MilestoneStatus.inProgress,
    'COMPLETED' => MilestoneStatus.completed,
    _ => MilestoneStatus.available,
  };

  static MilestoneCondition condition(String? value) => switch (value) {
    'OR' => MilestoneCondition.any,
    'X_OF_Y' => MilestoneCondition.xOfY,
    _ => MilestoneCondition.all,
  };

  static String conditionToApi(MilestoneCondition value) => switch (value) {
    MilestoneCondition.all => 'AND',
    MilestoneCondition.any => 'OR',
    MilestoneCondition.xOfY => 'X_OF_Y',
  };

  static ChallengeLinkType? linkType(String? value) => switch (value) {
    'EXAM' => ChallengeLinkType.exam,
    'DELIVERY' => ChallengeLinkType.delivery,
    _ => null,
  };

  static String linkTypeToApi(ChallengeLinkType value) =>
      value.name.toUpperCase();

  static ChallengeLink? link(String? type, String? id) {
    final linkType = ChallengeApiValues.linkType(type);
    return linkType == null || id == null
        ? null
        : ChallengeLink(type: linkType, entityId: id);
  }

  static String tasksToApi(ChallengeTasksFilter value) => switch (value) {
    ChallengeTasksFilter.withTasks => 'WITH',
    ChallengeTasksFilter.withoutTasks => 'WITHOUT',
  };

  /// Instante ISO-8601 de la API → hora local.
  static DateTime instant(String value) => DateTime.parse(value).toLocal();

  static DateTime? instantOrNull(String? value) =>
      value == null ? null : instant(value);

  /// Hora local → instante ISO-8601 UTC para la API.
  static String toInstant(DateTime value) => value.toUtc().toIso8601String();
}
