import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_contenido_dto.dart';
import '../infrastructure/admin_contenido_repository.dart';
import 'admin_auditoria_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio
// ─────────────────────────────────────────────────────────────────────────────

/// Proveedor del repositorio de contenido reportado.
final adminContenidoRepositoryProvider =
    Provider<AdminContenidoRepository>((ref) {
  return AdminContenidoRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Listado paginado de contenido reportado
// ─────────────────────────────────────────────────────────────────────────────

/// Contenido reportado pendiente de moderación. El parámetro [page] controla
/// el offset de paginación.
final adminContenidoReportadoProvider =
    FutureProvider.family<List<ContenidoReportado>, int>((ref, page) async {
  final repo = ref.watch(adminContenidoRepositoryProvider);
  return repo.listarContenidoReportado(page: page);
});

// ─────────────────────────────────────────────────────────────────────────────
// Acciones de moderación (mutaciones)
// ─────────────────────────────────────────────────────────────────────────────

/// Aprueba el contenido reportado, quitando la bandera de reportado y
/// registrando la acción en auditoría.
Future<void> aprobarContenido(
  WidgetRef ref, {
  required ContenidoTipo tipo,
  required String id,
  required String autorId,
}) async {
  final repo = ref.read(adminContenidoRepositoryProvider);
  await repo.aprobarContenido(tipo, id);
  ref.invalidate(adminContenidoReportadoProvider);
  await registrarAuditoria(
    ref,
    accion: 'aprobar_contenido',
    entidad: tipo == ContenidoTipo.actividad
        ? 'actividades_sociales'
        : 'comentarios_feed',
    entidadId: id,
    detalle: {'autor_id': autorId},
  );
}

/// Elimina (o aplica soft delete) al contenido reportado y registra la acción
/// en auditoría.
Future<void> eliminarContenido(
  WidgetRef ref, {
  required ContenidoTipo tipo,
  required String id,
  required String autorId,
}) async {
  final repo = ref.read(adminContenidoRepositoryProvider);
  await repo.eliminarContenido(tipo, id);
  ref.invalidate(adminContenidoReportadoProvider);
  await registrarAuditoria(
    ref,
    accion: 'eliminar_contenido',
    entidad: tipo == ContenidoTipo.actividad
        ? 'actividades_sociales'
        : 'comentarios_feed',
    entidadId: id,
    detalle: {'autor_id': autorId},
  );
}
