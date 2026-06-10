import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/utils/string_utils.dart';
import '../infrastructure/ejercicios_repository.dart';

// Re-exporta finalidadesEstandar y sanitizarObjetivo desde string_utils
// para mantener compatibilidad con todos los importadores de ejercicios_provider.
export '../../../shared/utils/string_utils.dart'
    show finalidadesEstandar, sanitizarObjetivo;

// ---------------------------------------------------------------------------
// Iconos — dependen de Flutter, se quedan aquí
// ---------------------------------------------------------------------------

IconData iconoFinalidad(String f) {
  switch (f) {
    case 'Hipertrofia Muscular':
      return Icons.monitor_weight_rounded;
    case 'Fuerza Máxima':
      return Icons.fitness_center_rounded;
    case 'Potencia y Explosividad':
      return Icons.bolt_rounded;
    case 'Fuerza Resistencia':
      return Icons.loop_rounded;
    case 'Movilidad y Flexibilidad':
      return Icons.self_improvement_rounded;
    case 'Estabilidad y Control Motor':
      return Icons.accessibility_new_rounded;
    case 'Acondicionamiento Metabólico':
      return Icons.directions_run_rounded;
    default:
      return Icons.gps_fixed_rounded;
  }
}

// ---------------------------------------------------------------------------
// DTO para filtro de ejercicios (cliente, sin red)
// ---------------------------------------------------------------------------

enum FiltroTipo {
  todos,
  parteCuerpo,
  musculo,
  equipamiento,
  finalidad,
  busqueda
}

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

final catalogoMusculosProvider = Provider<Map<String, String?>>((ref) {
  final catalogos = ref.watch(catalogosProvider).valueOrNull;
  if (catalogos == null) return {};
  return {
    for (final m in catalogos.musculos) m.nombre: m.urlImagen,
  };
});

final finalidadesDisponiblesProvider = Provider<List<String>>((ref) {
  final todos = ref.watch(ejerciciosProvider).valueOrNull ?? [];
  final unique = <String>{};
  for (final e in todos) {
    for (final f in e.finalidad) {
      if (f.isNotEmpty) unique.add(f);
    }
  }
  return unique.toList()..sort();
});

// ---------------------------------------------------------------------------
// Capa 2 — Filtrado en memoria (< 1ms, cero red)
// ---------------------------------------------------------------------------

final ejerciciosFiltradosProvider =
    Provider.family<List<EjercicioDb>, FiltroEjercicios>((ref, filtro) {
  final todos = ref.watch(ejerciciosProvider).valueOrNull ?? [];
  if (filtro.tipo == FiltroTipo.todos) return todos;

  final q = normalizeSearch(filtro.valor);
  switch (filtro.tipo) {
    case FiltroTipo.parteCuerpo:
      return todos
          .where((e) => e.partesCuerpo.any((p) => normalizeSearch(p) == q))
          .toList();
    case FiltroTipo.musculo:
      return todos
          .where((e) =>
              e.musculosObjetivo.any((m) => normalizeSearch(m) == q) ||
              e.musculosSecundarios.any((m) => normalizeSearch(m) == q))
          .toList();
    case FiltroTipo.equipamiento:
      return todos
          .where((e) => e.equipamientos.any((eq) => normalizeSearch(eq) == q))
          .toList();
    case FiltroTipo.finalidad:
      return todos
          .where((e) => e.finalidad.any((f) => normalizeSearch(f) == q))
          .toList();
    case FiltroTipo.busqueda:
      return todos
          .where((e) =>
              normalizeSearch(e.nombre).contains(q) ||
              (e.descripcion != null &&
                  normalizeSearch(e.descripcion!).contains(q)))
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
  final cachedList = ref.watch(ejerciciosProvider).valueOrNull;
  if (cachedList != null) {
    final cached = cachedList.where((e) => e.id == id).firstOrNull;
    if (cached != null) return cached;
  }
  final repo = ref.read(ejerciciosRepositoryProvider);
  return repo.fetchById(id);
});
