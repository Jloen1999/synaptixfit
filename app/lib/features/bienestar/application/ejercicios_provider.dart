import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';
import '../infrastructure/ejercicios_repository.dart';

// ---------------------------------------------------------------------------
// Provider del repositorio (singleton vía Riverpod)
// ---------------------------------------------------------------------------

final ejerciciosRepositoryProvider = Provider<EjerciciosRepository>((ref) {
  return EjerciciosRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Provider de ejercicios con sincronización en tiempo real (StreamProvider)
// Escucha cambios en la tabla ejercicios y re-emite la vista completa.
// ---------------------------------------------------------------------------

final ejerciciosProvider = StreamProvider<List<EjercicioDb>>((ref) async* {
  final repo = ref.read(ejerciciosRepositoryProvider);
  final client = Supabase.instance.client;

  // Carga inicial
  yield await repo.fetchAll();

  // Escucha cambios en tiempo real usando el stream de la tabla base.
  // Cuando se detecta un INSERT/UPDATE/DELETE se re-consulta la vista
  // denormalizada para obtener los datos frescos.
  final cambios = client.from('ejercicios').stream(primaryKey: ['id']);

  await for (final _ in cambios) {
    yield await repo.fetchAll();
  }
});

// ---------------------------------------------------------------------------
// Provider de catálogos (partes del cuerpo, músculos, equipamientos)
// ---------------------------------------------------------------------------

final catalogosProvider =
    FutureProvider.autoDispose<CatalogosEjercicios>((ref) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchCatalogos();
});

// ---------------------------------------------------------------------------
// Provider de ejercicio individual por ID
// ---------------------------------------------------------------------------

final ejercicioDetalleProvider =
    FutureProvider.autoDispose.family<EjercicioDb?, String>((ref, id) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchById(id);
});

// ---------------------------------------------------------------------------
// Provider de ejercicios filtrados por parte del cuerpo
// ---------------------------------------------------------------------------

final ejerciciosPorParteCuerpoProvider =
    FutureProvider.autoDispose.family<List<EjercicioDb>, String>(
        (ref, parte) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchByParteCuerpo(parte);
});

// ---------------------------------------------------------------------------
// Provider de búsqueda de ejercicios
// ---------------------------------------------------------------------------

final busquedaEjerciciosProvider =
    FutureProvider.autoDispose.family<List<EjercicioDb>, String>(
        (ref, query) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.buscar(query);
});
