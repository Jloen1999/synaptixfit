import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/features/bienestar/infrastructure/parametros_objetivo.dart';

void main() {
  group('ParametrosObjetivo.de', () {
    test('retorna parámetros para cada una de las 7 finalidades', () {
      const esperadas = [
        'Hipertrofia Muscular',
        'Fuerza Máxima',
        'Potencia y Explosividad',
        'Fuerza Resistencia',
        'Movilidad y Flexibilidad',
        'Estabilidad y Control Motor',
        'Acondicionamiento Metabólico',
      ];
      for (final f in esperadas) {
        final p = ParametrosObjetivo.de(f);
        expect(p.objetivo, f);
        expect(p.seriesMin > 0, isTrue);
        expect(p.seriesMax >= p.seriesMin, isTrue);
        expect(p.repsMin > 0, isTrue);
        expect(p.repsMax >= p.repsMin, isTrue);
        expect(p.descansoMin > 0, isTrue);
        expect(p.descansoMax >= p.descansoMin, isTrue);
        expect(p.rpeMin >= 1.0, isTrue);
        expect(p.rpeMax <= 10.0, isTrue);
        expect(p.ejerciciosPorDia, greaterThan(0));
        expect(p.modalidades, isNotEmpty);
        expect(p.finalidadesEjercicio, isNotEmpty);
      }
    });

    test('fallback a Hipertrofia Muscular para valor desconocido', () {
      final p = ParametrosObjetivo.de('inventado');
      expect(p.objetivo, 'Hipertrofia Muscular');
    });

    test('funciona con valores legacy', () {
      final p = ParametrosObjetivo.de('fuerza');
      expect(p.objetivo, 'Fuerza Máxima');
      expect(p.seriesMin, 3);
      expect(p.seriesMax, 5);
      expect(p.repsMin, 1);
      expect(p.repsMax, 6);
      expect(p.modalidades, ['fuerza']);
    });

    test('Fuerza Máxima tiene descanso largo', () {
      final p = ParametrosObjetivo.de('Fuerza Máxima');
      expect(p.descansoMin, 120);
      expect(p.descansoMax, 300);
    });

    test('Fuerza Resistencia tiene descanso corto', () {
      final p = ParametrosObjetivo.de('Fuerza Resistencia');
      expect(p.descansoMin, 30);
      expect(p.descansoMax, 60);
      expect(p.repsMin, 12);
      expect(p.repsMax, 25);
    });

    test('Acondicionamiento Metabólico usa modalidad aerobica', () {
      final p = ParametrosObjetivo.de('Acondicionamiento Metabólico');
      expect(p.modalidades, ['aerobica']);
      expect(p.admiteCircuito, isTrue);
    });

    test('Potencia y Explosividad usa modalidad metabolica', () {
      final p = ParametrosObjetivo.de('Potencia y Explosividad');
      expect(p.modalidades, ['metabolica']);
    });

    test('Movilidad y Flexibilidad usa modalidad movilidad', () {
      final p = ParametrosObjetivo.de('Movilidad y Flexibilidad');
      expect(p.modalidades, ['movilidad']);
    });

    test('seriesDefault está entre min y max', () {
      for (final f in [
        'Hipertrofia Muscular',
        'Fuerza Máxima',
        'Fuerza Resistencia',
      ]) {
        final p = ParametrosObjetivo.de(f);
        expect(p.seriesDefault >= p.seriesMin, isTrue);
        expect(p.seriesDefault <= p.seriesMax, isTrue);
      }
    });

    test('repsDefault está entre min y max', () {
      for (final f in [
        'Hipertrofia Muscular',
        'Fuerza Máxima',
        'Fuerza Resistencia',
      ]) {
        final p = ParametrosObjetivo.de(f);
        expect(p.repsDefault >= p.repsMin, isTrue);
        expect(p.repsDefault <= p.repsMax, isTrue);
      }
    });

    test('descansoDefault está entre min y max', () {
      for (final f in [
        'Hipertrofia Muscular',
        'Fuerza Máxima',
        'Fuerza Resistencia',
      ]) {
        final p = ParametrosObjetivo.de(f);
        expect(p.descansoDefault >= p.descansoMin, isTrue);
        expect(p.descansoDefault <= p.descansoMax, isTrue);
      }
    });
  });
}
