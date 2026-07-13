import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_dto.dart';
import '../infrastructure/admin_repository.dart';
import 'admin_auditoria_provider.dart';
import 'admin_metricas_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio
// ─────────────────────────────────────────────────────────────────────────────

/// Proveedor del repositorio de administración.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Verificación de rol admin
// ─────────────────────────────────────────────────────────────────────────────

/// Determina si el usuario autenticado actual tiene rol de administrador.
final esAdminProvider = FutureProvider<bool>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return false;
  try {
    final data = await client
        .from('usuarios')
        .select('rol')
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
    return data != null && data['rol'] == 'admin';
  } catch (_) {
    return false;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Parámetros de filtro y ordenamiento
// ─────────────────────────────────────────────────────────────────────────────

/// Parámetros combinados para el listado de usuarios:
/// búsqueda textual, filtro de rol, campo de orden y dirección.
class AdminFiltrosParams {
  final String query;
  final String rolFiltro;
  final String ordenarPor;
  final bool ascendente;

  const AdminFiltrosParams({
    this.query = '',
    this.rolFiltro = 'todos',
    this.ordenarPor = 'creado_en',
    this.ascendente = false,
  });

  @override
  bool operator ==(Object other) =>
      other is AdminFiltrosParams &&
      other.query == query &&
      other.rolFiltro == rolFiltro &&
      other.ordenarPor == ordenarPor &&
      other.ascendente == ascendente;

  @override
  int get hashCode => Object.hash(query, rolFiltro, ordenarPor, ascendente);
}

// ─────────────────────────────────────────────────────────────────────────────
// Listado de usuarios (con búsqueda, filtros y ordenamiento)
// ─────────────────────────────────────────────────────────────────────────────

/// Lista paginada de usuarios filtrada y ordenada según [params].
final adminUsuariosProvider =
    FutureProvider.family<List<UsuarioAdmin>, AdminFiltrosParams>(
        (ref, params) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listarUsuarios(
    query: params.query,
    rolFiltro: params.rolFiltro,
    ordenarPor: params.ordenarPor,
    ascendente: params.ascendente,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Detalle completo de un usuario
// ─────────────────────────────────────────────────────────────────────────────

/// Obtiene el perfil completo, conteos de actividad y datos recientes
/// (sesiones, retos, insignias, rutinas) de un usuario.
final adminUsuarioDetalleProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.obtenerDetalleUsuario(id);
});

// ─────────────────────────────────────────────────────────────────────────────
// Acciones de administración (mutaciones)
// ─────────────────────────────────────────────────────────────────────────────

/// Ejecuta el wipe de datos de un usuario y refresca el listado.
Future<Map<String, dynamic>> wipeUserData(
  WidgetRef ref,
  String usuarioId,
) async {
  final repo = ref.read(adminRepositoryProvider);
  final result = await repo.wipeUserData(usuarioId);
  // Invalidar todos los providers relacionados para refrescar la UI
  ref.invalidate(adminUsuariosProvider);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  registrarAuditoria(
    ref,
    accion: 'wipe',
    entidad: 'usuarios',
    entidadId: usuarioId,
  );
  return result;
}

/// Cambia el rol de un usuario y refresca el listado.
Future<void> cambiarRolUsuario(
  WidgetRef ref,
  String usuarioId,
  String nuevoRol,
) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.cambiarRol(usuarioId, nuevoRol);
  ref.invalidate(adminUsuariosProvider);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  await registrarAuditoria(
    ref,
    accion: 'cambiar_rol',
    entidad: 'usuarios',
    entidadId: usuarioId,
    detalle: {'nuevo_rol': nuevoRol},
  );
}

/// Elimina permanentemente un usuario y todos sus datos.
/// Registra auditoría y redirige al panel de administración.
Future<Map<String, dynamic>> eliminarUsuario(
  WidgetRef ref,
  String usuarioId,
) async {
  final repo = ref.read(adminRepositoryProvider);
  final result = await repo.deleteUser(usuarioId);
  ref.invalidate(adminUsuariosProvider);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  await registrarAuditoria(
    ref,
    accion: 'eliminar_usuario',
    entidad: 'usuarios',
    entidadId: usuarioId,
    detalle: {'email': result['email']},
  );
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Configuración de usuario desde admin
// ─────────────────────────────────────────────────────────────────────────────

/// Actualiza el nombre completo de un usuario desde el panel admin.
Future<void> actualizarNombreUsuario(
  WidgetRef ref,
  String usuarioId,
  String nuevoNombre,
) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.actualizarNombre(usuarioId, nuevoNombre);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  ref.invalidate(adminUsuariosProvider);
  await registrarAuditoria(
    ref,
    accion: 'actualizar_nombre',
    entidad: 'usuarios',
    entidadId: usuarioId,
    detalle: {'nombre': nuevoNombre},
  );
}

/// Actualiza el email de un usuario desde el panel admin.
Future<void> actualizarEmailUsuario(
  WidgetRef ref,
  String usuarioId,
  String nuevoEmail,
) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.actualizarEmail(usuarioId, nuevoEmail);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  ref.invalidate(adminUsuariosProvider);
  await registrarAuditoria(
    ref,
    accion: 'actualizar_email',
    entidad: 'usuarios',
    entidadId: usuarioId,
    detalle: {'email': nuevoEmail},
  );
}

/// Resetea el XP total de un usuario a 0 desde el panel admin.
Future<void> resetXpUsuario(
  WidgetRef ref,
  String usuarioId,
) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.resetXp(usuarioId);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  ref.invalidate(adminUsuariosProvider);
  await registrarAuditoria(
    ref,
    accion: 'reset_xp',
    entidad: 'usuarios',
    entidadId: usuarioId,
  );
}

/// Cambia manualmente el nivel de un usuario desde el panel admin.
Future<void> cambiarNivelUsuario(
  WidgetRef ref,
  String usuarioId,
  int nuevoNivel,
) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.cambiarNivel(usuarioId, nuevoNivel);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  ref.invalidate(adminUsuariosProvider);
  await registrarAuditoria(
    ref,
    accion: 'cambiar_nivel',
    entidad: 'usuarios',
    entidadId: usuarioId,
    detalle: {'nivel': nuevoNivel},
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shadowban (Trust & Safety)
// ─────────────────────────────────────────────────────────────────────────────

/// Activa o desactiva el shadowban para un usuario.
Future<void> toggleShadowbanUsuario(
  WidgetRef ref,
  String usuarioId,
  bool activar,
) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.toggleShadowban(usuarioId, activar);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  ref.invalidate(adminUsuariosProvider);
  await registrarAuditoria(
    ref,
    accion: activar ? 'activar_shadowban' : 'desactivar_shadowban',
    entidad: 'usuarios',
    entidadId: usuarioId,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Lockdown Mode (Modo Pánico)
// ─────────────────────────────────────────────────────────────────────────────

/// Provedor del estado de lockdown.
final lockdownStateProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getLockdownState();
});

/// Activa o desactiva el modo lockdown global.
Future<void> toggleLockdown(
  WidgetRef ref,
  bool activar,
) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.toggleLockdown(activar);
  ref.invalidate(lockdownStateProvider);
  ref.invalidate(adminMetricasProvider);
  await registrarAuditoria(
    ref,
    accion: activar ? 'activar_lockdown' : 'desactivar_lockdown',
    entidad: 'configuracion_global',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GDPR: Anonimización y Exportación
// ─────────────────────────────────────────────────────────────────────────────

/// Anonimiza permanentemente a un usuario preservando datos analíticos.
Future<Map<String, dynamic>> anonimizarUsuario(
  WidgetRef ref,
  String usuarioId,
) async {
  final repo = ref.read(adminRepositoryProvider);
  final result = await repo.anonymizeUser(usuarioId);
  ref.invalidate(adminUsuariosProvider);
  ref.invalidate(adminUsuarioDetalleProvider(usuarioId));
  await registrarAuditoria(
    ref,
    accion: 'anonimizar_usuario',
    entidad: 'usuarios',
    entidadId: usuarioId,
    detalle: {'email': result['email']},
  );
  return result;
}

/// Exporta todos los datos de un usuario en formato JSON.
Future<Map<String, dynamic>> exportarDatosUsuario(
  WidgetRef ref,
  String usuarioId,
) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.exportUserData(usuarioId);
}
