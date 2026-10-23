import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/planner_enums.dart';

part 'block_draft.freezed.dart';

/// Datos editables de un bloque (alta o edición). El horario solo se usa en el
/// alta; en la edición se cambia reprogramando el bloque.
@freezed
abstract class BlockDraft with _$BlockDraft {
  const factory BlockDraft({
    required BlockType type,
    required DateTime start,
    required DateTime end,
    String? subjectId,
    String? topics,
    String? location,
    PlannerPriority? priority,
    @Default(false) bool privateBlock,
    ClassKind? classKind,
    String? routineId,
    String? challengeId,
    String? deadlineId,

    /// Solo al crear un examen/entrega sin [deadlineId].
    String? deadlineTitle,
    PlannerPriority? deadlineDifficulty,

    /// Solo al crear: semanas siguientes en las que se repite a la misma hora.
    @Default(0) int repeatWeeks,
  }) = _BlockDraft;
}

/// Petición para distribuir una rutina completa en el calendario.
@freezed
abstract class RoutineDistribution with _$RoutineDistribution {
  const factory RoutineDistribution({
    required String routineId,

    /// 1 = lunes … 7 = domingo.
    required Set<int> weekdays,
    required DateTime startDate,

    /// Minutos desde medianoche.
    required int preferredStartMinutes,
    required int durationMinutes,
  }) = _RoutineDistribution;
}
