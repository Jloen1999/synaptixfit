import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/challenges/challenge_draft.dart';
import 'challenge_api_values.dart';

part 'challenge_request_dto.freezed.dart';
part 'challenge_request_dto.g.dart';

/// `CreateChallengeRequest` de la API.
@freezed
abstract class CreateChallengeRequestDto with _$CreateChallengeRequestDto {
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory CreateChallengeRequestDto({
    required String title,
    String? type,
    String? goal,
    String? visibility,
    String? difficulty,
    String? startAt,
    required String endAt,
    String? subjectId,
    String? linkedEntityType,
    String? linkedEntityId,
    @Default(<MilestoneRequestDto>[]) List<MilestoneRequestDto> milestones,
    int? sessionTarget,
  }) = _CreateChallengeRequestDto;

  factory CreateChallengeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateChallengeRequestDtoFromJson(json);

  factory CreateChallengeRequestDto.fromDomain(ChallengeDraft draft) {
    final goal = draft.goal?.trim();
    final type = draft.type;
    final start = draft.startAt;
    final link = draft.link;
    return CreateChallengeRequestDto(
      title: draft.title.trim(),
      type: type == null ? null : ChallengeApiValues.typeToApi(type),
      goal: goal == null || goal.isEmpty ? null : goal,
      visibility: draft.visibility.apiValue,
      difficulty: ChallengeApiValues.difficultyToApi(draft.difficulty),
      startAt: start == null ? null : ChallengeApiValues.toInstant(start),
      endAt: ChallengeApiValues.toInstant(draft.endAt),
      subjectId: draft.subjectId,
      linkedEntityType: link == null
          ? null
          : ChallengeApiValues.linkTypeToApi(link.type),
      linkedEntityId: link?.entityId,
      milestones: draft.milestones.map(MilestoneRequestDto.fromDomain).toList(),
      sessionTarget: draft.sessionTarget,
    );
  }
}

/// `MilestoneRequest` de la API.
@freezed
abstract class MilestoneRequestDto with _$MilestoneRequestDto {
  @JsonSerializable(includeIfNull: false)
  const factory MilestoneRequestDto({
    String? id,
    required String title,
    String? difficulty,
    String? subjectId,
    String? noteId,
    String? fileId,
    String? linkedEntityType,
    String? linkedEntityId,
    @Default(<int>[]) List<int> dependsOn,
    String? conditionType,
    int? conditionN,
  }) = _MilestoneRequestDto;

  factory MilestoneRequestDto.fromJson(Map<String, dynamic> json) =>
      _$MilestoneRequestDtoFromJson(json);

  factory MilestoneRequestDto.fromDomain(MilestoneDraft draft) {
    final link = draft.link;
    final hasDeps = draft.dependsOn.isNotEmpty;
    return MilestoneRequestDto(
      id: draft.id,
      title: draft.title.trim(),
      difficulty: ChallengeApiValues.difficultyToApi(draft.difficulty),
      subjectId: draft.subjectId,
      noteId: draft.noteId,
      fileId: draft.fileId,
      linkedEntityType: link == null
          ? null
          : ChallengeApiValues.linkTypeToApi(link.type),
      linkedEntityId: link?.entityId,
      dependsOn: draft.dependsOn,
      conditionType: hasDeps
          ? ChallengeApiValues.conditionToApi(draft.condition)
          : null,
      conditionN: hasDeps ? draft.conditionN : null,
    );
  }
}

/// `UpdateChallengeRequest` de la API (los nulos no cambian).
@freezed
abstract class UpdateChallengeRequestDto with _$UpdateChallengeRequestDto {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateChallengeRequestDto({
    String? title,
    String? type,
    String? goal,
    String? visibility,
    String? difficulty,
    String? startAt,
    String? endAt,
    String? subjectId,
    bool? clearSubject,
    String? linkedEntityType,
    String? linkedEntityId,
    bool? clearLink,
    int? sessionTarget,
    bool? clearSessionTarget,
  }) = _UpdateChallengeRequestDto;

  factory UpdateChallengeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateChallengeRequestDtoFromJson(json);

  factory UpdateChallengeRequestDto.fromDomain(ChallengeChanges changes) {
    final type = changes.type;
    final difficulty = changes.difficulty;
    final start = changes.startAt;
    final end = changes.endAt;
    final link = changes.link;
    return UpdateChallengeRequestDto(
      title: changes.title?.trim(),
      type: type == null ? null : ChallengeApiValues.typeToApi(type),
      goal: changes.goal?.trim(),
      visibility: changes.visibility?.apiValue,
      difficulty: difficulty == null
          ? null
          : ChallengeApiValues.difficultyToApi(difficulty),
      startAt: start == null ? null : ChallengeApiValues.toInstant(start),
      endAt: end == null ? null : ChallengeApiValues.toInstant(end),
      subjectId: changes.clearSubject ? null : changes.subjectId,
      clearSubject: changes.clearSubject ? true : null,
      linkedEntityType: changes.clearLink || link == null
          ? null
          : ChallengeApiValues.linkTypeToApi(link.type),
      linkedEntityId: changes.clearLink ? null : link?.entityId,
      clearLink: changes.clearLink ? true : null,
      sessionTarget: changes.clearSessionTarget ? null : changes.sessionTarget,
      clearSessionTarget: changes.clearSessionTarget ? true : null,
    );
  }
}
