import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/wellbeing.dart';
import 'routine_dto.dart';

part 'wellbeing_dto.freezed.dart';
part 'wellbeing_dto.g.dart';

@freezed
abstract class CheckInDto with _$CheckInDto {
  const factory CheckInDto({
    required String id,
    required String date,
    required int sleepQuality,
    required int stress,
    required int energy,
    required int soreness,
    List<String>? painZones,
    @Default(true) bool readyToTrain,
    String? notes,
    @Default(0) int fatigueScore,
    @Default(false) bool requiresAdaptation,
    DateTime? createdAt,
  }) = _CheckInDto;

  const CheckInDto._();

  factory CheckInDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInDtoFromJson(json);

  CheckIn toDomain() => CheckIn(
    id: id,
    date: parseLocalDate(date) ?? DateTime.now(),
    sleepQuality: sleepQuality,
    stress: stress,
    energy: energy,
    soreness: soreness,
    painZones: painZones ?? const [],
    readyToTrain: readyToTrain,
    notes: notes,
    fatigueScore: fatigueScore,
    requiresAdaptation: requiresAdaptation,
    createdAt: createdAt?.toLocal(),
  );
}

@freezed
abstract class SubmitCheckInResponseDto with _$SubmitCheckInResponseDto {
  const factory SubmitCheckInResponseDto({
    required CheckInDto checkIn,
    @Default(false) bool firstOfDay,
    @Default(0) int xpAwarded,
  }) = _SubmitCheckInResponseDto;

  const SubmitCheckInResponseDto._();

  factory SubmitCheckInResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SubmitCheckInResponseDtoFromJson(json);

  CheckInResult toDomain() => CheckInResult(
    checkIn: checkIn.toDomain(),
    firstOfDay: firstOfDay,
    xpAwarded: xpAwarded,
  );
}

@freezed
abstract class CheckInRequestDto with _$CheckInRequestDto {
  @JsonSerializable(includeIfNull: false)
  const factory CheckInRequestDto({
    required int sleepQuality,
    required int stress,
    required int energy,
    required int soreness,
    required List<String> painZones,
    required bool readyToTrain,
    String? notes,
  }) = _CheckInRequestDto;

  factory CheckInRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInRequestDtoFromJson(json);

  factory CheckInRequestDto.fromDomain(CheckInInput i) => CheckInRequestDto(
    sleepQuality: i.sleepQuality,
    stress: i.stress,
    energy: i.energy,
    soreness: i.soreness,
    painZones: i.painZones,
    readyToTrain: i.readyToTrain,
    notes: i.notes?.trim().isEmpty ?? true ? null : i.notes!.trim(),
  );
}

@freezed
abstract class WeeklyPlanDto with _$WeeklyPlanDto {
  const factory WeeklyPlanDto({
    required String id,
    required String weekStart,
    required int plannedSessions,
    String? intensity,
    required int minutesPerSession,
    String? status,
    String? notes,
    @Default(0) int completedSessions,
    @Default(0) double compliance,
  }) = _WeeklyPlanDto;

  const WeeklyPlanDto._();

  factory WeeklyPlanDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPlanDtoFromJson(json);

  WeeklyPlan toDomain() => WeeklyPlan(
    id: id,
    weekStart: parseLocalDate(weekStart) ?? DateTime.now(),
    plannedSessions: plannedSessions,
    intensity: PlanIntensity.fromApi(intensity),
    minutesPerSession: minutesPerSession,
    status: PlanStatus.fromApi(status),
    notes: notes,
    completedSessions: completedSessions,
    compliance: compliance.clamp(0, 1).toDouble(),
  );
}

@freezed
abstract class WeeklyPlanRequestDto with _$WeeklyPlanRequestDto {
  @JsonSerializable(includeIfNull: false)
  const factory WeeklyPlanRequestDto({
    required int plannedSessions,
    required String intensity,
    required int minutesPerSession,
    required String status,
    String? notes,
  }) = _WeeklyPlanRequestDto;

  factory WeeklyPlanRequestDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPlanRequestDtoFromJson(json);

  factory WeeklyPlanRequestDto.fromDomain(WeeklyPlanInput i) =>
      WeeklyPlanRequestDto(
        plannedSessions: i.plannedSessions,
        intensity: i.intensity.apiValue,
        minutesPerSession: i.minutesPerSession,
        status: i.status.apiValue,
        notes: i.notes?.trim().isEmpty ?? true ? null : i.notes!.trim(),
      );
}

/// Solo el peso del perfil de bienestar (`GET /api/v1/profile/wellness`).
@freezed
abstract class BodyWeightDto with _$BodyWeightDto {
  const factory BodyWeightDto({double? weightKg}) = _BodyWeightDto;

  factory BodyWeightDto.fromJson(Map<String, dynamic> json) =>
      _$BodyWeightDtoFromJson(json);
}
