import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_timeline_dto.dart';
import '../domain/admin_usuario_estadisticas_dto.dart';

/// Repositorio para estadísticas y línea de tiempo de usuarios desde el panel
/// de administración.
///
/// Consulta las vistas analíticas y tablas de actividad para construir gráficos
/// de rendimiento y la línea de tiempo de cada usuario.
class AdminUsuarioStatsRepository {
  final SupabaseClient _client;

  const AdminUsuarioStatsRepository(this._client);

  /// Obtiene la serie temporal de RPE promedio semanal para un usuario.
  Future<List<AdminDataPoint>> obtenerRpeSemanal(
    String usuarioId, {
    int semanas = 12,
  }) async {
    final desde = DateTime.now().subtract(Duration(days: semanas * 7));
    final data = await _client
        .from('v_analitica_semanal')
        .select('semana_inicio, rpe_promedio')
        .eq('usuario_id', usuarioId)
        .gte('semana_inicio', desde.toIso8601String().substring(0, 10))
        .order('semana_inicio')
        .timeout(const Duration(seconds: 10));

    return (data as List).map((r) {
      final map = r as Map<String, dynamic>;
      return AdminDataPoint(
        fecha: DateTime.parse(map['semana_inicio'] as String),
        valor: (map['rpe_promedio'] as num?)?.toDouble() ?? 0,
        etiqueta: 'RPE',
      );
    }).toList();
  }

  /// Obtiene la serie temporal de volumen en minutos semanal para un usuario.
  Future<List<AdminDataPoint>> obtenerVolumenSemanal(
    String usuarioId, {
    int semanas = 12,
  }) async {
    final desde = DateTime.now().subtract(Duration(days: semanas * 7));
    final data = await _client
        .from('v_analitica_semanal')
        .select('semana_inicio, volumen_minutos')
        .eq('usuario_id', usuarioId)
        .gte('semana_inicio', desde.toIso8601String().substring(0, 10))
        .order('semana_inicio')
        .timeout(const Duration(seconds: 10));

    return (data as List).map((r) {
      final map = r as Map<String, dynamic>;
      return AdminDataPoint(
        fecha: DateTime.parse(map['semana_inicio'] as String),
        valor: (map['volumen_minutos'] as num?)?.toDouble() ?? 0,
        etiqueta: 'Minutos',
      );
    }).toList();
  }

  /// Construye la línea de tiempo de un usuario combinando sesiones, retos
  /// completados y registros de auditoría (cambios de rol, wipes).
  Future<List<AdminTimelineEntry>> obtenerTimeline(
    String usuarioId, {
    int page = 0,
    int limit = 30,
  }) async {
    final results = <AdminTimelineEntry>[];
    final cuarto = limit ~/ 4;

    // Sesiones registradas
    final sesiones = await _client
        .from('sesiones_registradas')
        .select('completada_en, duracion_minutos')
        .eq('usuario_id', usuarioId)
        .order('completada_en', ascending: false)
        .range(page * cuarto, (page + 1) * cuarto - 1)
        .timeout(const Duration(seconds: 10));

    for (final map in sesiones) {
      final duracion = map['duracion_minutos'];
      results.add(AdminTimelineEntry(
        fecha: DateTime.parse(map['completada_en'] as String),
        tipo: TimelineTipoAdmin.sesion,
        descripcion: 'Sesión de ${duracion ?? '?'} min',
      ));
    }

    // Retos completados
    final retos = await _client
        .from('retos')
        .select('titulo, creado_en')
        .eq('usuario_id', usuarioId)
        .eq('esta_completado', true)
        .order('creado_en', ascending: false)
        .limit(cuarto)
        .timeout(const Duration(seconds: 10));

    for (final map in retos) {
      results.add(AdminTimelineEntry(
        fecha: DateTime.parse(map['creado_en'] as String),
        tipo: TimelineTipoAdmin.reto,
        descripcion: 'Reto: ${map['titulo']}',
      ));
    }

    // Auditoría (cambios de rol, wipes)
    final auditoria = await _client
        .from('admin_auditoria')
        .select('accion, entidad, creado_en')
        .eq('entidad_id', usuarioId)
        .order('creado_en', ascending: false)
        .limit(cuarto)
        .timeout(const Duration(seconds: 10));

    for (final map in auditoria) {
      final accion = map['accion'] as String;
      results.add(AdminTimelineEntry(
        fecha: DateTime.parse(map['creado_en'] as String),
        tipo: accion == 'wipe'
            ? TimelineTipoAdmin.wipe
            : TimelineTipoAdmin.rolCambio,
        descripcion: accion == 'wipe' ? 'Wipe de datos' : 'Cambio de rol',
      ));
    }

    results.sort((a, b) => b.fecha.compareTo(a.fecha));
    return results.take(limit).toList();
  }
}
