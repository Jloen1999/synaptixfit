import '../../../shared/models/db_models.dart';
import '../application/ejercicios_provider.dart';
import '../application/rutina_provider.dart';
import 'parametros_objetivo.dart';

enum FaseTransicion { estable, temprana, media, completa }

class ParametrosTransicion {
  final ParametrosObjetivo params;
  final FaseTransicion fase;
  final double factorInterpolacion;
  final String? motivo;

  const ParametrosTransicion({
    required this.params,
    required this.fase,
    required this.factorInterpolacion,
    this.motivo,
  });

  static final sinTransicion = ParametrosTransicion(
    params: ParametrosObjetivo.de('Hipertrofia Muscular'),
    fase: FaseTransicion.estable,
    factorInterpolacion: 1.0,
  );
}

class TransicionObjetivoService {
  ParametrosTransicion calcularTransicion({
    required String objetivoActual,
    HistorialObjetivoDb? registroAnterior,
  }) {
    if (registroAnterior == null || registroAnterior.objetivoAnterior == null) {
      return ParametrosTransicion(
        params: ParametrosObjetivo.de(objetivoActual),
        fase: FaseTransicion.estable,
        factorInterpolacion: 1.0,
        motivo: null,
      );
    }

    final nuevo = sanitizarObjetivo(objetivoActual);
    final viejo = sanitizarObjetivo(registroAnterior.objetivoAnterior!);

    if (nuevo == viejo) {
      return ParametrosTransicion(
        params: ParametrosObjetivo.de(nuevo),
        fase: FaseTransicion.estable,
        factorInterpolacion: 1.0,
      );
    }

    final semanasEnNuevo = registroAnterior.semanasActivo;
    final factor = _factorTransicion(semanasEnNuevo);
    final fase = _faseDesdeFactor(factor);

    final params = _interpolar(
      ParametrosObjetivo.de(viejo),
      ParametrosObjetivo.de(nuevo),
      factor,
    );

    return ParametrosTransicion(
      params: params,
      fase: fase,
      factorInterpolacion: factor,
      motivo: 'Transición $viejo → $nuevo (semana ${semanasEnNuevo + 1})',
    );
  }

  double _factorTransicion(int semanasEnNuevoObjetivo) {
    if (semanasEnNuevoObjetivo <= 0) return 0.30;
    if (semanasEnNuevoObjetivo <= 1) return 0.70;
    return 1.0;
  }

  FaseTransicion _faseDesdeFactor(double factor) {
    if (factor >= 1.0) return FaseTransicion.completa;
    if (factor >= 0.60) return FaseTransicion.media;
    if (factor >= 0.20) return FaseTransicion.temprana;
    return FaseTransicion.estable;
  }

  ParametrosObjetivo _interpolar(
    ParametrosObjetivo viejo,
    ParametrosObjetivo nuevo,
    double factor,
  ) {
    int lerpInt(int a, int b) => (a + (b - a) * factor).round();
    double lerpDouble(double a, double b) => a + (b - a) * factor;

    final sMin = lerpInt(viejo.seriesMin, nuevo.seriesMin);
    final sMax = lerpInt(viejo.seriesMax, nuevo.seriesMax);
    final rMin = lerpInt(viejo.repsMin, nuevo.repsMin);
    final rMax = lerpInt(viejo.repsMax, nuevo.repsMax);
    final dMin = lerpInt(viejo.descansoMin, nuevo.descansoMin);
    final dMax = lerpInt(viejo.descansoMax, nuevo.descansoMax);

    return ParametrosObjetivo(
      objetivo: nuevo.objetivo,
      seriesMin: sMin,
      seriesMax: sMax < sMin ? sMin : sMax,
      repsMin: rMin,
      repsMax: rMax < rMin ? rMin : rMax,
      descansoMin: dMin,
      descansoMax: dMax < dMin ? dMin : dMax,
      rpeMin: lerpDouble(viejo.rpeMin, nuevo.rpeMin),
      rpeMax: lerpDouble(viejo.rpeMax, nuevo.rpeMax),
      intensidadRelativa:
          lerpDouble(viejo.intensidadRelativa, nuevo.intensidadRelativa),
      ejerciciosPorDia: lerpInt(viejo.ejerciciosPorDia, nuevo.ejerciciosPorDia),
      priorizarCompuestos:
          factor < 0.5 ? viejo.priorizarCompuestos : nuevo.priorizarCompuestos,
      modalidades: factor >= 0.5 ? nuevo.modalidades : viejo.modalidades,
      finalidadesEjercicio: factor >= 0.5
          ? nuevo.finalidadesEjercicio
          : viejo.finalidadesEjercicio,
      volumenSemanalObjetivo:
          lerpInt(viejo.volumenSemanalObjetivo, nuevo.volumenSemanalObjetivo),
      admiteCircuito:
          factor >= 0.5 ? nuevo.admiteCircuito : viejo.admiteCircuito,
    );
  }

  // ---------------------------------------------------------------------------
  // Aplicar transición a una estructura
  // ---------------------------------------------------------------------------

  Map<int, Map<int, List<EjercicioInput>>> aplicarTransicion({
    required Map<int, Map<int, List<EjercicioInput>>> estructura,
    required ParametrosTransicion transicion,
  }) {
    if (transicion.fase == FaseTransicion.completa) return estructura;

    final resultado = <int, Map<int, List<EjercicioInput>>>{};
    for (final semana in estructura.entries) {
      resultado[semana.key] = {};
      for (final dia in semana.value.entries) {
        resultado[semana.key]![dia.key] = dia.value.map((e) {
          final ns = e.series
              .clamp(transicion.params.seriesMin, transicion.params.seriesMax);
          final nr = e.repeticiones
              .clamp(transicion.params.repsMin, transicion.params.repsMax);
          final nd = e.segundosDescanso.clamp(
              transicion.params.descansoMin, transicion.params.descansoMax);
          return EjercicioInput(
            ejercicioId: e.ejercicioId,
            series: ns,
            repeticiones: nr,
            segundosDescanso: nd,
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
}
