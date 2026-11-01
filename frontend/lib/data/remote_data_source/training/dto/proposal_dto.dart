import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/routine.dart';
import '../../../../domain/models/training/routine_draft.dart';
import 'routine_dto.dart';

part 'proposal_dto.freezed.dart';
part 'proposal_dto.g.dart';

/// Ejercicio de una propuesta o de un alta de rutina (misma forma en la API).
@freezed
abstract class ProposedExerciseDto with _$ProposedExerciseDto {
  @JsonSerializable(includeIfNull: false)
  const factory ProposedExerciseDto({
    required String exerciseId,
    String? exerciseName,
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
  }) = _ProposedExerciseDto;

  const ProposedExerciseDto._();

  factory ProposedExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$ProposedExerciseDtoFromJson(json);

  factory ProposedExerciseDto.fromDomain(DraftExercise e) {
    final p = e.parameters;
    return ProposedExerciseDto(
      exerciseId: e.exerciseId,
      exerciseName: e.exerciseName,
      sets: p.sets,
      reps: p.reps,
      restSeconds: p.restSeconds,
      weightKg: p.weightKg,
      weightsKg: p.weightsKg,
      targetDurationSeconds: p.targetDurationSeconds,
      distanceMeters: p.distanceMeters,
      isometricSeconds: p.isometricSeconds,
      repsPerSet: p.repsPerSet,
      isometricSecondsPerSet: p.isometricSecondsPerSet,
    );
  }

  DraftExercise toDomain() => DraftExercise(
    exerciseId: exerciseId,
    exerciseName: exerciseName ?? '',
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
  );
}

@freezed
abstract class ProposedDayDto with _$ProposedDayDto {
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory ProposedDayDto({
    required int dayNumber,
    String? name,
    List<ProposedExerciseDto>? exercises,
  }) = _ProposedDayDto;

  const ProposedDayDto._();

  factory ProposedDayDto.fromJson(Map<String, dynamic> json) =>
      _$ProposedDayDtoFromJson(json);

  factory ProposedDayDto.fromDomain(DraftDay d) => ProposedDayDto(
    dayNumber: d.dayNumber,
    name: _blank(d.name),
    exercises: d.exercises.map(ProposedExerciseDto.fromDomain).toList(),
  );

  DraftDay toDomain() => DraftDay(
    dayNumber: dayNumber,
    name: name,
    exercises: (exercises ?? const []).map((e) => e.toDomain()).toList(),
  );
}

@freezed
abstract class ProposedWeekDto with _$ProposedWeekDto {
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory ProposedWeekDto({
    int? number,
    String? name,
    String? type,
    List<ProposedDayDto>? days,
  }) = _ProposedWeekDto;

  const ProposedWeekDto._();

  factory ProposedWeekDto.fromJson(Map<String, dynamic> json) =>
      _$ProposedWeekDtoFromJson(json);

  factory ProposedWeekDto.fromDomain(DraftWeek w, int number) =>
      ProposedWeekDto(
        number: number,
        name: _blank(w.name),
        type: w.type?.apiValue,
        days: w.days.map(ProposedDayDto.fromDomain).toList(),
      );

  DraftWeek toDomain() => DraftWeek(
    name: name,
    type: WeekType.tryFromApi(type),
    days: ((days ?? const <ProposedDayDto>[]).map((d) => d.toDomain()).toList())
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber)),
  );
}

/// Propuesta de rutina: respuesta de generar/refinar y cuerpo de refinar.
@freezed
abstract class RoutineProposalDto with _$RoutineProposalDto {
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory RoutineProposalDto({
    String? name,
    String? description,
    String? goal,
    int? durationWeeks,
    String? split,
    List<String>? adjustmentReasons,
    double? totalLoadFactor,
    bool? aiRefined,
    String? aiNotice,
    List<ProposedWeekDto>? weeks,
  }) = _RoutineProposalDto;

  const RoutineProposalDto._();

  factory RoutineProposalDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineProposalDtoFromJson(json);

  /// Cuerpo para refinar. La API exige objetivo: si falta, se usa hipertrofia.
  factory RoutineProposalDto.fromDomain(RoutineProposal p) {
    final d = p.draft;
    return RoutineProposalDto(
      name: _blank(d.name),
      description: _blank(d.description),
      goal: (d.goal ?? TrainingGoal.hypertrophy).apiValue,
      durationWeeks: d.weeks.length,
      split: p.split,
      adjustmentReasons: p.adjustmentReasons,
      totalLoadFactor: p.totalLoadFactor,
      weeks: [
        for (var i = 0; i < d.weeks.length; i++)
          ProposedWeekDto.fromDomain(d.weeks[i], i + 1),
      ],
    );
  }

  RoutineProposal toDomain() => RoutineProposal(
    draft: RoutineDraft(
      name: name ?? '',
      description: description,
      goal: TrainingGoal.tryFromApi(goal),
      weeks: (weeks ?? const []).map((w) => w.toDomain()).toList(),
    ),
    split: split,
    adjustmentReasons: adjustmentReasons ?? const [],
    totalLoadFactor: totalLoadFactor,
    aiRefined: aiRefined ?? false,
    aiNotice: _blank(aiNotice),
  );
}

/// Alta completa de una rutina (`POST /api/v1/routines`).
@freezed
abstract class CreateRoutineRequestDto with _$CreateRoutineRequestDto {
  @JsonSerializable(includeIfNull: false, explicitToJson: true)
  const factory CreateRoutineRequestDto({
    required String name,
    String? description,
    String? visibility,
    String? goal,
    String? startDate,
    required List<ProposedWeekDto> weeks,
  }) = _CreateRoutineRequestDto;

  const CreateRoutineRequestDto._();

  factory CreateRoutineRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateRoutineRequestDtoFromJson(json);

  factory CreateRoutineRequestDto.fromDomain(RoutineDraft d) =>
      CreateRoutineRequestDto(
        name: d.name.trim(),
        description: _blank(d.description),
        visibility: d.visibility.apiValue,
        goal: d.goal?.apiValue,
        startDate: d.startDate == null ? null : formatLocalDate(d.startDate!),
        weeks: [
          for (var i = 0; i < d.weeks.length; i++)
            ProposedWeekDto.fromDomain(
              d.weeks[i],
              i + 1,
            ).copyWith(number: null),
        ],
      );
}

String? _blank(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
