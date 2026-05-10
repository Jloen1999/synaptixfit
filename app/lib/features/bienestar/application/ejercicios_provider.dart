import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';
import '../infrastructure/ejercicios_repository.dart';

// ---------------------------------------------------------------------------
// DTO para filtro de ejercicios (cliente, sin red)
// ---------------------------------------------------------------------------

enum FiltroTipo { todos, parteCuerpo, musculo, equipamiento, busqueda }

class FiltroEjercicios {
  const FiltroEjercicios({this.tipo = FiltroTipo.todos, this.valor = ''});

  final FiltroTipo tipo;
  final String valor;
}

// ---------------------------------------------------------------------------
// Provider del repositorio (singleton vía Riverpod)
// ---------------------------------------------------------------------------

final ejerciciosRepositoryProvider = Provider<EjerciciosRepository>((ref) {
  return EjerciciosRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Capa 1 — Carga única (cache permanente, sin red en filtros)
// ---------------------------------------------------------------------------

final ejerciciosProvider = FutureProvider<List<EjercicioDb>>((ref) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchAll();
});

final catalogosProvider = FutureProvider<CatalogosEjercicios>((ref) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchCatalogos();
});

// ---------------------------------------------------------------------------
// Capa 2 — Filtrado en memoria (< 1ms, cero red)
// ---------------------------------------------------------------------------

final ejerciciosFiltradosProvider =
    Provider.family<List<EjercicioDb>, FiltroEjercicios>((ref, filtro) {
  final todos = ref.watch(ejerciciosProvider).valueOrNull ?? [];
  if (filtro.tipo == FiltroTipo.todos) return todos;

  final q = filtro.valor.toLowerCase();
  switch (filtro.tipo) {
    case FiltroTipo.parteCuerpo:
      return todos
          .where((e) => e.partesCuerpo.any((p) => p.toLowerCase() == q))
          .toList();
    case FiltroTipo.musculo:
      return todos
          .where((e) =>
              e.musculosObjetivo.any((m) => m.toLowerCase() == q) ||
              e.musculosSecundarios.any((m) => m.toLowerCase() == q))
          .toList();
    case FiltroTipo.equipamiento:
      return todos
          .where((e) => e.equipamientos.any((eq) => eq.toLowerCase() == q))
          .toList();
    case FiltroTipo.busqueda:
      return todos
          .where((e) =>
              e.nombre.toLowerCase().contains(q) ||
              (e.descripcion?.toLowerCase().contains(q) ?? false))
          .toList();
    default:
      return todos;
  }
});

// ---------------------------------------------------------------------------
// Provider de ejercicio individual por ID
// ---------------------------------------------------------------------------

final ejercicioDetalleProvider =
    FutureProvider.autoDispose.family<EjercicioDb?, String>((ref, id) async {
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchById(id);
});
