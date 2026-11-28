import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/models/training/wod.dart';
import 'package:synaptixfit/domain/models/training/wod_timer.dart';

/// Fases del cronómetro de un WOD según su formato (ADR 0069).
void main() {
  group('por tiempo', () {
    test('cuenta hacia delante y termina al llegar al límite', () {
      const timer = WodTimer(format: WodFormat.forTime, timeCapSeconds: 600);
      final start = timer.at(0);
      expect(start.phase, WodPhase.work);
      expect(start.clockSeconds, 0);
      expect(start.countsDown, isFalse);
      expect(timer.at(125).clockSeconds, 125);
      expect(timer.at(599).done, isFalse);

      final end = timer.at(600);
      expect(end.done, isTrue);
      expect(end.clockSeconds, 600);
      // Un tic que llega tarde no pasa del límite.
      expect(timer.at(900).elapsedSeconds, 600);
    });

    test('sin límite no termina sola', () {
      const timer = WodTimer(format: WodFormat.forTime);
      expect(timer.totalSeconds, isNull);
      expect(timer.at(7200).done, isFalse);
      expect(timer.at(7200).clockSeconds, 7200);
    });
  });

  test('AMRAP cuenta atrás desde el límite', () {
    const timer = WodTimer(format: WodFormat.amrap, timeCapSeconds: 720);
    expect(timer.at(0).clockSeconds, 720);
    expect(timer.at(0).countsDown, isTrue);
    expect(timer.at(700).clockSeconds, 20);
    expect(timer.at(700).round, 1);
    expect(timer.at(720).done, isTrue);
    expect(timer.at(720).clockSeconds, 0);
  });

  test('EMOM: una ronda por minuto, con la cuenta atrás de cada uno', () {
    const timer = WodTimer(format: WodFormat.emom, timeCapSeconds: 600);
    expect(timer.totalRounds, 10);
    expect(timer.at(0).round, 1);
    expect(timer.at(0).clockSeconds, 60);
    expect(timer.at(59).round, 1);
    expect(timer.at(59).clockSeconds, 1);
    expect(timer.at(60).round, 2);
    expect(timer.at(60).clockSeconds, 60);
    expect(timer.at(599).round, 10);
    expect(timer.at(600).done, isTrue);
    expect(timer.at(600).round, 10);
  });

  test('Tabata: 8 rondas de 20 s de trabajo y 10 s de descanso', () {
    const timer = WodTimer(format: WodFormat.tabata);
    expect(timer.totalSeconds, 240);
    expect(timer.totalRounds, 8);

    expect(timer.at(0).phase, WodPhase.work);
    expect(timer.at(0).clockSeconds, 20);
    expect(timer.at(19).phase, WodPhase.work);
    expect(timer.at(19).clockSeconds, 1);
    expect(timer.at(20).phase, WodPhase.rest);
    expect(timer.at(20).clockSeconds, 10);
    expect(timer.at(29).clockSeconds, 1);
    expect(timer.at(30).phase, WodPhase.work);
    expect(timer.at(30).round, 2);
    expect(timer.at(239).phase, WodPhase.rest);
    expect(timer.at(239).round, 8);
    expect(timer.at(240).done, isTrue);
  });

  test('lo que se anuncia solo cambia con la fase o la ronda', () {
    const timer = WodTimer(format: WodFormat.tabata);
    final keys = {for (var s = 0; s <= 240; s++) timer.at(s).announceKey};
    // 8 de trabajo, 8 de descanso y el final: nunca un anuncio por segundo.
    expect(keys, hasLength(17));
    expect(timer.at(3).announceKey, timer.at(17).announceKey);
    expect(timer.at(19).announceKey, isNot(timer.at(20).announceKey));

    const forTime = WodTimer(format: WodFormat.forTime, timeCapSeconds: 300);
    expect(
      {for (var s = 0; s <= 300; s++) forTime.at(s).announceKey},
      {(WodPhase.work, 1), (WodPhase.done, 1)},
    );
  });

  test('el formato dice qué se apunta', () {
    expect(WodFormat.forTime.scoreType(capped: false), WodScoreType.time);
    expect(WodFormat.forTime.scoreType(capped: true), WodScoreType.reps);
    expect(WodFormat.amrap.scoreType(capped: false), WodScoreType.roundsReps);
    expect(WodFormat.emom.scoreType(capped: false), WodScoreType.reps);
    expect(WodFormat.tabata.scoreType(capped: false), WodScoreType.reps);
  });
}
