import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/planner_enums.dart';

part 'planner_ai.freezed.dart';

/// Propuesta semanal (no guardada).
@freezed
abstract class WeekSuggestion with _$WeekSuggestion {
  const factory WeekSuggestion({
    required SuggestionSource source,
    required double studyHours,
    required int sportSessions,
    required List<SuggestedBlock> blocks,
  }) = _WeekSuggestion;
}

/// Bloque propuesto; se acepta creándolo como bloque normal.
@freezed
abstract class SuggestedBlock with _$SuggestedBlock {
  const factory SuggestedBlock({
    required BlockType type,
    required DateTime start,
    required DateTime end,
    String? subjectId,
    String? subjectName,
    String? routineId,
    String? routineName,
    String? topic,
  }) = _SuggestedBlock;
}

/// Resultado del escaneo de un horario.
@freezed
abstract class ScheduleScanResult with _$ScheduleScanResult {
  const factory ScheduleScanResult({
    required int classesFound,
    required int blocksCreated,
    required int blocksUpdated,
    @Default(<String>[]) List<String> unmatchedSubjects,

    /// El horario semanal detectado, ordenado por día y hora.
    @Default(<ScheduleClass>[]) List<ScheduleClass> classes,
  }) = _ScheduleScanResult;
}

/// Una clase del horario escaneado. [dayOfWeek] es ISO (1 = lunes); [start] y
/// [end] son horas locales «HH:mm».
@freezed
abstract class ScheduleClass with _$ScheduleClass {
  const factory ScheduleClass({
    required String subjectName,
    required int dayOfWeek,
    required String start,
    required String end,
    @Default(false) bool practice,
    String? room,
  }) = _ScheduleClass;
}

/// Archivo elegido para escanear.
@freezed
abstract class ScheduleFile with _$ScheduleFile {
  const factory ScheduleFile({
    required String name,
    required List<int> bytes,
    required String mimeType,
  }) = _ScheduleFile;
}

/// Resultado de importar un calendario ICS.
@freezed
abstract class IcsImportResult with _$IcsImportResult {
  const factory IcsImportResult({
    required IcsMatch match,
    required int totalEvents,
    required int matchingEvents,
    required int classes,
    required int exams,
    required int deliveries,
    required int created,
    required int updated,
    required bool imported,
  }) = _IcsImportResult;
}
