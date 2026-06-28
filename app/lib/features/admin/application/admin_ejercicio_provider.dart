import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_ejercicio_dto.dart';
import '../infrastructure/admin_ejercicio_repository.dart';
import 'admin_auditoria_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio
// ─────────────────────────────────────────────────────────────────────────────

/// Proveedor del repositorio de ejercicios.
final adminEjercicioRepositoryProvider =
    Provider<AdminEjercicioRepository>((ref) {
  return AdminEjercicioRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Listado paginado de ejercicios con búsqueda
// ─────────────────────────────────────────────────────────────────────────────

/// Lista de ejercicios del catálogo con paginación y búsqueda por nombre.
/// El parámetro [params] incluye la página y la consulta de búsqueda.
final adminEjerciciosProvider =
    FutureProvider.family<List<AdminEjercicio>, ({int page, String query})>(
        (ref, params) async {
  final repo = ref.watch(adminEjercicioRepositoryProvider);
  return repo.listarEjercicios(page: params.page, query: params.query);
});

// ─────────────────────────────────────────────────────────────────────────────
// Acciones de gestión de ejercicios (mutaciones)
// ─────────────────────────────────────────────────────────────────────────────

/// Activa o desactiva un ejercicio en el catálogo, registrando la acción en
/// auditoría.
Future<void> toggleEjercicioActivo(
  WidgetRef ref, {
  required String id,
  required String nombre,
  required bool activo,
}) async {
  final repo = ref.read(adminEjercicioRepositoryProvider);
  await repo.toggleActivo(id, activo);
  ref.invalidate(adminEjerciciosProvider);
  await registrarAuditoria(
    ref,
    accion: activo ? 'activar_ejercicio' : 'desactivar_ejercicio',
    entidad: 'ejercicios',
    entidadId: id,
    detalle: {'nombre': nombre, 'activo': activo},
  );
}

/// Actualiza los campos editables de un ejercicio (nombre, dificultad,
/// modalidad_entrenamiento).
Future<void> actualizarEjercicio(
  WidgetRef ref, {
  required String id,
  String? nombre,
  String? dificultad,
  String? modalidadEntrenamiento,
}) async {
  final repo = ref.read(adminEjercicioRepositoryProvider);
  await repo.actualizarEjercicio(
    id,
    nombre: nombre,
    dificultad: dificultad,
    modalidadEntrenamiento: modalidadEntrenamiento,
  );
  ref.invalidate(adminEjerciciosProvider);
  await registrarAuditoria(
    ref,
    accion: 'editar_ejercicio',
    entidad: 'ejercicios',
    entidadId: id,
    detalle: {
      'nombre': nombre,
      'dificultad': dificultad,
      'modalidad': modalidadEntrenamiento
    },
  );
}
