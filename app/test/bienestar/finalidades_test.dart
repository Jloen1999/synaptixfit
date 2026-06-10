import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/features/bienestar/application/ejercicios_provider.dart';

void main() {
  group('sanitizarObjetivo', () {
    test('retorna valor estándar si ya es válido', () {
      expect(sanitizarObjetivo('Fuerza Máxima'), 'Fuerza Máxima');
      expect(sanitizarObjetivo('Hipertrofia Muscular'), 'Hipertrofia Muscular');
      expect(sanitizarObjetivo('Movilidad y Flexibilidad'),
          'Movilidad y Flexibilidad');
    });

    test('mapea valores legacy en inglés', () {
      expect(sanitizarObjetivo('fuerza'), 'Fuerza Máxima');
      expect(sanitizarObjetivo('hipertrofia'), 'Hipertrofia Muscular');
      expect(sanitizarObjetivo('ganar_masa'), 'Hipertrofia Muscular');
      expect(sanitizarObjetivo('perder_peso'), 'Acondicionamiento Metabólico');
      expect(sanitizarObjetivo('resistencia'), 'Fuerza Resistencia');
      expect(sanitizarObjetivo('movilidad'), 'Movilidad y Flexibilidad');
      expect(
          sanitizarObjetivo('fitness_general'), 'Estabilidad y Control Motor');
      expect(sanitizarObjetivo('mixto'), 'Hipertrofia Muscular');
      expect(sanitizarObjetivo('cardio'), 'Acondicionamiento Metabólico');
      expect(sanitizarObjetivo('flexibilidad'), 'Movilidad y Flexibilidad');
    });

    test('retorna Hipertrofia Muscular para valores desconocidos', () {
      expect(sanitizarObjetivo('xyz'), 'Hipertrofia Muscular');
      expect(sanitizarObjetivo(''), 'Hipertrofia Muscular');
      expect(sanitizarObjetivo('bodybuilding'), 'Hipertrofia Muscular');
    });

    test('es case-insensitive', () {
      expect(sanitizarObjetivo('FUERZA'), 'Fuerza Máxima');
      expect(sanitizarObjetivo('Ganar_Masa'), 'Hipertrofia Muscular');
      expect(sanitizarObjetivo('Fuerza máxima'), 'Fuerza Máxima');
    });

    test('ignora acentos', () {
      expect(sanitizarObjetivo('fuerza máxima'), 'Fuerza Máxima');
      expect(sanitizarObjetivo('hipertrofia'), 'Hipertrofia Muscular');
    });
  });

  group('finalidadesEstandar', () {
    test('tiene exactamente 7 valores', () {
      expect(finalidadesEstandar.length, 7);
    });

    test('todos los valores esperados están presentes', () {
      expect(finalidadesEstandar, contains('Hipertrofia Muscular'));
      expect(finalidadesEstandar, contains('Fuerza Máxima'));
      expect(finalidadesEstandar, contains('Potencia y Explosividad'));
      expect(finalidadesEstandar, contains('Fuerza Resistencia'));
      expect(finalidadesEstandar, contains('Movilidad y Flexibilidad'));
      expect(finalidadesEstandar, contains('Estabilidad y Control Motor'));
      expect(finalidadesEstandar, contains('Acondicionamiento Metabólico'));
    });
  });

  group('iconoFinalidad', () {
    test('retorna un icono para cada finalidad estándar', () {
      for (final f in finalidadesEstandar) {
        final icono = iconoFinalidad(f);
        expect(icono, isNotNull);
      }
    });

    test('retorna icono default para valor desconocido', () {
      final icono = iconoFinalidad('algo desconocido');
      expect(icono, isNotNull);
    });
  });
}
