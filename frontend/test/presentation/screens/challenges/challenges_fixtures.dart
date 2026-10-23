import 'package:synaptixfit/domain/enums/challenge_difficulty.dart';
import 'package:synaptixfit/domain/enums/challenge_status.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/enums/milestone_condition.dart';
import 'package:synaptixfit/domain/enums/milestone_status.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/challenges/challenge.dart';

/// Datos de prueba compartidos por los tests del módulo challenges.
abstract final class ChallengesFixtures {
  static const account = Account(
    id: 'u1',
    email: 'ana@uni.es',
    fullName: 'Ana',
    level: 2,
    levelXp: 40,
    levelThreshold: 200,
    streak: 3,
    privacy: Visibility.private,
    role: UserRole.user,
    hasPassword: true,
    googleLinked: false,
  );

  static Milestone milestone(
    String id, {
    bool completed = false,
    MilestoneStatus status = MilestoneStatus.available,
    List<String> dependencies = const [],
    int xpAwarded = 0,
  }) => Milestone(
    id: id,
    title: 'Tarea $id',
    weight: 50,
    order: 1,
    progress: completed ? 100 : 0,
    completed: completed,
    status: completed ? MilestoneStatus.completed : status,
    dependencies: dependencies,
    condition: MilestoneCondition.all,
    conditionN: 1,
    difficulty: ChallengeDifficulty.medium,
    xpReward: 40,
    xpAwarded: xpAwarded,
  );

  static Challenge challenge({
    String id = 'c1',
    bool owned = true,
    bool completed = false,
    int xpAwarded = 0,
    String? subjectId,
    List<Milestone> milestones = const [],
  }) => Challenge(
    id: id,
    ownerId: owned ? 'u1' : 'u2',
    owned: owned,
    ownerName: owned ? 'Ana' : 'Luis',
    title: 'Reto $id',
    type: ChallengeType.academic,
    visibility: Visibility.private,
    difficulty: ChallengeDifficulty.medium,
    xpReward: 40,
    xpAwarded: xpAwarded,
    completed: completed,
    status: completed ? ChallengeStatus.completed : ChallengeStatus.active,
    progress: completed ? 100 : 0,
    startAt: DateTime(2026, 10, 1),
    endAt: DateTime(2026, 10, 30, 23, 59),
    subjectId: subjectId,
    currentStreak: 0,
    bestStreak: 0,
    hasDependencies: milestones.any((m) => m.dependencies.isNotEmpty),
    milestoneCount: milestones.length,
    completedMilestoneCount: milestones.where((m) => m.completed).length,
    milestones: milestones,
  );
}
