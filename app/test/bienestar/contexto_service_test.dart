import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/features/bienestar/infrastructure/recomendacion_contexto_service.dart';
import 'package:synaptixfit/shared/models/db_models.dart';

void main() {
  group('ContextoAcademico', () {
    test('valores por defecto son neutros', () {
      const c = ContextoAcademico();
      expect(c.horasEstudioReales, 0);
      expect(c.nivelEstres, 5);
      expect(c.horasSuenoPromedio, 7);
      expect(c.tieneExamenesProximos, false);
    });
  });

  group('ContextoFisiologico', () {
    test('sin datos de peso: tendencia null', () {
      const c = ContextoFisiologico();
      expect(c.tendenciaPesoSemanal, isNull);
      expect(c.estaPerdiendoPeso, false);
      expect(c.estaGanandoPeso, false);
    });

    test('detecta pérdida de peso', () {
      const c = ContextoFisiologico(
        pesoActual: 80,
        pesoSemanaAnterior: 81,
      );
      expect(c.tendenciaPesoSemanal, -1.0);
      expect(c.estaPerdiendoPeso, true);
      expect(c.estaGanandoPeso, false);
    });

    test('detecta ganancia de peso', () {
      const c = ContextoFisiologico(
        pesoActual: 80,
        pesoSemanaAnterior: 79,
      );
      expect(c.tendenciaPesoSemanal, 1.0);
      expect(c.estaPerdiendoPeso, false);
      expect(c.estaGanandoPeso, true);
    });

    test('peso estable: ni pérdida ni ganancia', () {
      const c = ContextoFisiologico(
        pesoActual: 80,
        pesoSemanaAnterior: 80.2,
      );
      expect(c.tendenciaPesoSemanal, closeTo(-0.2, 0.01));
      expect(c.estaPerdiendoPeso, false);
      expect(c.estaGanandoPeso, false);
    });
  });

  group('AjusteContexto', () {
    test('sinCambios tiene valores neutros', () {
      expect(AjusteContexto.sinCambios.factorVolumen, 1.0);
      expect(AjusteContexto.sinCambios.deltaSeries, 0);
      expect(AjusteContexto.sinCambios.deltaDescanso, 0);
      expect(AjusteContexto.sinCambios.factorCargaTotal, 0.0);
    });
  });

  group('RecomendacionContextoService.calcularAjustes', () {
    final service = RecomendacionContextoService();

    test('sin carga académica ni fisiológica: ajuste neutro', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(rachaActual: 5),
      );
      expect(ajuste.factorVolumen, 1.0);
      expect(ajuste.deltaSeries, 0);
      expect(ajuste.deltaDescanso, 0);
      expect(ajuste.factorCargaTotal >= 0.0, isTrue);
      expect(ajuste.motivo, isNull);
    });

    test('modo exámenes: reduce volumen', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(tieneExamenesProximos: true),
        fisiologico: const ContextoFisiologico(),
      );
      expect(ajuste.factorVolumen, lessThan(1.0));
      expect(ajuste.deltaSeries, lessThan(0));
      expect(ajuste.motivo, contains('exámenes'));
    });

    test('modo exámenes desde fisiologico', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(modoExamenes: true),
      );
      expect(ajuste.factorVolumen, lessThan(1.0));
    });

    test('racha en 0: rutina de reenganche', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(rachaActual: 0),
      );
      expect(ajuste.factorVolumen, lessThan(1.0));
      expect(ajuste.motivo, contains('reenganche'));
    });

    test('racha > 0: sin ajuste por racha', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(rachaActual: 5),
      );
      expect(ajuste.motivo, isNull);
    });

    test('pérdida de peso: preservar masa', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(
          pesoActual: 80,
          pesoSemanaAnterior: 82,
        ),
      );
      expect(ajuste.factorVolumen, lessThan(1.0));
      expect(ajuste.motivo, contains('pérdida'));
    });

    test('ganancia de peso: mayor volumen', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(
          pesoActual: 82,
          pesoSemanaAnterior: 80,
          rachaActual: 5,
        ),
      );
      expect(ajuste.factorVolumen, greaterThan(1.0));
      expect(ajuste.motivo, contains('ganancia'));
    });

    test('estado diario con fatiga alta', () {
      final estado = EstadoDiarioDb(
        id: 'x',
        usuarioId: 'x',
        fecha: DateTime.now(),
        calidadSueno: 2,
        nivelEstres: 4,
        nivelEnergia: 2,
        dolorMuscular: 4,
        zonasDolor: const [],
        listoParaEntrenar: true,
        creadoEn: DateTime.now(),
      );
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(),
        estadoDiario: estado,
      );
      expect(ajuste.factorVolumen, lessThan(1.0));
      expect(ajuste.motivo, contains('fatiga alta'));
    });

    test('no listo para entrenar: reducción drástica', () {
      final estado = EstadoDiarioDb(
        id: 'x',
        usuarioId: 'x',
        fecha: DateTime.now(),
        calidadSueno: 3,
        nivelEstres: 3,
        nivelEnergia: 3,
        dolorMuscular: 2,
        zonasDolor: const [],
        listoParaEntrenar: false,
        creadoEn: DateTime.now(),
      );
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(),
        fisiologico: const ContextoFisiologico(rachaActual: 5),
        estadoDiario: estado,
      );
      expect(ajuste.factorVolumen, 0.60);
      expect(ajuste.deltaSeries, -2);
    });

    test('FCT alto con mucha carga académica', () {
      final ajuste = service.calcularAjustes(
        academico: const ContextoAcademico(
          horasEstudioReales: 30,
          nivelEstres: 9,
          evaluacionesSemana: 4,
          horasSuenoPromedio: 4,
        ),
        fisiologico: const ContextoFisiologico(),
      );
      expect(ajuste.factorCargaTotal, greaterThan(0.5));
      expect(ajuste.factorVolumen, lessThan(1.0));
    });
  });
}
