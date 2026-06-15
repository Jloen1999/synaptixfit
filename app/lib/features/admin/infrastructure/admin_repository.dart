import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_dto.dart';

/// Repositorio de administración.
///
/// Centraliza todas las consultas y mutaciones que requieren privilegios
/// de administrador (rol = 'admin'). Las políticas RLS en Supabase
/// garantizan que solo los administradores puedan ejecutar estas operaciones.
class AdminRepository {
  final SupabaseClient _client;

  const AdminRepository(this._client);

  // ─────────────────────────────────────────────────────────────────────────
  // Listado paginado con búsqueda
  // ─────────────────────────────────────────────────────────────────────────

  /// Lista usuarios con búsqueda por email o nombre, paginado de 20 en 20.
  ///
  /// [query] permite filtrar por coincidencia parcial en email o nombre.
  /// [page] controla el offset (página 0 = primeros 20 resultados).
  Future<List<UsuarioAdmin>> listarUsuarios({
    String query = '',
    int page = 0,
  }) async {
    final normalized = query.trim();
    final select = _client.from('usuarios').select(
          'id, email, nombre_completo, url_avatar, rol, nivel, xp_total, racha_actual, creado_en',
        );

    if (normalized.isNotEmpty) {
      select.or(
        'email.ilike.%$normalized%,nombre_completo.ilike.%$normalized%',
      );
    }

    final response = await select
        .order('creado_en', ascending: false)
        .limit(20)
        .range(page * 20, (page + 1) * 20 - 1)
        .timeout(const Duration(seconds: 10));

    return (response as List<dynamic>)
        .map((r) => UsuarioAdmin.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Detalle completo de un usuario
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene el perfil completo de un usuario con conteos agregados.
  ///
  /// Realiza una consulta principal al usuario con LEFT JOIN a tablas
  /// de perfil, y subconsultas COUNT para obtener totales de actividad.
  Future<Map<String, dynamic>> obtenerDetalleUsuario(String usuarioId) async {
    // Consulta principal: datos del usuario + perfiles
    final userData = await _client
        .from('usuarios')
        .select('''
          id, email, nombre_completo, url_avatar, rol,
          nivel, xp_total, racha_actual, creado_en, actualizado_en,
          perfil_bienestar_usuario!left(peso_kg, altura_cm, objetivo_principal),
          perfil_academico_usuario!left(carrera, semestre_actual)
        ''')
        .eq('id', usuarioId)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (userData == null) {
      throw Exception('Usuario no encontrado');
    }

    final data = userData;

    // Subconsultas para conteos (ejecutadas en paralelo)
    // Se usa limit(0) + count('exact') para obtener solo el total sin traer filas.
    final conteosSesiones = await _client
        .from('sesiones_registradas')
        .select('id')
        .eq('usuario_id', usuarioId)
        .limit(0)
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 10));

    final conteosRutinas = await _client
        .from('rutinas')
        .select('id')
        .eq('usuario_id', usuarioId)
        .limit(0)
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 10));

    final conteosRetos = await _client
        .from('retos')
        .select('id')
        .eq('usuario_id', usuarioId)
        .limit(0)
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 10));

    final conteosInsignias = await _client
        .from('usuario_insignias')
        .select('id')
        .eq('usuario_id', usuarioId)
        .limit(0)
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 10));

    data['_conteos'] = {
      'sesiones': conteosSesiones.count,
      'rutinas': conteosRutinas.count,
      'retos': conteosRetos.count,
      'insignias': conteosInsignias.count,
    };

    return data;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Wipe de datos de usuario
  // ─────────────────────────────────────────────────────────────────────────

  /// Invoca la RPC `wipe_user_data` que elimina el historial completo
  /// del usuario y resetea sus valores dinámicos, conservando perfil.
  Future<Map<String, dynamic>> wipeUserData(String usuarioId) async {
    final result = await _client.rpc(
      'wipe_user_data',
      params: {'p_usuario_id': usuarioId},
    );
    // La respuesta viene como objeto JSON, riverpod lo maneja como Map
    if (result == null) throw Exception('Error al ejecutar wipe');
    return result as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cambio de rol
  // ─────────────────────────────────────────────────────────────────────────

  /// Actualiza el rol de un usuario (solo 'usuario' o 'admin').
  Future<void> cambiarRol(String usuarioId, String nuevoRol) async {
    await _client
        .from('usuarios')
        .update({'rol': nuevoRol})
        .eq('id', usuarioId)
        .timeout(const Duration(seconds: 10));
  }
}
