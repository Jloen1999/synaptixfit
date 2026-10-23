import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/training/routine.dart';

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
    int? realDurationSeconds,
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
    ),
    realDurationSeconds: realDurationSeconds,
  );
}

@freezed
abstract class DayDto with _$DayDto {
  const factory DayDto({
    required String id,
    required int dayNumber,
    String? name,
    String? status,
    List<PlannedExerciseDto>? exercises,
  }) = _DayDto;

  const DayDto._();

  factory DayDto.fromJson(Map<String, dynamic> json) => _$DayDtoFromJson(json);

  RoutineDay toDomain() => RoutineDay(
    id: id,
    dayNumber: dayNumber,
    name: name,
    status: ProgressStatus.fromApi(status),
    exercises: _exercises(exercises),
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
    OriginDto? origin,
    DateTime? createdAt,
    List<WeekDto>? weeks,
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
    origin: origin?.toDomain(),
    createdAt: createdAt?.toLocal(),
    weeks: ((weeks ?? const <WeekDto>[]).map((w) => w.toDomain()).toList())
      ..sort((a, b) => a.number.compareTo(b.number)),
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
  );
}

@freezed
abstract class PendingDayDto with _$PendingDayDto {
  const factory PendingDayDto({
    required String routineId,
    required String routineName,
    required String weekId,
    required int weekNumber,
    String? weekName,
    required String dayId,
    required int dayNumber,
    String? dayName,
    String? dayStatus,
    List<PlannedExerciseDto>? exercises,
  }) = _PendingDayDto;

  const PendingDayDto._();

  factory PendingDayDto.fromJson(Map<String, dynamic> json) =>
      _$PendingDayDtoFromJson(json);

  PendingDay toDomain() => PendingDay(
    routineId: routineId,
    routineName: routineName,
    weekId: weekId,
    weekNumber: weekNumber,
    weekName: weekName,
    dayId: dayId,
    dayNumber: dayNumber,
    dayName: dayName,
    dayStatus: ProgressStatus.fromApi(dayStatus),
    exercises: _exercises(exercises),
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
