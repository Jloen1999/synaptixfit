import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/challenges/challenge.dart';
import '../../../../domain/models/challenges/challenge_outcome.dart';
import '../../../../domain/models/challenges/challenge_page.dart';
import '../../../../domain/models/challenges/challenge_progress_entry.dart';
import '../../../../domain/models/challenges/challenge_summary.dart';
import '../../../../domain/models/challenges/pending_milestone.dart';
import 'challenge_api_values.dart';

part 'challenge_dto.freezed.dart';
part 'challenge_dto.g.dart';

/// `ChallengeResponse` de la API.
@freezed
abstract class ChallengeDto with _$ChallengeDto {
  const factory ChallengeDto({
    required String id,
    required String ownerId,
    @Default(false) bool owned,
    String? ownerName,
    required String title,
    String? type,
    String? goal,
    String? visibility,
    String? difficulty,
    @Default(0) int xpReward,
    @Default(0) int xpAwarded,
    @Default(false) bool completed,
    String? status,
    @Default(0) double progress,
    @Default(true) bool open,
    required String startAt,
    required String endAt,
    String? subjectId,
    String? linkedEntityType,
    String? linkedEntityId,
    String? linkTitle,
    String? linkDueAt,
    bool? linkCompleted,
    @Default(false) bool completedByLink,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
    String? lastActiveDay,
    @Default(false) bool hasDependencies,
    @Default(0) int milestoneCount,
    @Default(0) int completedMilestoneCount,
    @Default(<MilestoneDto>[]) List<MilestoneDto> milestones,
    String? originId,
    String? originOwnerName,
    String? createdAt,
    int? sessionTarget,
    @Default(0) int sessionsCompleted,
    @Default(false) bool tracksTrainingSessions,
  }) = _ChallengeDto;

  const ChallengeDto._();

  factory ChallengeDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeDtoFromJson(json);

  Challenge toDomain() {
    final mapped = milestones.map((m) => m.toDomain()).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final lastDay = lastActiveDay;
    return Challenge(
      id: id,
      ownerId: ownerId,
      owned: owned,
      ownerName: ownerName,
      title: title,
      type: ChallengeApiValues.type(type),
      goal: goal,
      visibility: Visibility.fromApi(visibility),
      difficulty: ChallengeApiValues.difficulty(difficulty),
      xpReward: xpReward,
      xpAwarded: xpAwarded,
      completed: completed,
      status: ChallengeApiValues.status(status),
      progress: progress,
      open: open,
      startAt: ChallengeApiValues.instant(startAt),
      endAt: ChallengeApiValues.instant(endAt),
      subjectId: subjectId,
      link: ChallengeApiValues.link(linkedEntityType, linkedEntityId),
      linkTitle: linkTitle,
      linkDueAt: ChallengeApiValues.instantOrNull(linkDueAt),
      linkCompleted: linkCompleted,
      completedByLink: completedByLink,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      // Es una fecha (sin hora): no se convierte de zona horaria.
      lastActiveDay: lastDay == null ? null : DateTime.parse(lastDay),
      hasDependencies: hasDependencies,
      milestoneCount: milestoneCount == 0 ? mapped.length : milestoneCount,
      completedMilestoneCount: completedMilestoneCount,
      milestones: mapped,
      originId: originId,
      originOwnerName: originOwnerName,
      createdAt: ChallengeApiValues.instantOrNull(createdAt),
      sessionTarget: sessionTarget,
      sessionsCompleted: sessionsCompleted,
      tracksTrainingSessions: tracksTrainingSessions,
    );
  }
}

/// `MilestoneResponse` de la API.
@freezed
abstract class MilestoneDto with _$MilestoneDto {
  const factory MilestoneDto({
    required String id,
    required String title,
    @Default(0) double weight,
    @Default(0) int order,
    @Default(0) double progress,
    @Default(false) bool completed,
    String? status,
    @Default(<String>[]) List<String> dependencies,
    String? conditionType,
    @Default(1) int conditionN,
    String? difficulty,
    @Default(0) int xpReward,
    @Default(0) int xpAwarded,
    String? subjectId,
    String? linkedEntityType,
    String? linkedEntityId,
    String? linkTitle,
    String? linkDueAt,
    bool? linkCompleted,
    @Default(false) bool completedByLink,
    @Default(0) int studyBlocksTotal,
    @Default(0) int studyBlocksCompleted,
    String? noteId,
    String? fileId,
    int? linkWeekNumber,
    int? linkDayNumber,
  }) = _MilestoneDto;

  const MilestoneDto._();

  factory MilestoneDto.fromJson(Map<String, dynamic> json) =>
      _$MilestoneDtoFromJson(json);

  Milestone toDomain() => Milestone(
    id: id,
    title: title,
    weight: weight,
    order: order,
    progress: progress,
    completed: completed,
    status: ChallengeApiValues.milestoneStatus(status),
    dependencies: dependencies,
    condition: ChallengeApiValues.condition(conditionType),
    conditionN: conditionN,
    difficulty: ChallengeApiValues.difficulty(difficulty),
    xpReward: xpReward,
    xpAwarded: xpAwarded,
    subjectId: subjectId,
    link: ChallengeApiValues.link(linkedEntityType, linkedEntityId),
    linkTitle: linkTitle,
    linkDueAt: ChallengeApiValues.instantOrNull(linkDueAt),
    linkCompleted: linkCompleted,
    completedByLink: completedByLink,
    studyBlocksTotal: studyBlocksTotal,
    studyBlocksCompleted: studyBlocksCompleted,
    noteId: noteId,
    fileId: fileId,
    linkWeekNumber: linkWeekNumber,
    linkDayNumber: linkDayNumber,
  );
}

/// `ChallengeOutcomeResponse` de la API.
@freezed
abstract class ChallengeOutcomeDto with _$ChallengeOutcomeDto {
  const factory ChallengeOutcomeDto({
    required ChallengeDto challenge,
    @Default(0) int xpDelta,
    @Default(<String>[]) List<String> unlockedMilestoneIds,
    @Default(false) bool challengeCompleted,
  }) = _ChallengeOutcomeDto;

  const ChallengeOutcomeDto._();

  factory ChallengeOutcomeDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeOutcomeDtoFromJson(json);

  ChallengeOutcome toDomain() => ChallengeOutcome(
    challenge: challenge.toDomain(),
    xpDelta: xpDelta,
    unlockedMilestoneIds: unlockedMilestoneIds,
    challengeCompleted: challengeCompleted,
  );
}

/// `PageResponseChallengeResponse` de la API.
@freezed
abstract class ChallengePageDto with _$ChallengePageDto {
  const factory ChallengePageDto({
    @Default(<ChallengeDto>[]) List<ChallengeDto> items,
    @Default(0) int page,
    @Default(0) int totalPages,
    @Default(0) int totalItems,
  }) = _ChallengePageDto;

  const ChallengePageDto._();

  factory ChallengePageDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengePageDtoFromJson(json);

  ChallengePage toDomain() => ChallengePage(
    items: items.map((c) => c.toDomain()).toList(),
    page: page,
    totalPages: totalPages,
    totalItems: totalItems,
  );
}

/// `ChallengeSummaryResponse` de la API.
@freezed
abstract class ChallengeSummaryDto with _$ChallengeSummaryDto {
  const factory ChallengeSummaryDto({
    @Default(0) int active,
    @Default(0) int completed,
    @Default(0) int expired,
    @Default(0) int upcoming,
    @Default(0) int total,
  }) = _ChallengeSummaryDto;

  const ChallengeSummaryDto._();

  factory ChallengeSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeSummaryDtoFromJson(json);

  ChallengeSummary toDomain() => ChallengeSummary(
    active: active,
    completed: completed,
    expired: expired,
    upcoming: upcoming,
    total: total,
  );
}

/// `PendingMilestoneResponse` de la API.
@freezed
abstract class PendingMilestoneDto with _$PendingMilestoneDto {
  const factory PendingMilestoneDto({
    required String challengeId,
    required String challengeTitle,
    required String challengeEndAt,
    String? challengeType,
    required MilestoneDto milestone,
  }) = _PendingMilestoneDto;

  const PendingMilestoneDto._();

  factory PendingMilestoneDto.fromJson(Map<String, dynamic> json) =>
      _$PendingMilestoneDtoFromJson(json);

  PendingMilestone toDomain() => PendingMilestone(
    challengeId: challengeId,
    challengeTitle: challengeTitle,
    challengeEndAt: ChallengeApiValues.instant(challengeEndAt),
    challengeType: ChallengeApiValues.type(challengeType),
    milestone: milestone.toDomain(),
  );
}

/// `ProgressEntryResponse` de la API.
@freezed
abstract class ProgressEntryDto with _$ProgressEntryDto {
  const factory ProgressEntryDto({
    required String id,
    String? milestoneId,
    @Default(0) double amount,
    required String recordedAt,
  }) = _ProgressEntryDto;

  const ProgressEntryDto._();

  factory ProgressEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ProgressEntryDtoFromJson(json);

  ChallengeProgressEntry toDomain() => ChallengeProgressEntry(
    id: id,
    milestoneId: milestoneId,
    amount: amount,
    recordedAt: ChallengeApiValues.instant(recordedAt),
  );
}
