import 'package:freezed_annotation/freezed_annotation.dart';

import 'sport_activity.dart';

part 'run.freezed.dart';

/// Un punto de GPS tal como lo da el móvil (ADR 0037). Lo que se guarda y se
/// sube es la ruta cruda: las cifras de verdad las calcula el servidor.
@freezed
abstract class RunFix with _$RunFix {
  const factory RunFix({
    required double latitude,
    required double longitude,
    double? altitude,

    /// Precisión horizontal en metros (cuanto menor, mejor).
    required double accuracy,
    required DateTime time,
  }) = _RunFix;
}

/// Punto de la ruta grabada: segundos desde que empezó y segmento (cambia con
/// cada pausa, así lo que se mueve en pausa no cuenta).
@freezed
abstract class RunTrackPoint with _$RunTrackPoint {
  const factory RunTrackPoint({
    required double latitude,
    required double longitude,
    double? altitude,
    required double accuracy,
    required double offsetSeconds,
    required int segment,
  }) = _RunTrackPoint;
}

/// Un tramo del análisis por kilómetro.
@freezed
abstract class RunSplit with _$RunSplit {
  const factory RunSplit({
    required int number,
    required int distanceMeters,
    required int seconds,
    required int paceSecondsPerKm,
  }) = _RunSplit;
}

/// Detalle de una carrera (todas las cifras las da el servidor). La ruta es
/// privada: solo la ve su dueño y nunca se comparte.
@freezed
abstract class RunDetail with _$RunDetail {
  const factory RunDetail({
    required String blockId,
    required ActivityKind kind,
    String? title,
    required DateTime startedAt,
    required DateTime endedAt,
    required int distanceMeters,
    required int movingSeconds,
    int? paceSecondsPerKm,
    required int elevationGainMeters,
    int? kcal,
    required int effort,
    @Default(<RunSplit>[]) List<RunSplit> splits,

    /// Puntos (lat, lon) para dibujar la ruta.
    @Default(<(double, double)>[]) List<(double, double)> route,
    String? workoutId,
  }) = _RunDetail;
}

/// La carrera guardada y la XP que sumó.
@freezed
abstract class RunSaved with _$RunSaved {
  const factory RunSaved({required RunDetail run, required int xpDelta}) =
      _RunSaved;
}

/// «Esta semana» en Correr (lunes a domingo).
@freezed
abstract class RunWeek with _$RunWeek {
  const factory RunWeek({
    required DateTime weekStart,
    required int distanceMeters,
    required int movingSeconds,
    required int elevationGainMeters,
    required int outings,

    /// Metros de cada día, de lunes a domingo.
    @Default(<int>[]) List<int> dailyDistanceMeters,
  }) = _RunWeek;
}

/// Qué se hace en un paso de un entreno de carrera.
enum RunStepType {
  warmup('WARMUP'),
  run('RUN'),
  recover('RECOVER'),
  cooldown('COOLDOWN');

  const RunStepType(this.api);

  final String api;

  static RunStepType fromApi(String? v) =>
      values.where((t) => t.api == v).firstOrNull ?? run;
}

/// Cómo se mide un paso: por tiempo (segundos) o por distancia (metros).
enum RunMeasure {
  time('TIME'),
  distance('DISTANCE');

  const RunMeasure(this.api);

  final String api;

  static RunMeasure fromApi(String? v) =>
      values.where((m) => m.api == v).firstOrNull ?? time;
}

/// Un paso: «Correr 800 m», «Recuperar 2 min».
@freezed
abstract class RunStep with _$RunStep {
  const factory RunStep({
    required RunStepType type,
    required RunMeasure measure,
    required int value,
  }) = _RunStep;
}

/// Pasos que se repiten [repeat] veces seguidas.
@freezed
abstract class RunStepGroup with _$RunStepGroup {
  const factory RunStepGroup({
    @Default(1) int repeat,
    required List<RunStep> steps,
  }) = _RunStepGroup;

  const RunStepGroup._();

  /// Los pasos ya desplegados con sus repeticiones.
  List<RunStep> get expanded => [for (var i = 0; i < repeat; i++) ...steps];
}

/// Entreno de carrera por pasos (propio o plantilla).
@freezed
abstract class RunWorkout with _$RunWorkout {
  const factory RunWorkout({
    String? id,
    required String name,
    String? templateCode,
    required List<RunStepGroup> groups,

    /// Duración prevista en segundos (la da el servidor).
    @Default(0) int estimatedSeconds,
  }) = _RunWorkout;

  const RunWorkout._();

  List<RunStep> get steps => [for (final g in groups) ...g.expanded];
}

/// Evento del calendario con un entreno de carrera aún por hacer.
@freezed
abstract class PlannedRun with _$PlannedRun {
  const factory PlannedRun({
    required String blockId,
    required String workoutId,
    required String workoutName,
    required DateTime start,
    required DateTime end,
  }) = _PlannedRun;
}

/// Carrera en curso o terminada pendiente de subir, guardada en el teléfono:
/// así no se pierde nada si se cierra la app o se reinicia el móvil.
@freezed
abstract class RunRecording with _$RunRecording {
  const factory RunRecording({
    /// Clave idempotente: la cola puede reintentar sin duplicar.
    required String clientKey,
    required ActivityKind kind,
    required DateTime startedAt,
    @Default(<RunTrackPoint>[]) List<RunTrackPoint> points,
    @Default(0) int segment,

    /// Desde cuándo está en pausa (nulo si graba).
    DateTime? pausedAt,

    /// Segundos en pausa ya acumulados.
    @Default(0) int pausedSeconds,
    String? workoutId,
    String? plannedBlockId,

    /// «¿Cuánto te ha costado?» (1-10): con él, está terminada y en la cola.
    int? effort,
  }) = _RunRecording;

  const RunRecording._();

  bool get finished => effort != null;
}
