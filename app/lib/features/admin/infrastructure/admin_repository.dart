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
  // Listado paginado con búsqueda, filtros y ordenamiento
  // ─────────────────────────────────────────────────────────────────────────

  /// Valores válidos para el filtro de rol en el listado de usuarios.
  static const rolesFiltro = ['todos', 'admin', 'usuario'];

  /// Valores válidos para el campo de ordenamiento.
  static const camposOrden = [
    'creado_en',
    'nivel',
    'xp_total',
    'racha_actual',
  ];

  /// Lista usuarios con búsqueda por email o nombre, filtro por rol y
  /// ordenamiento configurable, paginado de 20 en 20.
  ///
  /// [query] permite filtrar por coincidencia parcial en email o nombre.
  /// [rolFiltro] filtra por rol ('todos', 'admin', 'usuario').
  /// [ordenarPor] campo por el cual ordenar.
  /// [ascendente] dirección del ordenamiento.
  /// [page] controla el offset (página 0 = primeros 20 resultados).
  Future<List<UsuarioAdmin>> listarUsuarios({
    String query = '',
    String rolFiltro = 'todos',
    String ordenarPor = 'creado_en',
    bool ascendente = false,
    int page = 0,
  }) async {
    final normalized = query.trim();
    // Se usa dynamic para evitar conflicto de tipos entre
    // PostgrestFilterBuilder y PostgrestTransformBuilder al encadenar .or()
    // seguido de .eq() / .order().
    dynamic select = _client.from('usuarios').select(
          'id, email, nombre_completo, url_avatar, rol, nivel, xp_total, racha_actual, is_shadowbanned, creado_en',
        );

    // Filtro por búsqueda textual
    if (normalized.isNotEmpty) {
      select = select.or(
        'email.ilike.%$normalized%,nombre_completo.ilike.%$normalized%',
      );
    }

    // Filtro por rol
    if (rolFiltro == 'admin') {
      select = select.eq('rol', 'admin');
    } else if (rolFiltro == 'usuario') {
      select = select.eq('rol', 'usuario');
    }

    // Ordenamiento
    final campo = camposOrden.contains(ordenarPor) ? ordenarPor : 'creado_en';
    select = select.order(campo, ascending: ascendente);

    final response = await select
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

  /// Obtiene el perfil completo de un usuario con conteos agregados,
  /// últimas sesiones, retos, insignias y rutinas activas.
  ///
  /// Realiza una consulta principal al usuario con LEFT JOIN a tablas
  /// de perfil, y subconsultas para obtener totales y actividad reciente.
  Future<Map<String, dynamic>> obtenerDetalleUsuario(String usuarioId) async {
    // Consulta principal: datos del usuario + perfiles
    final userData = await _client
        .from('usuarios')
        .select('''
          id, email, nombre_completo, url_avatar, rol,
          nivel, xp_total, racha_actual, is_shadowbanned, creado_en, actualizado_en,
          perfil_bienestar_usuario!left(peso_kg, altura_cm, objetivo_principal, nivel_actividad, edad, sexo, imc, dias_disponibles_semana, minutos_por_sesion),
          perfil_academico_usuario!left(carrera, semestre_actual, universidad, modalidad, creditos_semestre_actual, horas_objetivo_estudio_semana, promedio_objetivo)
        ''')
        .eq('id', usuarioId)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (userData == null) {
      throw Exception('Usuario no encontrado');
    }

    final data = userData;

    // Subconsultas para conteos (ejecutadas en paralelo)
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

    // ── Actividad reciente ──

    // Últimas 5 sesiones
    final sesionesRecientes = await _client
        .from('sesiones_registradas')
        .select('completada_en, duracion_minutos')
        .eq('usuario_id', usuarioId)
        .order('completada_en', ascending: false)
        .limit(5)
        .timeout(const Duration(seconds: 10));

    data['_sesiones_recientes'] = sesionesRecientes;

    // Últimos 5 retos completados
    final retosRecientes = await _client
        .from('retos')
        .select('titulo, creado_en')
        .eq('usuario_id', usuarioId)
        .eq('esta_completado', true)
        .order('creado_en', ascending: false)
        .limit(5)
        .timeout(const Duration(seconds: 10));

    data['_retos_recientes'] = retosRecientes;

    // Últimas 5 insignias con nombre del catálogo
    final insigniasRecientes = await _client
        .from('usuario_insignias')
        .select('obtenida_en, insignia_id, insignias!inner(nombre, icono)')
        .eq('usuario_id', usuarioId)
        .order('obtenida_en', ascending: false)
        .limit(5)
        .timeout(const Duration(seconds: 10));

    data['_insignias_recientes'] = insigniasRecientes;

    // Últimas 5 rutinas activas
    final rutinasRecientes = await _client
        .from('rutinas')
        .select('nombre, creado_en')
        .eq('usuario_id', usuarioId)
        .order('creado_en', ascending: false)
        .limit(5)
        .timeout(const Duration(seconds: 10));

    data['_rutinas_recientes'] = rutinasRecientes;

    // Adherencia académica (últimas 4 semanas)
    try {
      final adherencia = await _client
          .from('carga_academica_semanal')
          .select(
              'semana_inicio, horas_estudio_planeadas, horas_estudio_reales')
          .eq('usuario_id', usuarioId)
          .order('semana_inicio', ascending: false)
          .limit(4)
          .timeout(const Duration(seconds: 8));
      double totalPlaneadas = 0;
      double totalReales = 0;
      for (final a in adherencia) {
        totalPlaneadas +=
            (a['horas_estudio_planeadas'] as num?)?.toDouble() ?? 0;
        totalReales += (a['horas_estudio_reales'] as num?)?.toDouble() ?? 0;
      }
      data['_adherencia'] = {
        'porcentaje': totalPlaneadas > 0
            ? ((totalReales / totalPlaneadas) * 100).round()
            : null,
        'semanas': adherencia.length,
      };
    } catch (_) {
      data['_adherencia'] = {'porcentaje': null, 'semanas': 0};
    }

    return data;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Eliminación permanente de usuario (hard delete)
  // ─────────────────────────────────────────────────────────────────────────

  /// Invoca la RPC `delete_user` que elimina permanentemente un usuario
  /// y todos sus datos dependientes en cascada.
  Future<Map<String, dynamic>> deleteUser(String usuarioId) async {
    final result = await _client.rpc(
      'delete_user',
      params: {'p_usuario_id': usuarioId},
    );
    if (result == null) throw Exception('Error al eliminar usuario');
    return result as Map<String, dynamic>;
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

  // ─────────────────────────────────────────────────────────────────────────
  // Configuración de usuario (Tarea 3c)
  // ─────────────────────────────────────────────────────────────────────────

  /// Actualiza el nombre completo de un usuario.
  Future<void> actualizarNombre(String usuarioId, String nuevoNombre) async {
    await _client
        .from('usuarios')
        .update({'nombre_completo': nuevoNombre})
        .eq('id', usuarioId)
        .timeout(const Duration(seconds: 10));
  }

  /// Actualiza el email de un usuario.
  Future<void> actualizarEmail(String usuarioId, String nuevoEmail) async {
    await _client
        .from('usuarios')
        .update({'email': nuevoEmail})
        .eq('id', usuarioId)
        .timeout(const Duration(seconds: 10));
  }

  /// Resetea el XP total de un usuario a 0.
  Future<void> resetXp(String usuarioId) async {
    await _client
        .from('usuarios')
        .update({'xp_total': 0})
        .eq('id', usuarioId)
        .timeout(const Duration(seconds: 10));
  }

  /// Cambia manualmente el nivel de un usuario.
  Future<void> cambiarNivel(String usuarioId, int nuevoNivel) async {
    await _client
        .from('usuarios')
        .update({'nivel': nuevoNivel})
        .eq('id', usuarioId)
        .timeout(const Duration(seconds: 10));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shadowban (Trust & Safety)
  // ─────────────────────────────────────────────────────────────────────────

  /// Activa o desactiva el shadowban para un usuario.
  Future<void> toggleShadowban(String usuarioId, bool activar) async {
    await _client
        .from('usuarios')
        .update({'is_shadowbanned': activar})
        .eq('id', usuarioId)
        .timeout(const Duration(seconds: 10));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lockdown Mode (Modo Pánico)
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene el estado actual del lockdown desde configuracion_global.
  Future<bool> getLockdownState() async {
    final data = await _client
        .from('configuracion_global')
        .select('lockdown_activo')
        .eq('id', true)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));
    return data?['lockdown_activo'] == true;
  }

  /// Activa o desactiva el modo lockdown y registra quién lo hizo.
  Future<void> toggleLockdown(bool activar) async {
    await _client
        .from('configuracion_global')
        .update({
          'lockdown_activo': activar,
          'lockdown_iniciado_en':
              activar ? DateTime.now().toUtc().toIso8601String() : null,
          'lockdown_iniciado_por':
              activar ? _client.auth.currentUser?.id : null,
        })
        .eq('id', true)
        .timeout(const Duration(seconds: 10));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GDPR: Anonimización y Exportación de Datos
  // ─────────────────────────────────────────────────────────────────────────

  /// Invoca la RPC anonymize_user para anonimizar permanentemente a un usuario
  /// preservando datos analíticos (GDPR Derecho al Olvido).
  Future<Map<String, dynamic>> anonymizeUser(String usuarioId) async {
    final result = await _client.rpc(
      'anonymize_user',
      params: {'p_usuario_id': usuarioId},
    );
    if (result == null) throw Exception('Error al anonimizar usuario');
    return result as Map<String, dynamic>;
  }

  /// Invoca la RPC exportar_datos_usuario para obtener todos los datos
  /// de un usuario en formato JSON (GDPR Derecho a la Portabilidad).
  Future<Map<String, dynamic>> exportUserData(String usuarioId) async {
    final result = await _client.rpc(
      'exportar_datos_usuario',
      params: {'p_usuario_id': usuarioId},
    );
    if (result == null) throw Exception('Error al exportar datos');
    return result as Map<String, dynamic>;
  }
}
