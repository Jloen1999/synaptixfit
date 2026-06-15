import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_dto.dart';
import '../infrastructure/admin_repository.dart';

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
// Listado de usuarios (con búsqueda)
// ─────────────────────────────────────────────────────────────────────────────

/// Lista paginada de usuarios filtrada por [query] (email o nombre).
final adminUsuariosProvider =
    FutureProvider.family<List<UsuarioAdmin>, String>((ref, query) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listarUsuarios(query: query);
});

// ─────────────────────────────────────────────────────────────────────────────
// Detalle completo de un usuario
// ─────────────────────────────────────────────────────────────────────────────

/// Obtiene el perfil completo y conteos de actividad de un usuario.
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
}
