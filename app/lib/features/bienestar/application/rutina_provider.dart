import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

class ItemRutina {
  const ItemRutina({
    required this.id,
    required this.ejercicioId,
    required this.nombre,
    required this.series,
    required this.repeticiones,
    required this.segundosDescanso,
    required this.indiceOrden,
  });

  final String id;
  final String ejercicioId;
  final String nombre;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final int indiceOrden;

  ItemRutina copyWith({
    String? id,
    String? ejercicioId,
    String? nombre,
    int? series,
    int? repeticiones,
    int? segundosDescanso,
    int? indiceOrden,
  }) {
    return ItemRutina(
      id: id ?? this.id,
      ejercicioId: ejercicioId ?? this.ejercicioId,
      nombre: nombre ?? this.nombre,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      segundosDescanso: segundosDescanso ?? this.segundosDescanso,
      indiceOrden: indiceOrden ?? this.indiceOrden,
    );
  }
}

class RutinaState {
  const RutinaState({required this.rutinaId, required this.items});

  final String rutinaId;
  final List<ItemRutina> items;
}

class RutinaNotifier extends StateNotifier<RutinaState> {
  RutinaNotifier() : super(const RutinaState(rutinaId: '', items: [])) {
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Obtener la primera rutina del usuario
      final rutinaMap = await client
          .from('rutinas')
          .select()
          .eq('usuario_id', user.id)
          .order('creado_en', ascending: false)
          .limit(1)
          .maybeSingle();

      if (rutinaMap == null) return;
      final rutinaId = rutinaMap['id'] as String;

      // Obtener los ejercicios de la rutina
      final seleccionData = await client
          .from('seleccion_de_ejercicios')
          .select('*, ejercicios(nombre)')
          .eq('rutina_id', rutinaId)
          .order('indice_orden', ascending: true);

      final items = (seleccionData as List).map((s) {
        final ejercicioNombre =
            (s['ejercicios'] as Map<String, dynamic>?)?['nombre'] ??
                'Ejercicio no disponible';
        return ItemRutina(
          id: s['id'] as String,
          ejercicioId: s['ejercicio_id'] as String,
          nombre: ejercicioNombre as String,
          series: (s['series'] as num?)?.toInt() ?? 3,
          repeticiones: (s['repeticiones'] as num?)?.toInt() ?? 10,
          segundosDescanso: (s['segundos_descanso'] as num?)?.toInt() ?? 60,
          indiceOrden: (s['indice_orden'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      state = RutinaState(rutinaId: rutinaId, items: items);
    } catch (e) {
      // Si falla la carga, mantener estado vacío
    }
  }

  void reorder(int oldIndex, int newIndex) {
    final current = [...state.items];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);
    final reordered = <ItemRutina>[];
    for (var index = 0; index < current.length; index++) {
      reordered.add(current[index].copyWith(indiceOrden: index + 1));
    }
    state = RutinaState(rutinaId: state.rutinaId, items: reordered);
  }

  void remove(String id) {
    final filtered = state.items.where((item) => item.id != id).toList();
    final normalized = <ItemRutina>[];
    for (var index = 0; index < filtered.length; index++) {
      normalized.add(filtered[index].copyWith(indiceOrden: index + 1));
    }
    state = RutinaState(rutinaId: state.rutinaId, items: normalized);
  }
}

final rutinaProvider = StateNotifierProvider<RutinaNotifier, RutinaState>((ref) {
  return RutinaNotifier();
});
