import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_kpi_dto.dart';

/// Repositorio para métricas globales del panel de administración.
///
/// Consulta la vista [v_admin_metricas] para KPIs agregados y genera
/// series temporales de registros diarios para gráficos.
class AdminMetricasRepository {
  final SupabaseClient _client;

  const AdminMetricasRepository(this._client);

  /// Obtiene las métricas globales desde la vista [v_admin_metricas].
  Future<AdminMetricasGlobales> obtenerMetricas() async {
    final data = await _client
        .from('v_admin_metricas')
        .select()
        .single()
        .timeout(const Duration(seconds: 10));
    return AdminMetricasGlobales.fromMap(data);
  }

  /// Devuelve el conteo de sesiones diarias para los últimos [dias] días.
  ///
  /// Retorna una lista de mapas con formato `{'fecha': 'YYYY-MM-DD', 'count': N}`,
  /// ordenada cronológicamente.
  Future<List<Map<String, dynamic>>> obtenerRegistrosDiarios(int dias) async {
    final desde = DateTime.now().subtract(Duration(days: dias));
    final data = await _client
        .from('sesiones_registradas')
        .select('completada_en')
        .gte('completada_en', desde.toIso8601String())
        .timeout(const Duration(seconds: 10));

    final agrupado = <String, int>{};
    for (final row in data) {
      final fecha = (row['completada_en'] as String).substring(0, 10);
      agrupado[fecha] = (agrupado[fecha] ?? 0) + 1;
    }
    return agrupado.entries
        .map((e) => {'fecha': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));
  }
}
