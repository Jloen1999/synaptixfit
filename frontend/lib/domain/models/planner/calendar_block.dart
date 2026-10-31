import '../../enums/item_time_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/planner_enums.dart';

part 'calendar_block.freezed.dart';

/// Bloque del calendario semanal. Las fechas están en hora local.
@freezed
abstract class CalendarBlock with _$CalendarBlock {
  const factory CalendarBlock({
    required String id,
    required BlockType type,
    required DateTime start,
    required DateTime end,
    String? subjectId,
    String? topics,
    String? location,
    PlannerPriority? priority,
    @Default(false) bool privateBlock,
    ClassKind? classKind,
    @Default(false) bool fixed,
    @Default(false) bool immovable,
    @Default(false) bool imported,
    @Default(false) bool hasConflict,
    @Default(false) bool completed,
    @Default(0) int xpReward,
    String? routineId,
    String? routineWeekId,
    String? routineDayId,
    String? challengeId,
    String? milestoneId,
    String? deadlineId,

    /// Pendiente, en curso, hecho o no hecho (lo decide el servidor).
    @Default(ItemTimeStatus.upcoming) ItemTimeStatus timeStatus,

    /// Deporte que no es una sesión de rutina: al marcarlo hecho se pide el
    /// esfuerzo para su carga física (lo decide el servidor).
    @Default(false) bool tracksPhysicalLoad,
  }) = _CalendarBlock;

  const CalendarBlock._();

  /// Fijo o inamovible: no se puede mover ni redimensionar.
  bool get isLocked => fixed || immovable;

  Duration get duration => end.difference(start);
}

/// Bloque creado o movido junto con los bloques con los que se solapa.
@freezed
abstract class BlockChange with _$BlockChange {
  const factory BlockChange({
    required CalendarBlock block,
    @Default(<CalendarBlock>[]) List<CalendarBlock> conflicts,

    /// Copias creadas con «Repetir cada semana».
    @Default(0) int weeklyCopies,
  }) = _BlockChange;
}

/// Bloque tras marcar/desmarcar y experiencia sumada (o restada si es negativa).
@freezed
abstract class BlockCompletion with _$BlockCompletion {
  const factory BlockCompletion({
    required CalendarBlock block,
    required int xpDelta,
  }) = _BlockCompletion;
}

/// Pareja de bloques solapados.
@freezed
abstract class BlockConflict with _$BlockConflict {
  const factory BlockConflict({
    required CalendarBlock first,
    required CalendarBlock second,
  }) = _BlockConflict;
}
