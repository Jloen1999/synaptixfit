import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_auditoria_dto.dart';
import '../infrastructure/admin_auditoria_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio
// ─────────────────────────────────────────────────────────────────────────────

/// Proveedor del repositorio de auditoría.
final adminAuditoriaRepositoryProvider =
    Provider<AdminAuditoriaRepository>((ref) {
  return AdminAuditoriaRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Listado paginado de auditoría
// ─────────────────────────────────────────────────────────────────────────────

/// Registros de auditoría paginados. El parámetro [page] controla el offset.
final adminAuditoriaProvider =
    FutureProvider.family<List<AuditoriaRegistro>, int>((ref, page) async {
  final repo = ref.watch(adminAuditoriaRepositoryProvider);
  return repo.listarAuditoria(page: page);
});

// ─────────────────────────────────────────────────────────────────────────────
// Helper para registrar auditoría desde cualquier mutación
// ─────────────────────────────────────────────────────────────────────────────

/// Registra una acción de auditoría de forma asíncrona e invalida el listado
/// para refrescar la UI.
Future<void> registrarAuditoria(
  WidgetRef ref, {
  required String accion,
  required String entidad,
  String? entidadId,
  Map<String, dynamic>? detalle,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  final repo = ref.read(adminAuditoriaRepositoryProvider);
  await repo.registrarAccion(
    adminId: userId,
    accion: accion,
    entidad: entidad,
    entidadId: entidadId,
    detalle: detalle,
  );
  ref.invalidate(adminAuditoriaProvider);
}
