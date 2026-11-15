import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/challenge_rule_kind.dart';
import '../../../../domain/enums/together_enums.dart';
import '../../../../domain/models/social/together.dart';

part 'together_dto.freezed.dart';
part 'together_dto.g.dart';

/// `PersonResponse`: otra persona, solo nombre y foto.
@freezed
abstract class TogetherPersonDto with _$TogetherPersonDto {
  const factory TogetherPersonDto({
    required String id,
    String? fullName,
    String? avatarUrl,
  }) = _TogetherPersonDto;

  const TogetherPersonDto._();

  factory TogetherPersonDto.fromJson(Map<String, dynamic> json) =>
      _$TogetherPersonDtoFromJson(json);

  TogetherPerson toDomain() =>
      TogetherPerson(id: id, name: fullName ?? '', avatarUrl: avatarUrl);
}

/// `FriendChallengeResponse.Member`.
@freezed
abstract class FriendChallengeMemberDto with _$FriendChallengeMemberDto {
  const factory FriendChallengeMemberDto({
    required TogetherPersonDto person,
    String? status,
    @Default(false) bool contributed,
    int? points,
    @Default(false) bool me,
  }) = _FriendChallengeMemberDto;

  const FriendChallengeMemberDto._();

  factory FriendChallengeMemberDto.fromJson(Map<String, dynamic> json) =>
      _$FriendChallengeMemberDtoFromJson(json);

  FriendChallengeMember toDomain() => FriendChallengeMember(
    person: person.toDomain(),
    status: TogetherMemberStatus.fromApi(status),
    contributed: contributed,
    points: points,
    me: me,
  );
}

/// `FriendChallengeResponse.BoardEntry`; `day` llega como «2026-11-16».
@freezed
abstract class FriendChallengeBoardEntryDto
    with _$FriendChallengeBoardEntryDto {
  const factory FriendChallengeBoardEntryDto({
    required TogetherPersonDto person,
    required String day,
    @Default(false) bool mine,
    @Default(<String, int>{}) Map<String, int> counts,
    String? myReaction,
  }) = _FriendChallengeBoardEntryDto;

  const FriendChallengeBoardEntryDto._();

  factory FriendChallengeBoardEntryDto.fromJson(Map<String, dynamic> json) =>
      _$FriendChallengeBoardEntryDtoFromJson(json);

  FriendChallengeBoardEntry toDomain() => FriendChallengeBoardEntry(
    person: person.toDomain(),
    day: DateTime.parse(day),
    mine: mine,
    counts: {
      for (final MapEntry(:key, :value) in counts.entries)
        ?TogetherReaction.fromApi(key): value,
    },
    myReaction: TogetherReaction.fromApi(myReaction),
  );
}

/// `FriendChallengeResponse` (ADR 0044).
@freezed
abstract class FriendChallengeDto with _$FriendChallengeDto {
  const factory FriendChallengeDto({
    required String id,
    @Default('') String title,
    @Default('') String goal,
    String? metric,
    String? unit,
    String? mode,
    required DateTime startAt,
    required DateTime endAt,
    @Default(7) int days,
    String? myStatus,
    required TogetherPersonDto creator,
    @Default(0) int groupTotal,
    @Default(1) int groupTarget,
    @Default(0) int myPoints,
    @Default(1) int myTarget,
    @Default(false) bool over,
    @Default(<FriendChallengeMemberDto>[])
    List<FriendChallengeMemberDto> members,
    @Default(<FriendChallengeBoardEntryDto>[])
    List<FriendChallengeBoardEntryDto> board,
  }) = _FriendChallengeDto;

  const FriendChallengeDto._();

  factory FriendChallengeDto.fromJson(Map<String, dynamic> json) =>
      _$FriendChallengeDtoFromJson(json);

  FriendChallenge toDomain() => FriendChallenge(
    id: id,
    title: title,
    goal: goal,
    metric: ChallengeRuleMetric.fromApi(metric),
    unit: ChallengeRuleUnit.fromApi(unit),
    mode: FriendChallengeMode.fromApi(mode),
    startAt: startAt.toLocal(),
    endAt: endAt.toLocal(),
    days: days,
    myStatus: TogetherMemberStatus.fromApi(myStatus),
    creator: creator.toDomain(),
    groupTotal: groupTotal,
    groupTarget: groupTarget,
    myPoints: myPoints,
    myTarget: myTarget,
    over: over,
    members: [for (final m in members) m.toDomain()],
    board: [for (final b in board) b.toDomain()],
  );
}

/// `FriendStreakResponse` (ADR 0044).
@freezed
abstract class FriendStreakDto with _$FriendStreakDto {
  const factory FriendStreakDto({
    required String id,
    String? status,
    required TogetherPersonDto friend,
    @Default(false) bool requestedByMe,
    @Default(0) int days,
    @Default(false) bool meDone,
    @Default(false) bool friendDone,
    @Default(false) bool paused,
    @Default(false) bool canNudge,
  }) = _FriendStreakDto;

  const FriendStreakDto._();

  factory FriendStreakDto.fromJson(Map<String, dynamic> json) =>
      _$FriendStreakDtoFromJson(json);

  FriendStreak toDomain() => FriendStreak(
    id: id,
    status: FriendStreakStatus.fromApi(status),
    friend: friend.toDomain(),
    requestedByMe: requestedByMe,
    days: days,
    meDone: meDone,
    friendDone: friendDone,
    paused: paused,
    canNudge: canNudge,
  );
}

/// `WorkoutTogetherResponse.Slot`.
@freezed
abstract class WorkoutSlotDto with _$WorkoutSlotDto {
  const factory WorkoutSlotDto({
    required int index,
    required String exerciseId,
    String? name,
  }) = _WorkoutSlotDto;

  const WorkoutSlotDto._();

  factory WorkoutSlotDto.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSlotDtoFromJson(json);

  WorkoutSlot toDomain() =>
      WorkoutSlot(index: index, exerciseId: exerciseId, name: name ?? '');
}

/// `WorkoutTogetherResponse.Member`.
@freezed
abstract class WorkoutTogetherMemberDto with _$WorkoutTogetherMemberDto {
  const factory WorkoutTogetherMemberDto({
    required TogetherPersonDto person,
    String? status,
    String? state,
    @Default(<int>[]) List<int> doneSlots,
    @Default(false) bool me,
  }) = _WorkoutTogetherMemberDto;

  const WorkoutTogetherMemberDto._();

  factory WorkoutTogetherMemberDto.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTogetherMemberDtoFromJson(json);

  WorkoutTogetherMember toDomain() => WorkoutTogetherMember(
    person: person.toDomain(),
    status: TogetherMemberStatus.fromApi(status),
    state: WorkoutMemberState.fromApi(state),
    doneSlots: doneSlots,
    me: me,
  );
}

/// `WorkoutTogetherResponse` (ADR 0044); `date` llega como «2026-11-16».
@freezed
abstract class WorkoutTogetherDto with _$WorkoutTogetherDto {
  const factory WorkoutTogetherDto({
    required String id,
    required TogetherPersonDto host,
    String? routineName,
    String? dayName,
    @Default(0) int dayNumber,
    required String date,
    @Default(false) bool today,
    String? myStatus,
    String? mySessionId,
    int? myMinutes,
    @Default(<WorkoutSlotDto>[]) List<WorkoutSlotDto> exercises,
    @Default(<WorkoutTogetherMemberDto>[])
    List<WorkoutTogetherMemberDto> members,
  }) = _WorkoutTogetherDto;

  const WorkoutTogetherDto._();

  factory WorkoutTogetherDto.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTogetherDtoFromJson(json);

  WorkoutTogether toDomain() => WorkoutTogether(
    id: id,
    host: host.toDomain(),
    routineName: routineName,
    dayName: dayName,
    dayNumber: dayNumber,
    date: DateTime.parse(date),
    today: today,
    myStatus: TogetherMemberStatus.fromApi(myStatus),
    mySessionId: mySessionId,
    myMinutes: myMinutes,
    exercises: [for (final s in exercises) s.toDomain()],
    members: [for (final m in members) m.toDomain()],
  );
}

/// `StudyRoomResponse.StudyRoomMember`.
@freezed
abstract class StudyRoomMemberDto with _$StudyRoomMemberDto {
  const factory StudyRoomMemberDto({
    required TogetherPersonDto person,
    String? status,
    String? reaction,
    @Default(false) bool me,
  }) = _StudyRoomMemberDto;

  const StudyRoomMemberDto._();

  factory StudyRoomMemberDto.fromJson(Map<String, dynamic> json) =>
      _$StudyRoomMemberDtoFromJson(json);

  StudyRoomMember toDomain() => StudyRoomMember(
    person: person.toDomain(),
    status: TogetherMemberStatus.fromApi(status),
    reaction: StudyRoomReaction.fromApi(reaction),
    me: me,
  );
}

/// `StudyRoomResponse` (ADR 0045). Los instantes llegan en UTC; se pasan a la
/// hora local del móvil.
@freezed
abstract class StudyRoomDto with _$StudyRoomDto {
  const factory StudyRoomDto({
    required String id,
    required TogetherPersonDto creator,
    String? length,
    @Default(25) int focusMinutes,
    @Default(5) int breakMinutes,
    @Default(1) int rounds,
    String? phase,
    @Default(0) int round,
    DateTime? phaseEndsAt,
    DateTime? startedAt,
    DateTime? endsAt,
    required DateTime serverTime,
    String? myStatus,
    String? mySubjectId,
    @Default(<StudyRoomMemberDto>[]) List<StudyRoomMemberDto> members,
  }) = _StudyRoomDto;

  const StudyRoomDto._();

  factory StudyRoomDto.fromJson(Map<String, dynamic> json) =>
      _$StudyRoomDtoFromJson(json);

  StudyRoom toDomain() => StudyRoom(
    id: id,
    creator: creator.toDomain(),
    length: StudyRoomLength.fromApi(length),
    focusMinutes: focusMinutes,
    breakMinutes: breakMinutes,
    rounds: rounds,
    phase: StudyRoomPhase.fromApi(phase),
    round: round,
    phaseEndsAt: phaseEndsAt?.toLocal(),
    startedAt: startedAt?.toLocal(),
    endsAt: endsAt?.toLocal(),
    serverTime: serverTime.toLocal(),
    myStatus: TogetherMemberStatus.fromApi(myStatus),
    mySubjectId: mySubjectId,
    members: [for (final m in members) m.toDomain()],
  );
}

/// `TogetherLimitsResponse.StudyRoomLengthResponse`.
@freezed
abstract class StudyRoomLengthDto with _$StudyRoomLengthDto {
  const factory StudyRoomLengthDto({
    String? length,
    required int focusMinutes,
    required int breakMinutes,
  }) = _StudyRoomLengthDto;

  const StudyRoomLengthDto._();

  factory StudyRoomLengthDto.fromJson(Map<String, dynamic> json) =>
      _$StudyRoomLengthDtoFromJson(json);

  StudyRoomLengthOption toDomain() => StudyRoomLengthOption(
    length: StudyRoomLength.fromApi(length),
    focusMinutes: focusMinutes,
    breakMinutes: breakMinutes,
  );
}

/// `TogetherLimitsResponse` (ADR 0045).
@freezed
abstract class TogetherLimitsDto with _$TogetherLimitsDto {
  const factory TogetherLimitsDto({
    required int challengeFriends,
    required int workoutFriends,
    required int studyRoomFriends,
    required int friendStreaks,
    required int studyRoomRounds,
    @Default(<StudyRoomLengthDto>[]) List<StudyRoomLengthDto> studyRoomLengths,
  }) = _TogetherLimitsDto;

  const TogetherLimitsDto._();

  factory TogetherLimitsDto.fromJson(Map<String, dynamic> json) =>
      _$TogetherLimitsDtoFromJson(json);

  TogetherLimits toDomain() => TogetherLimits(
    challengeFriends: challengeFriends,
    workoutFriends: workoutFriends,
    studyRoomFriends: studyRoomFriends,
    friendStreaks: friendStreaks,
    studyRoomRounds: studyRoomRounds,
    studyRoomLengths: [for (final l in studyRoomLengths) l.toDomain()],
  );
}

/// `TogetherOverviewResponse`.
@freezed
abstract class TogetherOverviewDto with _$TogetherOverviewDto {
  const factory TogetherOverviewDto({
    @Default(<FriendChallengeDto>[]) List<FriendChallengeDto> challenges,
    @Default(<FriendStreakDto>[]) List<FriendStreakDto> streaks,
    @Default(<WorkoutTogetherDto>[]) List<WorkoutTogetherDto> workouts,
    @Default(<StudyRoomDto>[]) List<StudyRoomDto> studyRooms,
  }) = _TogetherOverviewDto;

  const TogetherOverviewDto._();

  factory TogetherOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$TogetherOverviewDtoFromJson(json);

  TogetherOverview toDomain() => TogetherOverview(
    challenges: [for (final c in challenges) c.toDomain()],
    streaks: [for (final s in streaks) s.toDomain()],
    workouts: [for (final w in workouts) w.toDomain()],
    studyRooms: [for (final r in studyRooms) r.toDomain()],
  );
}
