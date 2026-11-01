import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/planner/planner_options.dart';

part 'planner_options_dto.freezed.dart';
part 'planner_options_dto.g.dart';

/// Lo que el planner necesita de `GET /api/v1/subjects`.
@freezed
abstract class SubjectOptionDto with _$SubjectOptionDto {
  const factory SubjectOptionDto({
    required String id,
    required String name,
    String? code,
    String? icsUrl,
  }) = _SubjectOptionDto;

  const SubjectOptionDto._();

  factory SubjectOptionDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectOptionDtoFromJson(json);

  SubjectOption toDomain() =>
      SubjectOption(id: id, name: name, code: code, icsUrl: icsUrl);
}

/// Lo que el planner necesita de `GET /api/v1/routines`.
@freezed
abstract class RoutineOptionDto with _$RoutineOptionDto {
  const factory RoutineOptionDto({required String id, required String name}) =
      _RoutineOptionDto;

  const RoutineOptionDto._();

  factory RoutineOptionDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineOptionDtoFromJson(json);

  RoutineOption toDomain() => RoutineOption(id: id, name: name);
}

/// Lo que el planner necesita de `GET /api/v1/challenges` (con sus tareas).
@freezed
abstract class ChallengeOptionDto with _$ChallengeOptionDto {
  const factory ChallengeOptionDto({
    required String id,
    required String title,
    @Default(<ChallengeTaskOptionDto>[])
    List<ChallengeTaskOptionDto> milestones,
  }) = _ChallengeOptionDto;

  const ChallengeOptionDto._();

  factory ChallengeOptionDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeOptionDtoFromJson(json);

  ChallengeOption toDomain() => ChallengeOption(
    id: id,
    title: title,
    tasks: [for (final m in milestones) m.toDomain()],
  );
}

/// Tarea de un reto (`MilestoneResponse`), lo justo para asignarle un bloque.
@freezed
abstract class ChallengeTaskOptionDto with _$ChallengeTaskOptionDto {
  const factory ChallengeTaskOptionDto({
    required String id,
    required String title,
    @Default(false) bool completed,
    String? linkedEntityType,
  }) = _ChallengeTaskOptionDto;

  const ChallengeTaskOptionDto._();

  factory ChallengeTaskOptionDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeTaskOptionDtoFromJson(json);

  ChallengeTaskOption toDomain() => ChallengeTaskOption(
    id: id,
    title: title,
    completed: completed,
    hasDeadline: linkedEntityType != null,
  );
}
