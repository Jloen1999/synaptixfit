import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/planner_enums.dart';

part 'weekly_planning.freezed.dart';

/// Resultado de guardar el plan de la semana.
@freezed
abstract class SavedPlan with _$SavedPlan {
  const factory SavedPlan({
    required String planId,
    required String name,
    required int blockCount,
    required int deadlineCount,
    required int xpAwarded,
  }) = _SavedPlan;
}

/// Carga académica de una semana.
@freezed
abstract class WeeklyLoad with _$WeeklyLoad {
  const factory WeeklyLoad({
    required DateTime weekStart,
    required int plannedHours,
    required int actualHours,
    required int exams,
    required int deliveries,
    required int stressLevel,
    required double sleepHours,
    String? notes,
  }) = _WeeklyLoad;
}

/// Carga recalculada y experiencia dada al sincronizar.
@freezed
abstract class WeeklyLoadSync with _$WeeklyLoadSync {
  const factory WeeklyLoadSync({
    required WeeklyLoad load,
    required int xpAwarded,
  }) = _WeeklyLoadSync;
}

/// Balance estudio/deporte de la semana.
@freezed
abstract class WeekBalance with _$WeekBalance {
  const factory WeekBalance({
    required DateTime weekStart,
    required double plannedStudyHours,
    required double actualStudyHours,
    required double plannedSportHours,
    required double actualSportHours,
    required BalanceState state,
  }) = _WeekBalance;
}

/// Elemento de la línea de tiempo (bloque o entrega).
@freezed
abstract class TimelineEntry with _$TimelineEntry {
  const factory TimelineEntry({
    required TimelineKind kind,
    required String id,
    BlockType? blockType,
    DeadlineType? deadlineType,
    String? title,
    required DateTime start,
    DateTime? end,
    String? subjectId,
    String? subjectName,
    @Default(false) bool completed,
  }) = _TimelineEntry;
}
