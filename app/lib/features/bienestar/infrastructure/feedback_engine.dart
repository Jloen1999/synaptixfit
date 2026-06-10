import 'package:supabase_flutter/supabase_flutter.dart';

import 'progresion_calculator.dart';

class FeedbackEngine {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> procesarSesion({
    required String sesionId,
    required String usuarioId,
    String? rutinaId,
  }) async {
    final sesion = await _client
        .from('sesiones_registradas')
        .select('rpe')
        .eq('id', sesionId)
        .maybeSingle();
    final rpe = (sesion?['rpe'] as num?)?.toDouble();

    final series =
        await _client.from('series_sesion').select().eq('sesion_id', sesionId);

    if ((series as List).isEmpty) return;

    final seriesList = (series as List).map((s) {
      final map = s as Map<String, dynamic>;
      return SerieRealizadaDto(
        numeroSerie: (map['numero_serie'] as num?)?.toInt() ?? 1,
        repeticionesRealizadas:
            (map['repeticiones_realizadas'] as num?)?.toInt(),
        pesoKg: (map['peso_kg'] as num?)?.toDouble(),
        completada: map['completada'] == true,
        failedReps: (map['failed_reps'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    final totalFailed = seriesList.fold<int>(0, (s, e) => s + e.failedReps);
    final totalSeries = seriesList.length;
    final completadas = seriesList.where((s) => s.completada).length;

    if (totalFailed > 0) {
      final factor = (100 - (totalFailed * 5)).clamp(70, 95);
      final pctReduccion = 100 - factor;
      await _insertarRecomendacion(
        usuarioId: usuarioId,
        rutinaId: rutinaId,
        tipo: 'degradacion',
        titulo: 'Reducir carga — $totalFailed repeticiones fallidas',
        descripcion:
            'En $completadas de $totalSeries series tuviste fallos. Para la proxima sesion se recomienda bajar la carga un $pctReduccion%.',
        datos: {'total_failed': totalFailed, 'total_series': totalSeries},
      );
    }

    if (rpe != null &&
        rpe <= 5.0 &&
        totalFailed == 0 &&
        completadas == totalSeries &&
        totalSeries > 0) {
      final pesos = seriesList
          .where((s) => s.pesoKg != null && s.pesoKg! > 0)
          .map((s) => s.pesoKg!)
          .toList();
      if (pesos.isNotEmpty) {
        await _insertarRecomendacion(
          usuarioId: usuarioId,
          rutinaId: rutinaId,
          tipo: 'progresion',
          titulo: 'Considera aumentar carga',
          descripcion:
              'Completaste todas las series sin fallos con RPE $rpe. Intenta subir un 5-10% el peso.',
          datos: {
            'peso_promedio': pesos.reduce((a, b) => a + b) / pesos.length,
            'rpe': rpe,
          },
        );
      }
    }
  }

  Future<void> detectarInactividad(String usuarioId) async {
    final ultima = await _client
        .from('sesiones_registradas')
        .select('completada_en')
        .eq('usuario_id', usuarioId)
        .order('completada_en', ascending: false)
        .limit(1)
        .maybeSingle();

    if (ultima == null) return;

    final ultimaFecha =
        DateTime.tryParse(ultima['completada_en'] as String? ?? '');
    if (ultimaFecha == null) return;
    final diasInactivo = DateTime.now().difference(ultimaFecha).inDays;

    if (diasInactivo > 14) {
      await _insertarRecomendacion(
        usuarioId: usuarioId,
        tipo: 'descarga',
        titulo: 'Volviste despues de $diasInactivo dias',
        descripcion:
            'Retoma con el 80% de tu carga habitual para evitar agujetas severas.',
        datos: {'dias_inactivo': diasInactivo, 'factor_carga': 0.80},
      );
    }
  }

  Future<void> generarAlertaFatiga({
    required String usuarioId,
    required int puntuacionFatiga,
    required bool requiereAdaptacion,
  }) async {
    if (!requiereAdaptacion) return;

    try {
      await _client.from('notificaciones').insert({
        'usuario_id': usuarioId,
        'titulo': 'Fatiga acumulada detectada',
        'descripcion':
            'Tu puntuacion de fatiga es $puntuacionFatiga/100. Considera una sesion mas ligera o un dia de descanso.',
        'prioridad': 'recommended',
        'tipo': 'fatigue_alert',
      });
    } catch (_) {
      // notification delivery failure is non-critical
    }
  }

  Future<void> _insertarRecomendacion({
    required String usuarioId,
    String? ejercicioId,
    String? rutinaId,
    required String tipo,
    required String titulo,
    String? descripcion,
    Map<String, dynamic> datos = const {},
  }) async {
    await _client.from('recomendaciones_pendientes').insert({
      'usuario_id': usuarioId,
      'tipo': tipo,
      'titulo': titulo,
      'descripcion': descripcion,
      'ejercicio_id': ejercicioId,
      'rutina_id': rutinaId,
      'datos': datos,
    });
  }
}
