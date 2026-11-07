import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/models/training/run.dart';
import 'package:synaptixfit/domain/models/training/run_live.dart';
import 'package:synaptixfit/domain/models/training/sport_activity.dart';

/// Cifras en directo y guía paso a paso de un entreno de carrera (ADR 0037).
void main() {
  const metersPerDegree = 111195.08;

  RunTrackPoint at(
    double meters,
    double second, {
    int segment = 0,
    double accuracy = 5,
  }) => RunTrackPoint(
    latitude: 40 + meters / metersPerDegree,
    longitude: -3.7,
    accuracy: accuracy,
    offsetSeconds: second,
    segment: segment,
  );

  group('RunLiveStats', () {
    test(
      'suma la distancia y no cuenta el baile del GPS ni los puntos malos',
      () {
        final points = [
          for (var s = 0; s <= 100; s++) at(3.0 * s, s.toDouble()),
          // Parado: ±1 m alrededor del mismo sitio.
          for (var s = 1; s <= 30; s++)
            at(300 + (s.isEven ? 1 : -1), 100.0 + s),
          // Un punto con 60 m de precisión no cuenta.
          at(900, 131, accuracy: 60),
        ];
        expect(RunLiveStats.meters(points), closeTo(300, 6));
      },
    );

    test('lo que se mueve en pausa (otro segmento) no suma', () {
      final points = [
        for (var s = 0; s <= 100; s++) at(3.0 * s, s.toDouble()),
        for (var s = 0; s <= 100; s++) at(800 + 3.0 * s, 200.0 + s, segment: 1),
      ];
      expect(RunLiveStats.meters(points), closeTo(600, 6));
    });

    test('el tiempo activo descuenta las pausas', () {
      final start = DateTime(2026, 11, 7, 18);
      final r = RunRecording(
        clientKey: 'k',
        kind: ActivityKind.run,
        startedAt: start,
        pausedSeconds: 120,
      );
      expect(
        RunLiveStats.activeSeconds(r, start.add(const Duration(minutes: 20))),
        18 * 60,
      );
      expect(RunLiveStats.paceSecondsPerKm(3000, 900), 300);
      expect(RunLiveStats.paceSecondsPerKm(50, 60), isNull);
    });
  });

  group('RunGuide', () {
    const warmup = RunStep(
      type: RunStepType.warmup,
      measure: RunMeasure.time,
      value: 300,
    );
    const run800 = RunStep(
      type: RunStepType.run,
      measure: RunMeasure.distance,
      value: 800,
    );
    const recover = RunStep(
      type: RunStepType.recover,
      measure: RunMeasure.time,
      value: 120,
    );
    final steps =
        const RunStepGroup(steps: [warmup]).expanded +
        const RunStepGroup(repeat: 2, steps: [run800, recover]).expanded;

    test('despliega las repeticiones: 6 × 800 m · 2 min es 12 pasos', () {
      expect(
        const RunStepGroup(repeat: 6, steps: [run800, recover]).expanded,
        hasLength(12),
      );
      expect(steps, [warmup, run800, recover, run800, recover]);
    });

    test('pasa de un paso de tiempo a uno de distancia y dice lo que queda', () {
      var guide = RunGuide(steps: steps);
      guide = guide.advance(200, 500);
      expect(guide.index, 0);
      expect(guide.remaining(200, 500), 100);

      // Calentamiento cumplido a los 300 s: la distancia del paso empieza ahí.
      guide = guide.advance(310, 900);
      expect(guide.current, run800);
      expect(guide.stepStartMeters, 900);
      expect(guide.remaining(310, 1000), 700);

      guide = guide.advance(500, 1700);
      expect(guide.current, recover);
      expect(guide.stepStartSeconds, 500);
      expect(guide.next, run800);
    });

    test('con la app dormida se pasan de golpe los pasos de tiempo', () {
      final timed = RunGuide(
        steps: const RunStepGroup(repeat: 3, steps: [warmup, recover]).expanded,
      );
      expect(timed.advance(5000, 0).finished, isTrue);
      // Un paso de distancia empieza a contar desde donde se estaba.
      final mixed = RunGuide(steps: steps).advance(5000, 10000);
      expect(mixed.current, run800);
      expect(mixed.stepStartSeconds, 300);
      expect(mixed.remaining(5000, 10300), 500);
    });
  });
}
