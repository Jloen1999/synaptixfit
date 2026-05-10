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

  Future<String?> guardarRutina({String nombre = 'Mi rutina'}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    if (state.items.isEmpty) return null;

    try {
      String rutinaId = state.rutinaId;

      if (rutinaId.isEmpty) {
        final rutinaData = await client
            .from('rutinas')
            .insert({
              'usuario_id': user.id,
              'nombre': nombre,
              'cantidad_ejercicios': state.items.length,
            })
            .select('id')
            .single();
        rutinaId = rutinaData['id'] as String;
      } else {
        await client.from('rutinas').update({
          'cantidad_ejercicios': state.items.length,
        }).eq('id', rutinaId);
      }

      // Eliminar selecciones previas y reinsertar
      await client
          .from('seleccion_de_ejercicios')
          .delete()
          .eq('rutina_id', rutinaId);

      if (state.items.isNotEmpty) {
        final rows = state.items
            .map((item) => {
                  'rutina_id': rutinaId,
                  'ejercicio_id': item.ejercicioId,
                  'series': item.series,
                  'repeticiones': item.repeticiones,
                  'segundos_descanso': item.segundosDescanso,
                  'indice_orden': item.indiceOrden,
                })
            .toList();

        await client.from('seleccion_de_ejercicios').insert(rows);
      }

      state = RutinaState(rutinaId: rutinaId, items: state.items);
      return rutinaId;
    } catch (e) {
      return null;
    }
  }
}

final rutinaProvider =
    StateNotifierProvider<RutinaNotifier, RutinaState>((ref) {
  return RutinaNotifier();
});

// ---------------------------------------------------------------------------
// Flujo de creación de rutina (estado compartido entre pantallas)
// ---------------------------------------------------------------------------

class EjercicioSeleccionado {
  const EjercicioSeleccionado({
    required this.ejercicioId,
    required this.nombre,
    this.series = 3,
    this.repeticiones = 10,
    this.segundosDescanso = 60,
  });

  final String ejercicioId;
  final String nombre;
  final int series;
  final int repeticiones;
  final int segundosDescanso;

  EjercicioSeleccionado copyWith({
    int? series,
    int? repeticiones,
    int? segundosDescanso,
  }) {
    return EjercicioSeleccionado(
      ejercicioId: ejercicioId,
      nombre: nombre,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      segundosDescanso: segundosDescanso ?? this.segundosDescanso,
    );
  }
}

class CreacionRutinaState {
  const CreacionRutinaState({
    this.nombre = '',
    this.descripcion = '',
    this.visibilidad = 'private',
    this.seleccionados = const [],
  });

  final String nombre;
  final String descripcion;
  final String visibilidad;
  final List<EjercicioSeleccionado> seleccionados;

  CreacionRutinaState copyWith({
    String? nombre,
    String? descripcion,
    String? visibilidad,
    List<EjercicioSeleccionado>? seleccionados,
  }) {
    return CreacionRutinaState(
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      visibilidad: visibilidad ?? this.visibilidad,
      seleccionados: seleccionados ?? this.seleccionados,
    );
  }
}

class CreacionRutinaNotifier extends StateNotifier<CreacionRutinaState> {
  CreacionRutinaNotifier() : super(const CreacionRutinaState());

  void setMetadata(String nombre, String descripcion, String visibilidad) {
    state = state.copyWith(
        nombre: nombre, descripcion: descripcion, visibilidad: visibilidad);
  }

  void toggleEjercicio(String ejercicioId, String nombre) {
    final existe = state.seleccionados.any((s) => s.ejercicioId == ejercicioId);
    if (existe) {
      state = state.copyWith(
        seleccionados: state.seleccionados
            .where((s) => s.ejercicioId != ejercicioId)
            .toList(),
      );
    } else {
      state = state.copyWith(
        seleccionados: [
          ...state.seleccionados,
          EjercicioSeleccionado(ejercicioId: ejercicioId, nombre: nombre),
        ],
      );
    }
  }

  void actualizarEjercicio(
      String ejercicioId, int series, int repeticiones, int descanso) {
    state = state.copyWith(
      seleccionados: state.seleccionados.map((s) {
        if (s.ejercicioId == ejercicioId) {
          return s.copyWith(
              series: series,
              repeticiones: repeticiones,
              segundosDescanso: descanso);
        }
        return s;
      }).toList(),
    );
  }

  void limpiar() {
    state = const CreacionRutinaState();
  }
}

final creacionRutinaProvider =
    StateNotifierProvider<CreacionRutinaNotifier, CreacionRutinaState>(
        (ref) => CreacionRutinaNotifier());

final rutinasComunidadProvider =
    FutureProvider<List<RutinaComunidadDto>>((ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('rutinas')
      .select('*, usuarios!usuario_id(nombre_completo)')
      .eq('visibilidad', 'public')
      .order('creado_en', ascending: false)
      .limit(30);
  return (data as List).map((r) {
    final map = r as Map<String, dynamic>;
    final autor = (map['usuarios'] as Map<String, dynamic>?)?['nombre_completo']
            as String? ??
        'Usuario';
    return RutinaComunidadDto(
      rutina: RutinaDb.fromMap(map),
      autorNombre: autor,
    );
  }).toList();
});

class RutinaComunidadDto {
  const RutinaComunidadDto({required this.rutina, required this.autorNombre});

  final RutinaDb rutina;
  final String autorNombre;
}

final rutinasUsuarioProvider = FutureProvider<List<RutinaDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];
  final data = await client
      .from('rutinas')
      .select('*')
      .eq('usuario_id', user.id)
      .order('creado_en', ascending: false)
      .limit(20);
  return (data as List)
      .map((r) => RutinaDb.fromMap(r as Map<String, dynamic>))
      .toList();
});

Future<void> clonarRutina(String rutinaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  final rutinaMap =
      await client.from('rutinas').select().eq('id', rutinaId).maybeSingle();
  if (rutinaMap == null) return;

  final nueva = await client
      .from('rutinas')
      .insert({
        'usuario_id': user.id,
        'nombre': '${rutinaMap['nombre']} (copiada)',
        'descripcion': rutinaMap['descripcion'],
        'visibilidad': 'private',
        'cantidad_ejercicios': rutinaMap['cantidad_ejercicios'],
      })
      .select('id')
      .single();

  final nuevoId = nueva['id'] as String;

  final ejercicios = await client
      .from('seleccion_de_ejercicios')
      .select()
      .eq('rutina_id', rutinaId)
      .order('indice_orden');

  if ((ejercicios as List).isNotEmpty) {
    final nuevos = ejercicios
        .map((e) => {
              'rutina_id': nuevoId,
              'ejercicio_id': e['ejercicio_id'],
              'series': e['series'],
              'repeticiones': e['repeticiones'],
              'segundos_descanso': e['segundos_descanso'],
              'indice_orden': e['indice_orden'],
            })
        .toList();
    await client.from('seleccion_de_ejercicios').insert(nuevos);
  }

  ref.invalidate(rutinasUsuarioProvider);
}

// ---------------------------------------------------------------------------
// Providers de estructura: semanas, días, ejercicios por día
// ---------------------------------------------------------------------------

final semanasDeRutinaProvider =
    FutureProvider.family<List<SemanaRutinaDb>, String>((ref, rutinaId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('semanas_rutina')
      .select('*')
      .eq('rutina_id', rutinaId)
      .order('numero_semana', ascending: true);
  return (data as List)
      .map((s) => SemanaRutinaDb.fromMap(s as Map<String, dynamic>))
      .toList();
});

final diasDeSemanaProvider =
    FutureProvider.family<List<DiaRutinaDb>, String>((ref, semanaId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('dias_rutina')
      .select('*')
      .eq('semana_id', semanaId)
      .order('numero_dia', ascending: true);
  return (data as List)
      .map((d) => DiaRutinaDb.fromMap(d as Map<String, dynamic>))
      .toList();
});

final ejerciciosDeDiaProvider =
    FutureProvider.family<List<SeleccionEjercicioDb>, String>(
        (ref, diaId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('seleccion_de_ejercicios')
      .select('*')
      .eq('dia_id', diaId)
      .order('indice_orden', ascending: true);
  return (data as List)
      .map((e) => SeleccionEjercicioDb.fromMap(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// CRUD — Rutinas con semanas, días y ejercicios
// ---------------------------------------------------------------------------

Future<String> crearRutinaCompleta({
  required String nombre,
  String? descripcion,
  required String visibilidad,
  required String objetivo,
  required int duracionSemanas,
  required Map<int, Map<int, List<EjercicioInput>>> estructura,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) throw Exception('No autenticado');

  final rutinaData = await client
      .from('rutinas')
      .insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'descripcion': descripcion,
        'visibilidad': visibilidad,
        'objetivo': objetivo,
        'duracion_semanas': duracionSemanas,
        'cantidad_ejercicios': 0,
      })
      .select('id')
      .single();
  final rutinaId = rutinaData['id'] as String;

  int totalEjercicios = 0;
  for (final semanaNum in estructura.keys) {
    final semanaData = await client
        .from('semanas_rutina')
        .insert({
          'rutina_id': rutinaId,
          'numero_semana': semanaNum,
          'nombre': 'Semana $semanaNum',
        })
        .select('id')
        .single();
    final semanaId = semanaData['id'] as String;

    final dias = estructura[semanaNum]!;
    for (final diaNum in dias.keys) {
      final diaData = await client
          .from('dias_rutina')
          .insert({
            'semana_id': semanaId,
            'numero_dia': diaNum,
            'nombre': 'Día $diaNum',
          })
          .select('id')
          .single();
      final diaId = diaData['id'] as String;

      final ejercicios = dias[diaNum]!;
      if (ejercicios.isNotEmpty) {
        final rows = <Map<String, dynamic>>[];
        for (var i = 0; i < ejercicios.length; i++) {
          final e = ejercicios[i];
          rows.add({
            'rutina_id': rutinaId,
            'ejercicio_id': e.ejercicioId,
            'dia_id': diaId,
            'series': e.series,
            'repeticiones': e.repeticiones,
            'segundos_descanso': e.segundosDescanso,
            'indice_orden': i + 1,
            if (e.pesoKg != null) 'peso_kg': e.pesoKg,
          });
        }
        await client.from('seleccion_de_ejercicios').insert(rows);
        totalEjercicios += ejercicios.length;
      }
    }
  }

  await client.from('rutinas').update({
    'cantidad_ejercicios': totalEjercicios,
  }).eq('id', rutinaId);

  ref.invalidate(rutinasUsuarioProvider);
  return rutinaId;
}

Future<void> eliminarRutina(String rutinaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client.from('rutinas').delete().eq('id', rutinaId);
  ref.invalidate(rutinasUsuarioProvider);
}

Future<void> actualizarEstadoSemana(
    String semanaId, String estado, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client
      .from('semanas_rutina')
      .update({'estado': estado}).eq('id', semanaId);
  ref.invalidate(semanasDeRutinaProvider);
}

Future<void> actualizarEstadoDia(
    String diaId, String estado, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client.from('dias_rutina').update({'estado': estado}).eq('id', diaId);
  ref.invalidate(diasDeSemanaProvider);
}

Future<void> agregarEjercicioADia({
  required String rutinaId,
  required String diaId,
  required String ejercicioId,
  required int series,
  required int repeticiones,
  required int segundosDescanso,
  double? pesoKg,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  await client.from('seleccion_de_ejercicios').insert({
    'rutina_id': rutinaId,
    'ejercicio_id': ejercicioId,
    'dia_id': diaId,
    'series': series,
    'repeticiones': repeticiones,
    'segundos_descanso': segundosDescanso,
    'indice_orden': 99,
    if (pesoKg != null) 'peso_kg': pesoKg,
  });
  ref.invalidate(ejerciciosDeDiaProvider(diaId));
}

Future<void> quitarEjercicioDeDia(
    String seleccionId, String diaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client.from('seleccion_de_ejercicios').delete().eq('id', seleccionId);
  ref.invalidate(ejerciciosDeDiaProvider(diaId));
}

Future<void> actualizarEjercicioDia(String seleccionId,
    Map<String, dynamic> patch, String diaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client
      .from('seleccion_de_ejercicios')
      .update(patch)
      .eq('id', seleccionId);
  ref.invalidate(ejerciciosDeDiaProvider(diaId));
}

Future<String> agregarDiaASemana(
    String semanaId, int numeroDia, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('dias_rutina')
      .insert({
        'semana_id': semanaId,
        'numero_dia': numeroDia,
        'nombre': 'Día $numeroDia',
      })
      .select('id')
      .single();
  ref.invalidate(diasDeSemanaProvider(semanaId));
  return data['id'] as String;
}

// ---------------------------------------------------------------------------
// Sesión en vivo — registro de sesión con series
// ---------------------------------------------------------------------------

Future<String> iniciarSesion({
  required String rutinaId,
  required String diaId,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) throw Exception('No autenticado');

  final data = await client
      .from('sesiones_registradas')
      .insert({
        'usuario_id': user.id,
        'rutina_id': rutinaId,
        'dia_id': diaId,
        'tipo': 'rutina',
        'duracion_minutos': 0,
        'calorias_quemadas': 0,
        'rpe': 5,
        'completada_en': DateTime.now().toIso8601String(),
      })
      .select('id')
      .single();

  await actualizarEstadoDia(diaId, 'en_progreso', ref);
  return data['id'] as String;
}

Future<void> finalizarSesion({
  required String sesionId,
  required String diaId,
  required int duracionSegundos,
  required int rpe,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final duracionMin = (duracionSegundos / 60).round();
  final calorias = (duracionMin * rpe * 0.8).roundToDouble();

  await client.from('sesiones_registradas').update({
    'duracion_minutos': duracionMin,
    'rpe': rpe,
    'calorias_quemadas': calorias,
  }).eq('id', sesionId);

  await actualizarEstadoDia(diaId, 'completado', ref);
}

Future<void> registrarSerie({
  required String sesionId,
  String? seleccionId,
  required int numeroSerie,
  int? repeticionesRealizadas,
  double? pesoKg,
  bool completada = true,
}) async {
  final client = Supabase.instance.client;
  await client.from('series_sesion').insert({
    'sesion_id': sesionId,
    if (seleccionId != null) 'seleccion_id': seleccionId,
    'numero_serie': numeroSerie,
    if (repeticionesRealizadas != null)
      'repeticiones_realizadas': repeticionesRealizadas,
    if (pesoKg != null) 'peso_kg': pesoKg,
    'completada': completada,
  });
}

class EjercicioInput {
  const EjercicioInput({
    required this.ejercicioId,
    required this.series,
    required this.repeticiones,
    required this.segundosDescanso,
    this.pesoKg,
  });
  final String ejercicioId;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final double? pesoKg;
}
