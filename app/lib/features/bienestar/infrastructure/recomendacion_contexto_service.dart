import '../../../shared/models/db_models.dart';
import '../application/rutina_provider.dart';
import 'cross_regulation_service.dart';
import 'parametros_objetivo.dart';

// ---------------------------------------------------------------------------
// DTOs
// ---------------------------------------------------------------------------

class ContextoAcademico {
  final double horasEstudioReales;
  final double nivelEstres;
  final int evaluacionesSemana;
  final double horasSuenoPromedio;
  final bool tieneExamenesProximos;
  final double adherenciaAcademica;
  final double estadoEnergetico;

  const ContextoAcademico({
    this.horasEstudioReales = 0,
    this.nivelEstres = 5,
    this.evaluacionesSemana = 0,
    this.horasSuenoPromedio = 7,
    this.tieneExamenesProximos = false,
    this.adherenciaAcademica = 50,
    this.estadoEnergetico = 50,
  });
}

class ContextoFisiologico {
  final double? pesoActual;
  final double? pesoSemanaAnterior;
  final int rachaActual;
  final int nivelUsuario;
  final bool modoExamenes;

  const ContextoFisiologico({
    this.pesoActual,
    this.pesoSemanaAnterior,
    this.rachaActual = 0,
    this.nivelUsuario = 1,
    this.modoExamenes = false,
  });

  double? get tendenciaPesoSemanal {
    if (pesoActual == null || pesoSemanaAnterior == null) return null;
    return pesoActual! - pesoSemanaAnterior!;
  }

  bool get estaPerdiendoPeso =>
      tendenciaPesoSemanal != null && tendenciaPesoSemanal! < -0.5;

  bool get estaGanandoPeso =>
      tendenciaPesoSemanal != null && tendenciaPesoSemanal! > 0.5;
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

class AjusteContexto {
  final double factorVolumen;
  final int deltaSeries;
  final int deltaDescanso;
  final double factorCargaTotal;
  final String? motivo;

  const AjusteContexto({
    required this.factorVolumen,
    required this.deltaSeries,
    required this.deltaDescanso,
    required this.factorCargaTotal,
    this.motivo,
  });

  static const sinCambios = AjusteContexto(
    factorVolumen: 1.0,
    deltaSeries: 0,
    deltaDescanso: 0,
    factorCargaTotal: 0.0,
  );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class RecomendacionContextoService {
  static const _umbralHorasSueno = 8;
  static const _umbralHorasEstudio = 30;

  static const _mapZonasAMusculos = {
    'piernas': [
      'Cuádriceps',
      'Isquiotibiales',
      'Glúteo mayor',
      'Glúteo medio',
      'Aductores',
      'Abductores',
      'Gemelos',
      'Sóleo',
      'Tibial anterior',
    ],
    'espalda': [
      'Dorsal ancho',
      'Romboides',
      'Trapecio superior',
      'Trapecio medio',
      'Trapecio inferior',
      'Erectores espinales',
    ],
    'hombros': [
      'Deltoides anterior',
      'Deltoides medio',
      'Deltoides posterior',
    ],
    'brazos': [
      'Bíceps braquial',
      'Tríceps braquial',
      'Braquial',
      'Braquiorradial',
    ],
    'pecho': [
      'Pectoral mayor',
      'Pectoral menor',
      'Serrato anterior',
    ],
    'core': [
      'Recto abdominal',
      'Oblicuos',
      'Transverso abdominal',
    ],
  };

  AjusteContexto calcularAjustes({
    required ContextoAcademico academico,
    required ContextoFisiologico fisiologico,
    EstadoDiarioDb? estadoDiario,
    int? diasProximoExamen,
  }) {
    double factorVolumen = 1.0;
    int deltaSeries = 0;
    int deltaDescanso = 0;
    final motivos = <String>[];

    final fct = calcularFCT(academico, estadoDiario);

    // ── Capa de regulación cruzada asintótica (Fase 3: Fórmulas Neurofisiológicas) ──
    if (diasProximoExamen != null) {
      final vMod = CrossRegulationService.calcularVolumenModificado(
        volumenBase: 1.0,
        cargaCognitiva: fct,
        cargaMaxima: 1.0,
        diasHastaExamen: diasProximoExamen,
      );
      final ajusteAsintotico = vMod.clamp(0.4, 1.0);
      if (ajusteAsintotico < factorVolumen) {
        factorVolumen = ajusteAsintotico;
        motivos.add('Regulación cruzada: examen en $diasProximoExamen días');
      }
    }

    if (fisiologico.modoExamenes || academico.tieneExamenesProximos) {
      factorVolumen *= 0.70;
      deltaSeries -= 1;
      deltaDescanso += 30;
      motivos.add('Modo exámenes activo');
    }

    if (fct > 0.7) {
      factorVolumen *= 0.50;
      deltaSeries -= 1;
      deltaDescanso += 30;
      motivos.add('Carga total muy alta (FCT ${fct.toStringAsFixed(2)})');
    } else if (fct > 0.5) {
      factorVolumen *= 0.80;
      deltaSeries -= 1;
      deltaDescanso += 20;
      motivos.add('Carga total alta (FCT ${fct.toStringAsFixed(2)})');
    } else if (fct > 0.3) {
      factorVolumen *= 0.90;
      deltaDescanso += 15;
      motivos.add('Carga total moderada (FCT ${fct.toStringAsFixed(2)})');
    }

    if (academico.estadoEnergetico < 30) {
      factorVolumen *= 0.40;
      deltaDescanso += 60;
      motivos.add(
          'Estado energético crítico (${academico.estadoEnergetico.toStringAsFixed(0)}/100) — sesión de recuperación');
    } else if (academico.estadoEnergetico < 50) {
      factorVolumen *= 0.75;
      deltaDescanso += 20;
      motivos.add(
          'Estado energético bajo (${academico.estadoEnergetico.toStringAsFixed(0)}/100) — reducir intensidad');
    }

    if (fisiologico.rachaActual == 0) {
      factorVolumen *= 0.75;
      deltaSeries -= 1;
      motivos.add('Sin racha activa — rutina de reenganche');
    }

    if (fisiologico.estaPerdiendoPeso) {
      factorVolumen *= 0.85;
      deltaSeries -= 1;
      motivos.add('Tendencia de pérdida de peso — preservar masa muscular');
    }

    if (fisiologico.estaGanandoPeso) {
      factorVolumen *= 1.10;
      deltaSeries += 1;
      motivos.add('Tendencia de ganancia de peso — mayor volumen');
    }

    if (estadoDiario != null && estadoDiario.requiereAdaptacion) {
      factorVolumen *= 0.80;
      deltaSeries -= 1;
      motivos.add(
          'Estado diario: fatiga alta (${estadoDiario.puntuacionFatiga}/100)');
    }

    if (estadoDiario != null && !estadoDiario.listoParaEntrenar) {
      factorVolumen *= 0.60;
      deltaSeries -= 2;
      deltaDescanso += 30;
      motivos.add('Usuario no se siente listo para entrenar');
    }

    if (estadoDiario != null && estadoDiario.calidadSueno <= 2) {
      factorVolumen *= 0.70;
      deltaDescanso += 30;
      motivos.add('Sueño deficiente (${estadoDiario.calidadSueno}/5)');
    }
    if (estadoDiario != null && estadoDiario.nivelEstres >= 4) {
      deltaDescanso += 15;
      motivos.add(
          'Estrés elevado (${estadoDiario.nivelEstres}/5) — movilidad recomendada');
    }
    if (estadoDiario != null && estadoDiario.nivelEnergia <= 2) {
      factorVolumen *= 0.75;
      motivos.add('Energía baja (${estadoDiario.nivelEnergia}/5)');
    }
    if (estadoDiario != null && estadoDiario.dolorMuscular >= 4) {
      factorVolumen *= 0.85;
      motivos.add('Dolor muscular alto (${estadoDiario.dolorMuscular}/5)');
    }

    return AjusteContexto(
      factorVolumen: factorVolumen.clamp(0.3, 1.5),
      deltaSeries: deltaSeries.clamp(-3, 2),
      deltaDescanso: deltaDescanso.clamp(-30, 60),
      factorCargaTotal: fct,
      motivo: motivos.isEmpty ? null : motivos.join(' | '),
    );
  }

  double calcularFCT(ContextoAcademico ac, EstadoDiarioDb? estado) {
    double fct = 0.0;

    fct += (ac.horasEstudioReales / _umbralHorasEstudio).clamp(0.0, 1.0) * 0.25;
    fct += (ac.nivelEstres / 10.0).clamp(0.0, 1.0) * 0.25;
    fct += (ac.evaluacionesSemana / 5.0).clamp(0.0, 1.0) * 0.15;
    fct += ((_umbralHorasSueno - ac.horasSuenoPromedio) / _umbralHorasSueno)
            .clamp(0.0, 1.0) *
        0.15;

    if (estado != null) {
      fct += ((estado.dolorMuscular - 1) / 4.0).clamp(0.0, 1.0) * 0.10;
      fct += ((6 - estado.nivelEnergia) / 5.0).clamp(0.0, 1.0) * 0.10;
    }

    return fct.clamp(0.0, 1.0);
  }

  Map<int, Map<int, List<EjercicioInput>>> aplicarAjustes({
    required Map<int, Map<int, List<EjercicioInput>>> estructura,
    required AjusteContexto ajuste,
    required ParametrosObjetivo params,
  }) {
    if (ajuste.factorVolumen == 1.0 &&
        ajuste.deltaSeries == 0 &&
        ajuste.deltaDescanso == 0) {
      return estructura;
    }

    final resultado = <int, Map<int, List<EjercicioInput>>>{};
    for (final semana in estructura.entries) {
      resultado[semana.key] = {};
      for (final dia in semana.value.entries) {
        resultado[semana.key]![dia.key] = dia.value.map((e) {
          final nuevasSeries = (e.series + ajuste.deltaSeries)
              .clamp(params.seriesMin, params.seriesMax);
          final nuevoDescanso = (e.segundosDescanso + ajuste.deltaDescanso)
              .clamp(params.descansoMin, params.descansoMax);
          return EjercicioInput(
            ejercicioId: e.ejercicioId,
            series: nuevasSeries,
            repeticiones: e.repeticiones,
            segundosDescanso: nuevoDescanso,
            pesoKg: e.pesoKg,
            pesosKg: e.pesosKg,
            duracionObjetivoSegundos: e.duracionObjetivoSegundos,
            distanciaMetros: e.distanciaMetros,
            tiempoIsometricoSegundos: e.tiempoIsometricoSegundos,
          );
        }).toList();
      }
    }
    return resultado;
  }

  Set<String> _musculosEnZonaDolor(List<String> zonasDolor) {
    final musculos = <String>{};
    for (final zona in zonasDolor) {
      final z = zona.toLowerCase().trim();
      final mapped = _mapZonasAMusculos[z];
      if (mapped != null) {
        musculos.addAll(mapped.map((m) => m.toLowerCase()));
      }
    }
    return musculos;
  }

  Map<int, Map<int, List<EjercicioInput>>> filtrarPorCheckIn({
    required Map<int, Map<int, List<EjercicioInput>>> estructura,
    required EstadoDiarioDb estadoDiario,
    required List<EjercicioDb> catalogo,
  }) {
    final musculosEvitar = _musculosEnZonaDolor(estadoDiario.zonasDolor);
    final excluirCompuestos = estadoDiario.dolorMuscular >= 4;

    final resultado = <int, Map<int, List<EjercicioInput>>>{};
    for (final semana in estructura.entries) {
      resultado[semana.key] = {};
      for (final dia in semana.value.entries) {
        var ejercicios = dia.value;

        if (musculosEvitar.isNotEmpty) {
          ejercicios = ejercicios.where((e) {
            final original = catalogo.cast<EjercicioDb?>().firstWhere(
                  (ex) => ex?.id == e.ejercicioId,
                  orElse: () => null,
                );
            if (original == null) return true;
            final musculosEj =
                original.musculosObjetivo.map((m) => m.toLowerCase()).toSet();
            return musculosEj.intersection(musculosEvitar).isEmpty;
          }).toList();
        }

        if (excluirCompuestos) {
          ejercicios = ejercicios.where((e) {
            final original = catalogo.cast<EjercicioDb?>().firstWhere(
                  (ex) => ex?.id == e.ejercicioId,
                  orElse: () => null,
                );
            if (original == null) return true;
            return original.musculosSecundarios.length < 3;
          }).toList();
        }

        if (estadoDiario.nivelEstres >= 4) {
          final tieneMovilidad = ejercicios.any((e) {
            final original = catalogo.cast<EjercicioDb?>().firstWhere(
                  (ex) => ex?.id == e.ejercicioId,
                  orElse: () => null,
                );
            return original?.modalidadEntrenamiento == 'movilidad';
          });
          if (!tieneMovilidad) {
            final movilidadPool =
                catalogo.where((e) => e.modalidadEntrenamiento == 'movilidad');
            if (movilidadPool.isNotEmpty) {
              ejercicios = [
                ...ejercicios,
                EjercicioInput(
                  ejercicioId: movilidadPool.first.id,
                  series: 2,
                  repeticiones: 10,
                  segundosDescanso: 30,
                  pesoKg: null,
                  duracionObjetivoSegundos:
                      movilidadPool.first.tipoMedicion.contains('tiempo')
                          ? 600
                          : null,
                ),
              ];
            }
          }
        }

        resultado[semana.key]![dia.key] = ejercicios;
      }
    }
    return resultado;
  }
}
