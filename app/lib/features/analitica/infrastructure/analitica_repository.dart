import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/insight_correlacion_dto.dart';
import '../domain/metrica_semanal_dto.dart';

// ---------------------------------------------------------------------------
// Repositorio de analitica — consulta la vista v_analitica_semanal y la tabla
// carga_academica_semanal para generar metricas e insights de correlacion.
// ---------------------------------------------------------------------------

/// Columnas que se seleccionan de la vista para minimizar ancho de banda.
const _columnasMetrica =
    'semana_inicio,sesiones,rpe_promedio,minutos_totales,calorias_totales';

class AnaliticaRepository {
  AnaliticaRepository(this._client);

  final SupabaseClient _client;

  // ─────────────────────────────────────────────────────────────────────────
  // Metricas semanales
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene las metricas agregadas semanales para un usuario.
  /// [semanas] limita la cantidad de semanas hacia atras (default 12).
  Future<List<MetricaSemanal>> obtenerMetricas(
    String usuarioId, {
    int semanas = 12,
  }) async {
    final limite = DateTime.now().subtract(Duration(days: semanas * 7));

    final response = await _client
        .from('v_analitica_semanal')
        .select(_columnasMetrica)
        .eq('usuario_id', usuarioId)
        .gte('semana_inicio', limite.toIso8601String().substring(0, 10))
        .order('semana_inicio', ascending: false)
        .timeout(const Duration(seconds: 10));

    return (response as List)
        .map((row) => MetricaSemanal.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Correlacion carga academica vs RPE
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcula la correlacion de Pearson entre las horas de estudio reales
  /// y el RPE promedio semanal para el usuario dado.
  ///
  /// Retorna null si no hay suficientes datos (menos de 4 semanas).
  Future<InsightCorrelacion?> generarCorrelacionCargaVsRpe(
    String usuarioId,
  ) async {
    // Obtener carga academica semanal (ultimas 16 semanas)
    final cargaResponse = await _client
        .from('carga_academica_semanal')
        .select('semana_inicio,horas_estudio_reales')
        .eq('usuario_id', usuarioId)
        .order('semana_inicio', ascending: true)
        .limit(52)
        .timeout(const Duration(seconds: 10));

    final cargaData = cargaResponse as List;

    // Obtener metricas de entrenamiento (ultimas 16 semanas)
    final metricaResponse = await _client
        .from('v_analitica_semanal')
        .select('semana_inicio,rpe_promedio')
        .eq('usuario_id', usuarioId)
        .order('semana_inicio', ascending: true)
        .limit(52)
        .timeout(const Duration(seconds: 10));

    final metricaData = metricaResponse as List;

    if (cargaData.length < 4 || metricaData.length < 4) return null;

    // Indexar metricas por semana_inicio para cruce rapido
    final rpePorSemana = <String, double>{};
    for (final m in metricaData) {
      final map = m as Map<String, dynamic>;
      final semana = map['semana_inicio'].toString().substring(0, 10);
      final rpe = (map['rpe_promedio'] as num?)?.toDouble() ?? 0;
      rpePorSemana[semana] = rpe;
    }

    // Cruzar: alinear semanas con ambos datos
    final horasEstudio = <double>[];
    final rpeValores = <double>[];
    for (final c in cargaData) {
      final map = c as Map<String, dynamic>;
      final semana = map['semana_inicio'].toString().substring(0, 10);
      final horas = (map['horas_estudio_reales'] as num?)?.toDouble() ?? 0;
      final rpe = rpePorSemana[semana];
      if (rpe != null && horas > 0) {
        horasEstudio.add(horas);
        rpeValores.add(rpe);
      }
    }

    if (horasEstudio.length < 4) return null;

    final coef = _pearson(horasEstudio, rpeValores);

    // Construir insight
    const titulo = 'Carga academica vs RPE';
    final interpretacion =
        _interpretarCorrelacion(coef, horasEstudio, rpeValores);
    final recomendacion = _generarRecomendacion(coef);

    return InsightCorrelacion(
      titulo: titulo,
      coeficiente: coef,
      interpretacion: interpretacion,
      recomendacion: recomendacion,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Puntos de correlacion (scatter)
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene los puntos individuales (horasEstudio, rpe) para graficar
  /// un scatter plot de carga academica vs RPE.
  ///
  /// Retorna una lista vacia si no hay suficientes datos.
  Future<List<Map<String, double>>> obtenerPuntosCorrelacion(
    String usuarioId,
  ) async {
    // Obtener carga academica semanal (ultimas 16 semanas)
    final cargaResponse = await _client
        .from('carga_academica_semanal')
        .select('semana_inicio,horas_estudio_reales')
        .eq('usuario_id', usuarioId)
        .order('semana_inicio', ascending: true)
        .limit(52)
        .timeout(const Duration(seconds: 10));

    final cargaData = cargaResponse as List;

    // Obtener metricas de entrenamiento (ultimas 16 semanas)
    final metricaResponse = await _client
        .from('v_analitica_semanal')
        .select('semana_inicio,rpe_promedio')
        .eq('usuario_id', usuarioId)
        .order('semana_inicio', ascending: true)
        .limit(52)
        .timeout(const Duration(seconds: 10));

    final metricaData = metricaResponse as List;

    // Indexar metricas por semana_inicio
    final rpePorSemana = <String, double>{};
    for (final m in metricaData) {
      final map = m as Map<String, dynamic>;
      final semana = map['semana_inicio'].toString().substring(0, 10);
      final rpe = (map['rpe_promedio'] as num?)?.toDouble() ?? 0;
      rpePorSemana[semana] = rpe;
    }

    // Cruzar
    final puntos = <Map<String, double>>[];
    for (final c in cargaData) {
      final map = c as Map<String, dynamic>;
      final semana = map['semana_inicio'].toString().substring(0, 10);
      final horas = (map['horas_estudio_reales'] as num?)?.toDouble() ?? 0;
      final rpe = rpePorSemana[semana];
      if (rpe != null && horas > 0) {
        puntos.add({
          'horasEstudio': horas,
          'rpe': rpe,
        });
      }
    }

    return puntos;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Calculo de correlacion de Pearson
  // ─────────────────────────────────────────────────────────────────────────

  double _pearson(List<double> x, List<double> y) {
    assert(x.length == y.length, 'Las listas deben tener el mismo tamano');
    final n = x.length;
    if (n < 2) return 0;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);

    final numerador = n * sumXY - sumX * sumY;
    final denominador =
        sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    if (denominador == 0) return 0;
    return numerador / denominador;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Interpretacion en lenguaje natural
  // ─────────────────────────────────────────────────────────────────────────

  String _interpretarCorrelacion(
    double coef,
    List<double> horas,
    List<double> rpe,
  ) {
    final abs = coef.abs();
    final dir = coef >= 0 ? 'positiva' : 'negativa';
    final promHoras = horas.reduce((a, b) => a + b) / horas.length;

    if (abs < 0.2) {
      return 'No se encontro una relacion significativa entre tus horas '
          'de estudio y tu rendimiento en el gimnasio. Ambos aspectos '
          'parecen independientes en tu rutina actual.';
    }

    if (coef >= 0.6) {
      return 'Existe una correlacion positiva fuerte: cuando estudias mas '
          'horas, tu RPE promedio tiende a ser mas alto. Esto sugiere que '
          'mantienes buen rendimiento incluso bajo carga academica, o que '
          'la actividad fisica te ayuda a compensar el estres.';
    }

    if (coef <= -0.6) {
      return 'Se detecto una correlacion negativa fuerte: a mayor carga '
          'academica, menor es tu RPE promedio. Esto es normal en epocas '
          'de examenes; el estres y la fatiga mental pueden afectar '
          'tu energia en el gimnasio. Promedio de estudio: ${promHoras.toStringAsFixed(1)}h/semana.';
    }

    if (coef >= 0.4) {
      return 'Hay una correlacion positiva moderada entre estudio y '
          'rendimiento fisico. Tus semanas mas intensas academicamente '
          'suelen coincidir con buenos entrenamientos.';
    }

    if (coef <= -0.4) {
      return 'Se observa una correlacion negativa moderada: en semanas '
          'con mas estudio, tu RPE promedio baja ligeramente. '
          'Considera ajustar la intensidad del entrenamiento en esas semanas.';
    }

    // Caso residual 0.2-0.4
    return 'Existe una ligera correlacion $dir entre tu carga academica '
        'y tu RPE. La relacion es debil, pero podria intensificarse '
        'en periodos de alta exigencia.';
  }

  String _generarRecomendacion(double coef) {
    final abs = coef.abs();

    if (abs < 0.2) {
      return 'Sigue monitoreando ambas variables. Si notas cambios en '
          'las proximas semanas, ajusta tu rutina segun como te sientas.';
    }

    if (coef <= -0.4) {
      return 'En semanas de alta carga academica, prioriza entrenamientos '
          'de mantenimiento (menor volumen e intensidad). Escucha a tu '
          'cuerpo y no te exijas mas de lo necesario.';
    }

    if (coef >= 0.6) {
      return 'Aprovecha la sinergia positiva: el ejercicio parece ayudarte '
          'a manejar la carga academica. Manten tu frecuencia de '
          'entrenamiento incluso en epocas exigentes.';
    }

    return 'Observa como evoluciona la relacion en las proximas semanas. '
        'Si la tendencia se acentua, considera planificar sesiones '
        'de recuperacion activa en dias de mucho estudio.';
  }
}
