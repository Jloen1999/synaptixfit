import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/features/bienestar/infrastructure/progresion_calculator.dart';
import 'package:synaptixfit/features/bienestar/infrastructure/parametros_objetivo.dart';

void main() {
  group('calcular1RM', () {
    test('retorna 0 si peso <= 0', () {
      expect(ProgresionCalculator.calcular1RM(0, 10), 0);
      expect(ProgresionCalculator.calcular1RM(-10, 10), 0);
    });

    test('retorna 0 si reps <= 0', () {
      expect(ProgresionCalculator.calcular1RM(100, 0), 0);
      expect(ProgresionCalculator.calcular1RM(100, -5), 0);
    });

    test('retorna el mismo peso si reps == 1', () {
      expect(ProgresionCalculator.calcular1RM(100, 1), 100);
      expect(ProgresionCalculator.calcular1RM(50, 1), 50);
    });

    test('calcula 1RM mayor que el peso para reps > 1', () {
      final rm = ProgresionCalculator.calcular1RM(80, 5);
      expect(rm, greaterThan(80));
    });

    test('valores conocidos — Epley aproximado', () {
      final rm = ProgresionCalculator.calcular1RM(100, 10);
      expect(rm, greaterThan(100));
      expect(rm, lessThan(200));
    });
  });

  group('generarPesosPorSerie', () {
    test('1 serie: solo peso objetivo', () {
      final pesos = ProgresionCalculator.generarPesosPorSerie(
        pesoObjetivo: 100,
        totalSeries: 1,
      );
      expect(pesos, [100]);
    });

    test('2 series: ambas al 100%', () {
      final pesos = ProgresionCalculator.generarPesosPorSerie(
        pesoObjetivo: 100,
        totalSeries: 2,
      );
      expect(pesos, [100, 100]);
    });

    test('3 series: rampa 50-75-100', () {
      final pesos = ProgresionCalculator.generarPesosPorSerie(
        pesoObjetivo: 100,
        totalSeries: 3,
      );
      expect(pesos[0], closeTo(50, 1));
      expect(pesos[1], closeTo(75, 1));
      expect(pesos[2], closeTo(100, 1));
    });

    test('4 series: rampa 50-75-100-100', () {
      final pesos = ProgresionCalculator.generarPesosPorSerie(
        pesoObjetivo: 100,
        totalSeries: 4,
      );
      expect(pesos[0], closeTo(50, 1));
      expect(pesos[1], closeTo(75, 1));
      expect(pesos[2], closeTo(100, 1));
      expect(pesos[3], closeTo(100, 1));
    });

    test('5 series: los extras son 100%', () {
      final pesos = ProgresionCalculator.generarPesosPorSerie(
        pesoObjetivo: 80,
        totalSeries: 5,
      );
      expect(pesos[0], closeTo(40, 1));
      expect(pesos[1], closeTo(60, 1));
      expect(pesos[2], closeTo(80, 1));
      expect(pesos[3], closeTo(80, 1));
      expect(pesos[4], closeTo(80, 1));
    });
  });

  group('calcularProgresion', () {
    final params = ParametrosObjetivo.de('Hipertrofia Muscular');

    test('con fallos: reduce carga proporcionalmente', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 4,
        repeticionesActuales: 10,
        descansoActual: 90,
        pesoActual: 50,
        tipoMedicion: ['repeticiones', 'peso'],
        rpeUltimaSesion: 7,
        seriesRealizadas: [
          const SerieRealizadaDto(
              numeroSerie: 1, failedReps: 2, completada: true),
        ],
        params: params,
      );
      expect(prog.nuevoPeso, lessThan(50));
      expect(prog.nuevasSeries, lessThan(4));
      expect(prog.log, isNotNull);
    });

    test('RPE muy alto: reduce carga 15%', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 10,
        descansoActual: 90,
        pesoActual: 100,
        tipoMedicion: ['repeticiones', 'peso'],
        rpeUltimaSesion: 9.5,
        params: params,
      );
      expect(prog.nuevoPeso, closeTo(85, 1));
      expect(prog.log, contains('-15%'));
    });

    test('RPE muy bajo: sube carga 10%', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 10,
        descansoActual: 90,
        pesoActual: 100,
        tipoMedicion: ['repeticiones', 'peso'],
        rpeUltimaSesion: 4.5,
        params: params,
      );
      expect(prog.nuevoPeso, closeTo(110, 1));
    });

    test('RPE moderado-bajo: +1 rep', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 8,
        descansoActual: 90,
        pesoActual: 80,
        tipoMedicion: ['repeticiones', 'peso'],
        rpeUltimaSesion: 6.5,
        params: params,
      );
      expect(prog.nuevasRepeticiones, 9);
      expect(prog.nuevoPeso, 80);
    });

    test('RPE moderado-bajo en repsMax: sube peso, resetea reps', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 15,
        descansoActual: 90,
        pesoActual: 60,
        tipoMedicion: ['repeticiones', 'peso'],
        rpeUltimaSesion: 6.5,
        params: params,
      );
      expect(prog.nuevoPeso, greaterThan(60));
      expect(prog.nuevasRepeticiones, 6);
      expect(prog.log, contains('reps reset'));
    });

    test('genera pesosPorSerie cuando hay peso', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 4,
        repeticionesActuales: 10,
        descansoActual: 90,
        pesoActual: 80,
        tipoMedicion: ['repeticiones', 'peso'],
        rpeUltimaSesion: 7,
        params: params,
      );
      expect(prog.pesosPorSerie, isNotNull);
      expect(prog.pesosPorSerie!.length, 4);
    });

    test('sin tipoMedicion peso: no genera pesosPorSerie', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 600,
        descansoActual: 60,
        pesoActual: null,
        tipoMedicion: ['tiempo'],
        rpeUltimaSesion: 6,
        duracionActual: 600,
      );
      expect(prog.pesosPorSerie, isNull);
      expect(prog.nuevaDuracionSegundos, 660);
    });

    test('sin params: no clampa, usa valores tal cual', () {
      final prog = ProgresionCalculator().calcularProgresion(
        ejercicioId: 'test-id',
        seriesActuales: 10,
        repeticionesActuales: 100,
        descansoActual: 600,
        pesoActual: 100,
        tipoMedicion: ['repeticiones', 'peso'],
        rpeUltimaSesion: 9.5,
      );
      expect(prog.nuevoPeso, closeTo(85, 1));
      expect(prog.nuevasSeries, 10);
    });
  });

  group('degradarPorInactividad', () {
    test('<= 14 días: sin cambios', () {
      final prog = ProgresionCalculator().degradarPorInactividad(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 10,
        descansoActual: 90,
        pesoActual: 80,
        tipoMedicion: ['repeticiones', 'peso'],
        diasInactivo: 14,
      );
      expect(prog.nuevoPeso, 80);
      expect(prog.nuevasSeries, 3);
      expect(prog.log, isNull);
    });

    test('15-21 días: -20% carga', () {
      final prog = ProgresionCalculator().degradarPorInactividad(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 10,
        descansoActual: 90,
        pesoActual: 100,
        tipoMedicion: ['repeticiones', 'peso'],
        diasInactivo: 18,
      );
      expect(prog.nuevoPeso, closeTo(80, 1));
      expect(prog.nuevoDescanso, 120);
    });

    test('> 21 días: -30% carga', () {
      final prog = ProgresionCalculator().degradarPorInactividad(
        ejercicioId: 'test-id',
        seriesActuales: 3,
        repeticionesActuales: 10,
        descansoActual: 90,
        pesoActual: 100,
        tipoMedicion: ['repeticiones', 'peso'],
        diasInactivo: 30,
      );
      expect(prog.nuevoPeso, closeTo(70, 1));
    });
  });

  group('generarInicial', () {
    test('sin peso: no genera pesosPorSerie', () {
      final prog = ProgresionCalculator().generarInicial(
        ejercicioId: 'test-id',
        series: 3,
        repeticiones: 10,
        descanso: 90,
        tipoMedicion: ['repeticiones'],
      );
      expect(prog.pesosPorSerie, isNull);
    });

    test('con peso: genera rampa', () {
      final prog = ProgresionCalculator().generarInicial(
        ejercicioId: 'test-id',
        series: 3,
        repeticiones: 10,
        descanso: 90,
        pesoKg: 80,
        tipoMedicion: ['repeticiones', 'peso'],
      );
      expect(prog.pesosPorSerie, isNotNull);
      expect(prog.pesosPorSerie!.length, 3);
    });

    test('parámetros se pasan sin cambios', () {
      final prog = ProgresionCalculator().generarInicial(
        ejercicioId: 'test-id',
        series: 4,
        repeticiones: 12,
        descanso: 60,
        tipoMedicion: ['repeticiones'],
      );
      expect(prog.nuevasSeries, 4);
      expect(prog.nuevasRepeticiones, 12);
      expect(prog.nuevoDescanso, 60);
    });
  });
}
