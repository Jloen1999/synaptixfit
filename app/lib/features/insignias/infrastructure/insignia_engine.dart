import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/insignia_dto.dart';
import 'insignias_repository.dart';

/// Motor de reglas que evalúa criterios y otorga insignias automáticamente.
class InsigniaEngine {
  final SupabaseClient _client;

  const InsigniaEngine(this._client);

  /// Evalúa todos los criterios para un usuario.
  /// Retorna la lista de insignias recién obtenidas (nuevas).
  Future<List<Insignia>> evaluarYOtorgar(String usuarioId) async {
    final repo = InsigniasRepository(_client);

    // 1. Obtener catálogo e insignias que ya tiene
    final catalogo = await repo.obtenerCatalogo(usuarioId);
    final pendientes = catalogo.where((i) => !i.obtenida).toList();

    if (pendientes.isEmpty) return [];

    // 2. Obtener métricas actuales del usuario
    final metricas = await _obtenerMetricas(usuarioId);

    // 3. Evaluar cada insignia pendiente
    final otorgadas = <Insignia>[];
    for (final insignia in pendientes) {
      final valorActual = metricas[insignia.criterioTipo] ?? 0;
      if (valorActual >= insignia.criterioValor) {
        final otorgada = await repo.otorgarInsignia(usuarioId, insignia.id);
        if (otorgada) {
          otorgadas.add(insignia);
          debugPrint(
              '[InsigniaEngine] 🏅 Otorgada: ${insignia.nombre} (${insignia.criterioTipo}=$valorActual >= ${insignia.criterioValor})');
        }
      }
    }

    return otorgadas;
  }

  /// Obtiene todas las métricas del usuario en una sola pasada.
  Future<Map<String, int>> _obtenerMetricas(String usuarioId) async {
    final metricas = <String, int>{};

    try {
      // --- Sesiones completadas ---
      final sesionesData = await _client
          .from('sesiones_registradas')
          .select('id')
          .eq('usuario_id', usuarioId);
      metricas['sesiones_completadas'] = (sesionesData as List).length;

      // --- RPE alto (>= 8) ---
      final rpeData = await _client
          .from('sesiones_registradas')
          .select('id')
          .eq('usuario_id', usuarioId)
          .gte('rpe', 8);
      metricas['rpe_alto'] = (rpeData as List).length;

      // --- Check-ins consecutivos (estado_diario_usuario) ---
      final checkinsData = await _client
          .from('estado_diario_usuario')
          .select('fecha')
          .eq('usuario_id', usuarioId)
          .order('fecha', ascending: false);
      metricas['checkins_consecutivos'] =
          _contarConsecutivos(checkinsData as List);

      // --- Publicaciones en feed social ---
      final publicacionesData = await _client
          .from('actividades_sociales')
          .select('id')
          .eq('usuario_id', usuarioId);
      metricas['publicaciones_feed'] = (publicacionesData as List).length;

      // --- Likes recibidos (interacciones tipo 'like' en actividades del usuario) ---
      final misActividades = await _client
          .from('actividades_sociales')
          .select('id')
          .eq('usuario_id', usuarioId);
      final misIds = (misActividades as List)
          .map((r) => (r as Map)['id'] as String)
          .toList();

      if (misIds.isNotEmpty) {
        final likesData = await _client
            .from('interacciones_sociales')
            .select('id')
            .inFilter('actividad_id', misIds)
            .eq('tipo_interaccion', 'like');
        metricas['likes_recibidos'] = (likesData as List).length;
      } else {
        metricas['likes_recibidos'] = 0;
      }

      // --- Retos completados ---
      final retosData = await _client
          .from('retos')
          .select('id')
          .eq('usuario_id', usuarioId)
          .eq('esta_completado', true);
      metricas['retos_completados'] = (retosData as List).length;

      // --- Insignias ya obtenidas (para "Coleccionista") ---
      final insigniasData = await _client
          .from('usuario_insignias')
          .select('id')
          .eq('usuario_id', usuarioId);
      metricas['insignias_obtenidas'] = (insigniasData as List).length;

      // --- Racha de días (sesiones_registradas) ---
      final sesionesFechas = await _client
          .from('sesiones_registradas')
          .select('completada_en')
          .eq('usuario_id', usuarioId)
          .order('completada_en', ascending: false);
      metricas['racha_dias'] = _contarRachaSesiones(sesionesFechas as List);

      // --- Bloques de estudio (horarios_academicos) ---
      final bloquesData = await _client
          .from('horarios_academicos')
          .select('id')
          .eq('usuario_id', usuarioId)
          .eq('tipo_actividad', 'estudio');
      metricas['bloques_estudio'] = (bloquesData as List).length;

      // --- Planes de estudio ---
      final planesData = await _client
          .from('planes_estudio')
          .select('id')
          .eq('usuario_id', usuarioId);
      metricas['planes_estudio'] = (planesData as List).length;

      // --- Apuntes creados ---
      final apuntesData = await _client
          .from('apuntes')
          .select('id')
          .eq('usuario_id', usuarioId);
      metricas['apuntes_creados'] = (apuntesData as List).length;
    } catch (e) {
      debugPrint('[InsigniaEngine] Error obteniendo métricas: $e');
    }

    return metricas;
  }

  /// Cuenta días consecutivos hacia atrás desde hoy en la lista de fechas.
  static int _contarConsecutivos(List<dynamic> rows) {
    if (rows.isEmpty) return 0;

    final fechas = rows
        .map((r) {
          final f = (r as Map<String, dynamic>)['fecha'];
          if (f == null) return null;
          final dt = DateTime.tryParse(f.toString());
          return dt != null ? DateTime(dt.year, dt.month, dt.day) : null;
        })
        .where((d) => d != null)
        .cast<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (fechas.isEmpty) return 0;

    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final ayer = hoyFecha.subtract(const Duration(days: 1));

    if (fechas.first != hoyFecha && fechas.first != ayer) {
      return 0;
    }

    int consecutivos = 1;
    for (int i = 1; i < fechas.length; i++) {
      final diff = fechas[i - 1].difference(fechas[i]).inDays;
      if (diff == 1) {
        consecutivos++;
      } else {
        break;
      }
    }
    return consecutivos;
  }

  /// Calcula racha de días con sesión de entrenamiento.
  static int _contarRachaSesiones(List<dynamic> rows) {
    if (rows.isEmpty) return 0;

    final fechas = rows
        .map((r) {
          final f = (r as Map<String, dynamic>)['completada_en'];
          if (f == null) return null;
          final dt = DateTime.tryParse(f.toString());
          return dt != null ? DateTime(dt.year, dt.month, dt.day) : null;
        })
        .where((d) => d != null)
        .cast<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (fechas.isEmpty) return 0;

    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final ayer = hoyFecha.subtract(const Duration(days: 1));

    if (fechas.first != hoyFecha && fechas.first != ayer) {
      return 0;
    }

    int consecutivos = (fechas.first == hoyFecha) ? 1 : 0;
    final inicio = (fechas.first == hoyFecha) ? 1 : 0;
    for (int i = inicio; i < fechas.length; i++) {
      final anterior = i > 0 ? fechas[i - 1] : hoyFecha;
      final diff = anterior.difference(fechas[i]).inDays;
      if (diff == 1) {
        consecutivos++;
      } else {
        break;
      }
    }
    return consecutivos;
  }
}
