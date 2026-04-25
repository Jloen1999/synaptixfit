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
// Provider de ejercicios (lista completa)
// ---------------------------------------------------------------------------

final ejerciciosProvider = FutureProvider<List<EjercicioDb>>((ref) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchAll();
});

// ---------------------------------------------------------------------------
// Provider de catálogos (partes del cuerpo, músculos, equipamientos)
// ---------------------------------------------------------------------------

final catalogosProvider = FutureProvider<CatalogosEjercicios>((ref) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchCatalogos();
});

// ---------------------------------------------------------------------------
// Provider de ejercicio individual por ID
// ---------------------------------------------------------------------------

final ejercicioDetalleProvider =
    FutureProvider.family<EjercicioDb?, String>((ref, id) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchById(id);
});

// ---------------------------------------------------------------------------
// Provider de ejercicios filtrados por parte del cuerpo
// ---------------------------------------------------------------------------

final ejerciciosPorParteCuerpoProvider =
    FutureProvider.family<List<EjercicioDb>, String>((ref, parte) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchByParteCuerpo(parte);
});

// ---------------------------------------------------------------------------
// Provider de búsqueda de ejercicios
// ---------------------------------------------------------------------------

final busquedaEjerciciosProvider =
    FutureProvider.family<List<EjercicioDb>, String>((ref, query) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.buscar(query);
});
