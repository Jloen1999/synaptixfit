import 'package:freezed_annotation/freezed_annotation.dart';

import 'session.dart';

part 'session_history.freezed.dart';

/// Qué mide un récord: el peso (con carga) o las repeticiones (peso corporal).
enum PersonalRecordKind {
  weight,
  reps;

  static PersonalRecordKind fromApi(String? value) =>
      value == 'WEIGHT' ? weight : reps;
}

/// Mejor marca en un ejercicio; la calcula el servidor.
@freezed
abstract class PersonalRecord with _$PersonalRecord {
  const factory PersonalRecord({
    required String exerciseId,
    String? exerciseName,
    required PersonalRecordKind kind,
    double? weightKg,
    required int reps,
    required String sessionId,
    required DateTime achievedAt,
  }) = _PersonalRecord;
}

/// Sesión del historial con su nombre (rutina y día) y los récords batidos.
@freezed
abstract class SessionHistoryEntry with _$SessionHistoryEntry {
  const factory SessionHistoryEntry({
    required TrainingSession session,
    String? routineName,

    /// Nulo si el día no tiene nombre: se muestra «Día N» con [dayNumber].
    String? dayName,
    int? dayNumber,
    int? weekNumber,
    @Default(<PersonalRecord>[]) List<PersonalRecord> records,
  }) = _SessionHistoryEntry;
}

/// Lo destacable de una sesión terminada: volumen movido, récords batidos y
/// la sesión anterior comparable (nulos si no la hay).
@freezed
abstract class SessionHighlights with _$SessionHighlights {
  const factory SessionHighlights({
    @Default(0) double volumeKg,
    @Default(0) int totalReps,
    @Default(0) int completedSets,
    @Default(<PersonalRecord>[]) List<PersonalRecord> records,
    double? previousVolumeKg,
    int? previousDurationMinutes,
  }) = _SessionHighlights;

  const SessionHighlights._();

  /// Diferencia de volumen con la sesión anterior comparable (sin sentido si
  /// aquella no movió peso, p. ej. solo peso corporal).
  double? get volumeDeltaKg =>
      previousVolumeKg == null || previousVolumeKg! <= 0
      ? null
      : volumeKg - previousVolumeKg!;
}
