import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/planner/focus.dart';
import 'planner_json.dart';

part 'focus_dto.freezed.dart';
part 'focus_dto.g.dart';

/// Respuesta de `POST /planner/focus-sessions`; solo interesa la XP concedida
/// y su estado (premiada, tope diario o sin derecho).
@freezed
abstract class FocusSessionResponseDto with _$FocusSessionResponseDto {
  const factory FocusSessionResponseDto({
    String? id,
    String? blockId,
    String? subjectId,
    @Default(0) int xpAwarded,
    String? xpStatus,
  }) = _FocusSessionResponseDto;

  const FocusSessionResponseDto._();

  factory FocusSessionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FocusSessionResponseDtoFromJson(json);

  FocusSessionResult toDomain() => FocusSessionResult(
    xpAwarded: xpAwarded,
    xpStatus: FocusXpStatus.fromApi(xpStatus),
  );
}

@freezed
abstract class FocusTotalsDto with _$FocusTotalsDto {
  const factory FocusTotalsDto({
    @Default(0) int focusMinutes,
    @Default(0) int breakMinutes,
    @Default(0) int focusCycles,
    @Default(0) int sessions,
  }) = _FocusTotalsDto;

  const FocusTotalsDto._();

  factory FocusTotalsDto.fromJson(Map<String, dynamic> json) =>
      _$FocusTotalsDtoFromJson(json);

  FocusTotals toDomain() => FocusTotals(
    focusMinutes: focusMinutes,
    breakMinutes: breakMinutes,
    focusCycles: focusCycles,
    sessions: sessions,
  );
}

@freezed
abstract class FocusDayDto with _$FocusDayDto {
  const factory FocusDayDto({
    required String date,
    required FocusTotalsDto totals,
  }) = _FocusDayDto;

  const FocusDayDto._();

  factory FocusDayDto.fromJson(Map<String, dynamic> json) =>
      _$FocusDayDtoFromJson(json);

  FocusDay toDomain() =>
      FocusDay(date: PlannerJson.date(date), totals: totals.toDomain());
}

@freezed
abstract class FocusStatsDto with _$FocusStatsDto {
  const factory FocusStatsDto({
    required FocusTotalsDto today,
    required FocusTotalsDto week,
    @Default(<FocusDayDto>[]) List<FocusDayDto> days,
  }) = _FocusStatsDto;

  const FocusStatsDto._();

  factory FocusStatsDto.fromJson(Map<String, dynamic> json) =>
      _$FocusStatsDtoFromJson(json);

  FocusStats toDomain() => FocusStats(
    today: today.toDomain(),
    week: week.toDomain(),
    days: days.map((d) => d.toDomain()).toList(),
  );
}

/// Respuesta de `GET /planner/focus-sessions/plan`.
@freezed
abstract class FocusPlanDto with _$FocusPlanDto {
  const factory FocusPlanDto({
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int cyclesBeforeLongBreak,
    @Default(false) bool limitedByFatigue,
    required int minFocusMinutes,
    required int maxFocusMinutes,
  }) = _FocusPlanDto;

  const FocusPlanDto._();

  factory FocusPlanDto.fromJson(Map<String, dynamic> json) =>
      _$FocusPlanDtoFromJson(json);

  FocusPlan toDomain() => FocusPlan(
    focusMinutes: focusMinutes,
    shortBreakMinutes: shortBreakMinutes,
    longBreakMinutes: longBreakMinutes,
    cyclesBeforeLongBreak: cyclesBeforeLongBreak,
    limitedByFatigue: limitedByFatigue,
    minFocusMinutes: minFocusMinutes,
    maxFocusMinutes: maxFocusMinutes,
  );
}
