import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/training/routine.dart';
import '../../../../domain/models/training/routine_template.dart';

part 'routine_dto.freezed.dart';
part 'routine_dto.g.dart';

@freezed
abstract class PlannedExerciseDto with _$PlannedExerciseDto {
  const factory PlannedExerciseDto({
    required String id,
    required String exerciseId,
    required String exerciseName,
    String? gifUrl,
    String? previewUrl,
    String? modality,
    List<String>? measurementTypes,
    @Default(0) double met,
    @Default(true) bool exerciseActive,
    @Default(0) int order,
    required int sets,
    required int reps,
    required int restSeconds,
    double? weightKg,
    List<double>? weightsKg,
    int? targetDurationSeconds,
    int? distanceMeters,
    int? isometricSeconds,
    List<int>? repsPerSet,
    List<int>? isometricSecondsPerSet,
    int? realDurationSeconds,
    String? trackingKind,
    int? estimatedSeconds,
  }) = _PlannedExerciseDto;

  const PlannedExerciseDto._();

  factory PlannedExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$PlannedExerciseDtoFromJson(json);

  PlannedExercise toDomain() => PlannedExercise(
    id: id,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    gifUrl: blankToNull(gifUrl),
    previewUrl: blankToNull(previewUrl),
    modality: Modality.fromApi(modality),
    measurementTypes: (measurementTypes ?? const [])
        .map(MeasurementType.fromApi)
        .toList(),
    met: met,
    exerciseActive: exerciseActive,
    order: order,
    parameters: ExerciseParameters(
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      weightKg: weightKg,
      weightsKg: weightsKg,
      targetDurationSeconds: targetDurationSeconds,
      distanceMeters: distanceMeters,
      isometricSeconds: isometricSeconds,
      repsPerSet: repsPerSet,
      isometricSecondsPerSet: isometricSecondsPerSet,
    ),
    realDurationSeconds: realDurationSeconds,
    trackingKind: TrackingKind.tryFromApi(trackingKind),
    estimatedSeconds: estimatedSeconds,
  );
}

@freezed
abstract class DayDto with _$DayDto {
  const factory DayDto({
    required String id,
    required int dayNumber,
    String? name,
    String? status,
    String? closedOn,
    List<PlannedExerciseDto>? exercises,
    @Default(0) int estimatedMinutes,
  }) = _DayDto;

  const DayDto._();

  factory DayDto.fromJson(Map<String, dynamic> json) => _$DayDtoFromJson(json);

  RoutineDay toDomain() => RoutineDay(
    id: id,
    dayNumber: dayNumber,
    name: name,
    status: ProgressStatus.fromApi(status),
    closedOn: parseLocalDate(closedOn),
    exercises: _exercises(exercises),
    estimatedMinutes: estimatedMinutes,
  );
}

@freezed
abstract class WeekDto with _$WeekDto {
  const factory WeekDto({
    required String id,
    required int number,
    String? name,
    String? type,
    String? status,
    List<DayDto>? days,
    String? startsOn,
    String? endsOn,
  }) = _WeekDto;

  const WeekDto._();

  factory WeekDto.fromJson(Map<String, dynamic> json) =>
      _$WeekDtoFromJson(json);

  RoutineWeek toDomain() => RoutineWeek(
    id: id,
    number: number,
    name: name,
    type: WeekType.tryFromApi(type),
    status: ProgressStatus.fromApi(status),
    days: ((days ?? const <DayDto>[]).map((d) => d.toDomain()).toList())
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber)),
    startsOn: parseLocalDate(startsOn),
    endsOn: parseLocalDate(endsOn),
  );
}

@freezed
abstract class OriginDto with _$OriginDto {
  const factory OriginDto({
    required String routineId,
    String? ownerId,
    String? ownerName,
  }) = _OriginDto;

  const OriginDto._();

  factory OriginDto.fromJson(Map<String, dynamic> json) =>
      _$OriginDtoFromJson(json);

  RoutineOrigin toDomain() => RoutineOrigin(
    routineId: routineId,
    ownerId: ownerId,
    ownerName: ownerName,
  );
}

@freezed
abstract class RoutineDto with _$RoutineDto {
  const factory RoutineDto({
    required String id,
    required String ownerId,
    String? authorName,
    @Default(true) bool owned,
    required String name,
    String? description,
    String? visibility,
    String? status,
    String? goal,
    String? startDate,
    @Default(0) int durationWeeks,
    @Default(0) int exerciseCount,
    @Default(0) int totalDays,
    @Default(0) int completedDays,
    @Default(0) int skippedDays,
    OriginDto? origin,
    DateTime? createdAt,
    List<WeekDto>? weeks,
    @Default(1) int currentWeek,
    @Default(0) int progressPercent,
    String? nextStep,
  }) = _RoutineDto;

  const RoutineDto._();

  factory RoutineDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineDtoFromJson(json);

  Routine toDomain() => Routine(
    id: id,
    ownerId: ownerId,
    authorName: authorName,
    owned: owned,
    name: name,
    description: description,
    visibility: Visibility.fromApi(visibility),
    status: RoutineStatus.fromApi(status),
    goal: TrainingGoal.tryFromApi(goal),
    startDate: parseLocalDate(startDate),
    durationWeeks: durationWeeks,
    exerciseCount: exerciseCount,
    totalDays: totalDays,
    completedDays: completedDays,
    skippedDays: skippedDays,
    origin: origin?.toDomain(),
    createdAt: createdAt?.toLocal(),
    weeks: ((weeks ?? const <WeekDto>[]).map((w) => w.toDomain()).toList())
      ..sort((a, b) => a.number.compareTo(b.number)),
    currentWeek: currentWeek,
    progressPercent: progressPercent,
    nextStep: RoutineNextStep.tryFromApi(nextStep),
  );
}

@freezed
abstract class RoutineSummaryDto with _$RoutineSummaryDto {
  const factory RoutineSummaryDto({
    required String id,
    required String ownerId,
    String? authorName,
    required String name,
    String? description,
    String? visibility,
    String? status,
    String? goal,
    String? startDate,
    @Default(0) int durationWeeks,
    @Default(0) int exerciseCount,
    @Default(0) int totalDays,
    @Default(0) int completedDays,
    OriginDto? origin,
    DateTime? createdAt,
    @Default(0) int skippedDays,
    String? coverImageUrl,
    String? coverModality,
  }) = _RoutineSummaryDto;

  const RoutineSummaryDto._();

  factory RoutineSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineSummaryDtoFromJson(json);

  RoutineSummary toDomain() => RoutineSummary(
    id: id,
    ownerId: ownerId,
    authorName: authorName,
    name: name,
    description: description,
    visibility: Visibility.fromApi(visibility),
    status: RoutineStatus.fromApi(status),
    goal: TrainingGoal.tryFromApi(goal),
    startDate: parseLocalDate(startDate),
    durationWeeks: durationWeeks,
    exerciseCount: exerciseCount,
    totalDays: totalDays,
    completedDays: completedDays,
    origin: origin?.toDomain(),
    createdAt: createdAt?.toLocal(),
    skippedDays: skippedDays,
    coverImageUrl: blankToNull(coverImageUrl),
    coverModality: coverModality == null
        ? null
        : Modality.fromApi(coverModality),
  );
}

@freezed
abstract class PendingDayDto with _$PendingDayDto {
  const factory PendingDayDto({
    required String routineId,
    required String routineName,
    required String weekId,
    required int weekNumber,
    @Default(1) int totalWeeks,
    String? weekName,
    required String dayId,
    required int dayNumber,
    String? dayName,
    String? dayStatus,
    String? scheduledDate,
    @Default(false) bool overdue,
    @Default(1) int sessionOfWeek,
    @Default(1) int sessionsInWeek,
    String? staleSessionId,
    List<PlannedExerciseDto>? exercises,
    @Default(0) int totalDays,
    @Default(0) int completedDays,
    @Default(0) int skippedDays,
    String? coverImageUrl,
    String? coverModality,
    @Default(0) int estimatedMinutes,
  }) = _PendingDayDto;

  const PendingDayDto._();

  factory PendingDayDto.fromJson(Map<String, dynamic> json) =>
      _$PendingDayDtoFromJson(json);

  PendingDay toDomain() => PendingDay(
    routineId: routineId,
    routineName: routineName,
    weekId: weekId,
    weekNumber: weekNumber,
    totalWeeks: totalWeeks,
    weekName: weekName,
    dayId: dayId,
    dayNumber: dayNumber,
    dayName: dayName,
    dayStatus: ProgressStatus.fromApi(dayStatus),
    scheduledDate: parseLocalDate(scheduledDate),
    overdue: overdue,
    sessionOfWeek: sessionOfWeek,
    sessionsInWeek: sessionsInWeek,
    staleSessionId: staleSessionId,
    exercises: _exercises(exercises),
    totalDays: totalDays,
    completedDays: completedDays,
    skippedDays: skippedDays,
    coverImageUrl: blankToNull(coverImageUrl),
    coverModality: coverModality == null
        ? null
        : Modality.fromApi(coverModality),
    estimatedMinutes: estimatedMinutes,
  );
}

List<PlannedExercise> _exercises(List<PlannedExerciseDto>? items) =>
    ((items ?? const <PlannedExerciseDto>[]).map((e) => e.toDomain()).toList())
      ..sort((a, b) => a.order.compareTo(b.order));

/// Fecha sin hora de la API (`yyyy-MM-dd`) como medianoche local.
DateTime? parseLocalDate(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// Fecha local como `yyyy-MM-dd` para la API.
String formatLocalDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Las URLs vacías se tratan como ausentes.
String? blankToNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value;

/// Plantilla de rutina (`GET /api/v1/training/templates`).
@freezed
abstract class RoutineTemplateDto with _$RoutineTemplateDto {
  const factory RoutineTemplateDto({
    required String id,
    required String code,
    required String name,
    @Default('') String description,
    String? goal,
    @Default(false) bool atHome,
    @Default(false) bool forExams,
    @Default(30) int minutes,
    @Default(4) int weeks,
    @Default(0) int daysPerWeek,
    @Default(<int>[]) List<int> dayNumbers,
    @Default(0) int exerciseCount,
  }) = _RoutineTemplateDto;

  const RoutineTemplateDto._();

  factory RoutineTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineTemplateDtoFromJson(json);

  RoutineTemplate toDomain() => RoutineTemplate(
    id: id,
    code: code,
    name: name,
    description: description,
    goal: TrainingGoal.tryFromApi(goal),
    atHome: atHome,
    forExams: forExams,
    minutes: minutes,
    weeks: weeks,
    daysPerWeek: daysPerWeek,
    dayNumbers: dayNumbers,
    exerciseCount: exerciseCount,
  );
}
