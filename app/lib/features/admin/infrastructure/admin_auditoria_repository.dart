import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_auditoria_dto.dart';

/// Repositorio de auditoría administrativa.
///
/// Permite consultar el historial de acciones realizadas por administradores
/// y registrar nuevas entradas cuando se ejecutan mutaciones sensibles.
class AdminAuditoriaRepository {
  final SupabaseClient _client;

  const AdminAuditoriaRepository(this._client);

  /// Lista los registros de auditoría de forma paginada, con el nombre del
  /// administrador que ejecutó cada acción.
  Future<List<AuditoriaRegistro>> listarAuditoria({
    int page = 0,
    int limit = 30,
  }) async {
    final data = await _client
        .from('admin_auditoria')
        .select('*, usuarios!admin_auditoria_admin_id_fkey(nombre_completo)')
        .order('creado_en', ascending: false)
        .range(page * limit, (page + 1) * limit - 1)
        .timeout(const Duration(seconds: 10));

    return (data as List).map((r) {
      final map = r as Map<String, dynamic>;
      final usuario = map['usuarios'] as Map<String, dynamic>?;
      return AuditoriaRegistro.fromMap({
        ...map,
        'admin_nombre': usuario?['nombre_completo'] as String?,
      });
    }).toList();
  }

  /// Registra una nueva acción de auditoría en la base de datos.
  Future<void> registrarAccion({
    required String adminId,
    required String accion,
    required String entidad,
    String? entidadId,
    Map<String, dynamic>? detalle,
  }) async {
    await _client.from('admin_auditoria').insert({
      'admin_id': adminId,
      'accion': accion,
      'entidad': entidad,
      'entidad_id': entidadId,
      'detalle': detalle ?? {},
    }).timeout(const Duration(seconds: 10));
  }
}
