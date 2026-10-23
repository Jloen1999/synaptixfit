import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/session.dart';
import 'recommendation_dto.dart';

part 'session_dto.freezed.dart';
part 'session_dto.g.dart';

@freezed
abstract class SessionSetDto with _$SessionSetDto {
  const factory SessionSetDto({
    required String id,
    String? plannedExerciseId,
    required int setNumber,
    int? repsDone,
    double? weightKg,
    @Default(true) bool completed,
    @Default(0) int failedReps,
  }) = _SessionSetDto;

  const SessionSetDto._();

  factory SessionSetDto.fromJson(Map<String, dynamic> json) =>
      _$SessionSetDtoFromJson(json);

  SessionSet toDomain() => SessionSet(
    id: id,
    plannedExerciseId: plannedExerciseId,
    setNumber: setNumber,
    repsDone: repsDone,
    weightKg: weightKg,
    completed: completed,
    failedReps: failedReps,
  );
}

@freezed
abstract class SessionDto with _$SessionDto {
  const factory SessionDto({
    required String id,
    String? routineId,
    String? dayId,
    String? type,
    String? status,
    required DateTime startedAt,
    DateTime? completedAt,
    @Default(0) int durationMinutes,
    int? rpe,
    double? calories,
    @Default(0) int xpAwarded,
    List<SessionSetDto>? sets,
  }) = _SessionDto;

  const SessionDto._();

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  TrainingSession toDomain() => TrainingSession(
    id: id,
    routineId: routineId,
    dayId: dayId,
    type: SessionType.fromApi(type),
    status: SessionStatus.fromApi(status),
    startedAt: startedAt.toLocal(),
    completedAt: completedAt?.toLocal(),
    durationMinutes: durationMinutes,
    rpe: rpe,
    calories: calories,
    xpAwarded: xpAwarded,
    sets: (sets ?? const []).map((s) => s.toDomain()).toList(),
  );
}

/// Serie para registrar (`RecordSetRequest`).
@freezed
abstract class RecordSetRequestDto with _$RecordSetRequestDto {
  @JsonSerializable(includeIfNull: false)
  const factory RecordSetRequestDto({
    String? plannedExerciseId,
    required int setNumber,
    int? repsDone,
    double? weightKg,
    required bool completed,
    required int failedReps,
  }) = _RecordSetRequestDto;

  factory RecordSetRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RecordSetRequestDtoFromJson(json);

  factory RecordSetRequestDto.fromDomain(SetRecord r) => RecordSetRequestDto(
    plannedExerciseId: r.plannedExerciseId,
    setNumber: r.setNumber,
    repsDone: r.repsDone,
    weightKg: r.weightKg,
    completed: r.completed,
    failedReps: r.failedReps,
  );
}

@freezed
abstract class ExperienceDto with _$ExperienceDto {
  const factory ExperienceDto({
    required int level,
    required int levelXp,
    @Default(0) int levelUps,
    @Default(0) int xpDelta,
  }) = _ExperienceDto;

  const ExperienceDto._();

  factory ExperienceDto.fromJson(Map<String, dynamic> json) =>
      _$ExperienceDtoFromJson(json);

  ExperienceChange toDomain() => ExperienceChange(
    level: level,
    levelXp: levelXp,
    levelUps: levelUps,
    xpDelta: xpDelta,
  );
}

@freezed
abstract class FinishSessionResponseDto with _$FinishSessionResponseDto {
  const factory FinishSessionResponseDto({
    required SessionDto session,
    required ExperienceDto experience,
    List<RecommendationDto>? recommendations,
  }) = _FinishSessionResponseDto;

  const FinishSessionResponseDto._();

  factory FinishSessionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FinishSessionResponseDtoFromJson(json);

  FinishSessionResult toDomain() => FinishSessionResult(
    session: session.toDomain(),
    experience: experience.toDomain(),
    recommendations: (recommendations ?? const [])
        .map((r) => r.toDomain())
        .toList(),
  );
}

@freezed
abstract class UnmarkSessionResponseDto with _$UnmarkSessionResponseDto {
  const factory UnmarkSessionResponseDto({
    required SessionDto session,
    required ExperienceDto experience,
  }) = _UnmarkSessionResponseDto;

  const UnmarkSessionResponseDto._();

  factory UnmarkSessionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UnmarkSessionResponseDtoFromJson(json);

  UnmarkSessionResult toDomain() => UnmarkSessionResult(
    session: session.toDomain(),
    experience: experience.toDomain(),
  );
}
