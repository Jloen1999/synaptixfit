import 'dart:math' as math;

import 'run.dart';

/// Cifras en directo mientras se graba, solo para enseñarlas (ADR 0037): la
/// distancia, el tiempo y el ritmo que se guardan los calcula el servidor con
/// su filtrado. Aquí se usa una versión sencilla del mismo criterio (puntos
/// con buena precisión y pasos de al menos unos metros) para que la cifra en
/// pantalla no se aleje de la que se guardará.
abstract final class RunLiveStats {
  /// Igual que el servidor: peor precisión que esto no se usa.
  static const maxAccuracyMeters = 25.0;

  /// Por debajo de este paso, es el GPS bailando estando parado.
  static const minStepMeters = 5.0;

  static const _earthRadius = 6371008.8;

  /// Distancia en metros entre dos puntos (haversine).
  static double distance(double lat1, double lon1, double lat2, double lon2) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * _earthRadius * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Metros recorridos (sin contar lo de entre pausas).
  static double meters(List<RunTrackPoint> points) {
    var total = 0.0;
    RunTrackPoint? anchor;
    for (final p in points) {
      if (p.accuracy > maxAccuracyMeters) continue;
      if (anchor == null || anchor.segment != p.segment) {
        anchor = p;
        continue;
      }
      final d = distance(
        anchor.latitude,
        anchor.longitude,
        p.latitude,
        p.longitude,
      );
      if (d >= minStepMeters) {
        total += d;
        anchor = p;
      }
    }
    return total;
  }

  /// Segundos grabando (sin pausas) hasta [now].
  static int activeSeconds(RunRecording r, DateTime now) {
    final end = r.pausedAt ?? now;
    final seconds = end.difference(r.startedAt).inSeconds - r.pausedSeconds;
    return math.max(0, seconds);
  }

  /// Ritmo en segundos por km; nulo con menos de 100 m.
  static int? paceSecondsPerKm(double meters, int seconds) =>
      meters < 100 || seconds <= 0 ? null : (seconds * 1000 / meters).round();
}

/// Por dónde va un entreno de carrera mientras se graba: paso actual, cuánto
/// le queda y cuándo se pasa al siguiente (para vibrar y avisar).
class RunGuide {
  const RunGuide({
    required this.steps,
    this.index = 0,
    this.stepStartSeconds = 0,
    this.stepStartMeters = 0,
  });

  final List<RunStep> steps;

  /// Paso actual; igual a `steps.length` cuando ya terminó.
  final int index;
  final int stepStartSeconds;
  final double stepStartMeters;

  bool get finished => index >= steps.length;

  RunStep? get current => finished ? null : steps[index];

  RunStep? get next => index + 1 < steps.length ? steps[index + 1] : null;

  /// Lo que falta del paso actual: segundos o metros según cómo se mida.
  int remaining(int seconds, double meters) {
    final step = current;
    if (step == null) return 0;
    final done = step.measure == RunMeasure.time
        ? seconds - stepStartSeconds
        : (meters - stepStartMeters).round();
    return math.max(0, step.value - done);
  }

  /// Avanza los pasos ya cumplidos con [seconds] activos y [meters]
  /// recorridos. Un paso de tiempo que se pasó de largo (p. ej. con la app
  /// dormida) empieza el siguiente justo donde terminaba, no ahora.
  RunGuide advance(int seconds, double meters) {
    var guide = this;
    while (!guide.finished) {
      final step = guide.current!;
      if (step.measure == RunMeasure.time) {
        final end = guide.stepStartSeconds + step.value;
        if (seconds < end) break;
        guide = guide._moved(end, meters);
      } else {
        final end = guide.stepStartMeters + step.value;
        if (meters < end) break;
        guide = guide._moved(seconds, end);
      }
    }
    return guide;
  }

  RunGuide _moved(int seconds, double meters) => RunGuide(
    steps: steps,
    index: index + 1,
    stepStartSeconds: seconds,
    stepStartMeters: meters,
  );
}
