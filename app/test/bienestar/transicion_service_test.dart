import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/features/bienestar/infrastructure/transicion_objetivo_service.dart';
import 'package:synaptixfit/shared/models/db_models.dart';

void main() {
  group('TransicionObjetivoService.calcularTransicion', () {
    final service = TransicionObjetivoService();

    test('sin registro anterior: fase estable, factor 1.0', () {
      final t = service.calcularTransicion(
        objetivoActual: 'Fuerza Máxima',
      );
      expect(t.fase, FaseTransicion.estable);
      expect(t.factorInterpolacion, 1.0);
      expect(t.motivo, isNull);
    });

    test('sin objetivo anterior en el registro: estable', () {
      final registro = HistorialObjetivoDb(
        id: 'x',
        usuarioId: 'x',
        objetivo: 'Hipertrofia Muscular',
        objetivoAnterior: null,
        fechaInicio: DateTime.now().subtract(const Duration(days: 10)),
        creadoEn: DateTime.now(),
      );
      final t = service.calcularTransicion(
        objetivoActual: 'Fuerza Máxima',
        registroAnterior: registro,
      );
      expect(t.fase, FaseTransicion.estable);
      expect(t.factorInterpolacion, 1.0);
    });

    test('mismo objetivo: estable', () {
      final registro = HistorialObjetivoDb(
        id: 'x',
        usuarioId: 'x',
        objetivo: 'Fuerza Máxima',
        objetivoAnterior: 'Fuerza Máxima',
        fechaInicio: DateTime.now().subtract(const Duration(days: 3)),
        creadoEn: DateTime.now(),
      );
      final t = service.calcularTransicion(
        objetivoActual: 'Fuerza Máxima',
        registroAnterior: registro,
      );
      expect(t.fase, FaseTransicion.estable);
      expect(t.factorInterpolacion, 1.0);
    });

    test('cambio reciente (semana 0): factor 0.30', () {
      final registro = HistorialObjetivoDb(
        id: 'x',
        usuarioId: 'x',
        objetivo: 'Fuerza Máxima',
        objetivoAnterior: 'Hipertrofia Muscular',
        fechaInicio: DateTime.now().subtract(const Duration(days: 2)),
        creadoEn: DateTime.now(),
      );
      final t = service.calcularTransicion(
        objetivoActual: 'Fuerza Máxima',
        registroAnterior: registro,
      );
      expect(t.factorInterpolacion, 0.30);
      expect(t.fase, FaseTransicion.temprana);
      expect(t.motivo, contains('Transición'));
    });

    test('cambio hace 8 días (semana 1): factor 0.70', () {
      final registro = HistorialObjetivoDb(
        id: 'x',
        usuarioId: 'x',
        objetivo: 'Fuerza Máxima',
        objetivoAnterior: 'Hipertrofia Muscular',
        fechaInicio: DateTime.now().subtract(const Duration(days: 8)),
        creadoEn: DateTime.now(),
      );
      final t = service.calcularTransicion(
        objetivoActual: 'Fuerza Máxima',
        registroAnterior: registro,
      );
      expect(t.factorInterpolacion, 0.70);
      expect(t.fase, FaseTransicion.media);
    });

    test('cambio hace 16 días (semana 2+): factor 1.0', () {
      final registro = HistorialObjetivoDb(
        id: 'x',
        usuarioId: 'x',
        objetivo: 'Fuerza Máxima',
        objetivoAnterior: 'Hipertrofia Muscular',
        fechaInicio: DateTime.now().subtract(const Duration(days: 16)),
        creadoEn: DateTime.now(),
      );
      final t = service.calcularTransicion(
        objetivoActual: 'Fuerza Máxima',
        registroAnterior: registro,
      );
      expect(t.factorInterpolacion, 1.0);
      expect(t.fase, FaseTransicion.completa);
    });

    test('transición con valores legacy funciona', () {
      final registro = HistorialObjetivoDb(
        id: 'x',
        usuarioId: 'x',
        objetivo: 'Fuerza Máxima',
        objetivoAnterior: 'ganar_masa',
        fechaInicio: DateTime.now().subtract(const Duration(days: 1)),
        creadoEn: DateTime.now(),
      );
      final t = service.calcularTransicion(
        objetivoActual: 'fuerza',
        registroAnterior: registro,
      );
      expect(t.factorInterpolacion, 0.30);
      expect(t.params.objetivo, 'Fuerza Máxima');
    });

    test('sinTransicion es valido', () {
      expect(ParametrosTransicion.sinTransicion.factorInterpolacion, 1.0);
      expect(ParametrosTransicion.sinTransicion.fase, FaseTransicion.estable);
    });
  });
}
