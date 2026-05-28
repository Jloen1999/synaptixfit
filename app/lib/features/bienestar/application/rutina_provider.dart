import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../auth/infrastructure/bienestar_repository.dart';
import '../infrastructure/recomendacion_ia_service.dart';

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

final nombresEjerciciosProvider =
    FutureProvider.family<Map<String, String>, String>((ref, diaId) async {
  final client = Supabase.instance.client;
  final ejerciciosRaw = await client
      .from('seleccion_de_ejercicios')
      .select('ejercicio_id, ejercicios!inner(nombre)')
      .eq('dia_id', diaId);
  final map = <String, String>{};
  for (final row in (ejerciciosRaw as List)) {
    final ejId = row['ejercicio_id'] as String;
    final ejData = row['ejercicios'] as Map<String, dynamic>?;
    if (ejData != null) {
      map[ejId] = ejData['nombre'] as String? ?? '';
    }
  }
  return map;
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

  const objetivosValidos = [
    'fitness_general',
    'perder_peso',
    'ganar_masa',
    'fuerza',
    'resistencia',
    'movilidad',
    'mixto',
  ];
  final objetivoFinal =
      objetivosValidos.contains(objetivo) ? objetivo : 'fuerza';

  final rutinaData = await client
      .from('rutinas')
      .insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'descripcion': descripcion,
        'visibilidad': visibilidad,
        'objetivo': objetivoFinal,
        'duracion_semanas': duracionSemanas,
        'cantidad_ejercicios': 0,
      })
      .select('id')
      .single();
  final rutinaId = rutinaData['id'] as String;

  int totalEjercicios = 0;
  final totalSemanas = estructura.keys.length;
  for (final semanaNum in estructura.keys) {
    final tipo = _calcularTipoSemana(semanaNum, totalSemanas);
    final semanaData = await client
        .from('semanas_rutina')
        .insert({
          'rutina_id': rutinaId,
          'numero_semana': semanaNum,
          'nombre': 'Semana $semanaNum',
          'tipo_semana': tipo,
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
            if (e.duracionSegundos != null)
              'duracion_segundos': e.duracionSegundos,
            if (e.distanciaMetros != null)
              'distancia_metros': e.distanciaMetros,
            if (e.tiempoIsometricoSegundos != null)
              'tiempo_isometrico_segundos': e.tiempoIsometricoSegundos,
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
  ref.invalidate(rutinasComunidadProvider);
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
  int? duracionSegundos,
  int? distanciaMetros,
  int? tiempoIsometricoSegundos,
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
    if (duracionSegundos != null) 'duracion_segundos': duracionSegundos,
    if (distanciaMetros != null) 'distancia_metros': distanciaMetros,
    if (tiempoIsometricoSegundos != null)
      'tiempo_isometrico_segundos': tiempoIsometricoSegundos,
  });
  await reactivarSiCompletada(rutinaId, ref);
  ref.invalidate(ejerciciosDeDiaProvider(diaId));
  ref.invalidate(nombresEjerciciosProvider(diaId));
}

Future<void> quitarEjercicioDeDia(
    String seleccionId, String diaId, String rutinaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client.from('seleccion_de_ejercicios').delete().eq('id', seleccionId);
  await reactivarSiCompletada(rutinaId, ref);
  ref.invalidate(ejerciciosDeDiaProvider(diaId));
  ref.invalidate(nombresEjerciciosProvider(diaId));
}

Future<void> reactivarSiCompletada(String rutinaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final r = await client
      .from('rutinas')
      .select('estado')
      .eq('id', rutinaId)
      .maybeSingle();
  if (r == null || r['estado'] != 'completado') return;

  final semanas = await client
      .from('semanas_rutina')
      .select('id')
      .eq('rutina_id', rutinaId);
  final semanaIds = (semanas as List).map((s) => s['id'] as String).toList();

  if (semanaIds.isNotEmpty) {
    for (final sid in semanaIds) {
      await client
          .from('dias_rutina')
          .update({'estado': 'pendiente'}).eq('semana_id', sid);
    }
    await client
        .from('semanas_rutina')
        .update({'estado': 'pendiente'}).eq('rutina_id', rutinaId);
  }

  await client.from('rutinas').update({'estado': 'activo'}).eq('id', rutinaId);

  ref.invalidate(rutinasUsuarioProvider);
  ref.invalidate(rutinasComunidadProvider);
  ref.invalidate(semanasDeRutinaProvider(rutinaId));
  ref.invalidate(progresoRutinasProvider);
}

Future<void> actualizarEjercicioDia(String seleccionId,
    Map<String, dynamic> patch, String diaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client
      .from('seleccion_de_ejercicios')
      .update(patch)
      .eq('id', seleccionId);
  ref.invalidate(ejerciciosDeDiaProvider(diaId));
  ref.invalidate(nombresEjerciciosProvider(diaId));
}

Future<String> agregarDiaASemana(
    String semanaId, int numeroDia, String rutinaId, WidgetRef ref) async {
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
  await reactivarSiCompletada(rutinaId, ref);
  ref.invalidate(diasDeSemanaProvider(semanaId));
  return data['id'] as String;
}

Future<void> eliminarDiaDeSemana(
    String diaId, String semanaId, String rutinaId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client.from('dias_rutina').delete().eq('id', diaId);
  await reactivarSiCompletada(rutinaId, ref);
  ref.invalidate(diasDeSemanaProvider(semanaId));
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
        'duracion_minutos': 1,
        'calorias_quemadas': 1.0,
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
  required String rutinaId,
  required int duracionSegundos,
  required int rpe,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final duracionMin = (duracionSegundos / 60).round().clamp(1, 99999);
  final calorias = (duracionMin * rpe * 0.8).roundToDouble();

  await client.from('sesiones_registradas').update({
    'duracion_minutos': duracionMin,
    'rpe': rpe,
    'calorias_quemadas': calorias,
  }).eq('id', sesionId);

  await actualizarEstadoDia(diaId, 'completado', ref);

  // El trigger actualizar_estado_semana() en BD actualiza la semana
  // automáticamente cuando todos sus días están 'completado'.
  ref.invalidate(diasDeSemanaProvider);
  ref.invalidate(semanasDeRutinaProvider(rutinaId));
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
    this.duracionSegundos,
    this.distanciaMetros,
    this.tiempoIsometricoSegundos,
  });
  final String ejercicioId;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final double? pesoKg;
  final int? duracionSegundos;
  final int? distanciaMetros;
  final int? tiempoIsometricoSegundos;
}

final perfilBienestarProvider = FutureProvider<PerfilBienestarDb?>((ref) async {
  return const BienestarRepository().obtenerPerfilBienestar();
});

final tiempoDiaProvider =
    FutureProvider.family<int, String>((ref, diaId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('sesiones_registradas')
      .select('duracion_minutos')
      .eq('dia_id', diaId)
      .order('completada_en', ascending: false)
      .limit(1);
  if (data is List && data.isNotEmpty) {
    return (data.first['duracion_minutos'] as num?)?.toInt() ?? 0;
  }
  return 0;
});

final historialSesionUsuarioProvider =
    FutureProvider<HistorialSesionDto?>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  // Sesiones completadas recientes (ultimas 4 semanas)
  final sesionesData = await client
      .from('sesiones_registradas')
      .select('id, rpe, completada_en')
      .eq('usuario_id', user.id)
      .order('completada_en', ascending: false)
      .limit(30);

  final sesionesList = sesionesData as List?;
  if (sesionesList == null || sesionesList.isEmpty) return null;

  final sesiones = sesionesList.cast<Map<String, dynamic>>();

  // RPE promedio
  final rpes = sesiones
      .map((s) => (s['rpe'] as num?)?.toDouble())
      .whereType<double>()
      .toList();
  final rpePromedio =
      rpes.isNotEmpty ? rpes.reduce((a, b) => a + b) / rpes.length : 0.0;

  // Sesiones de las ultimas 4 semanas
  final hace4Semanas = DateTime.now().subtract(const Duration(days: 28));
  final sesionesRecientes = sesiones.where((s) {
    final fecha = DateTime.tryParse(s['completada_en'] as String? ?? '');
    return fecha != null && fecha.isAfter(hace4Semanas);
  }).toList();

  // Semanas consecutivas entrenando
  int semanasConsecutivas = 0;
  DateTime? semanaAnterior;
  for (final s in sesionesRecientes) {
    final fecha = DateTime.tryParse(s['completada_en'] as String? ?? '');
    if (fecha == null) continue;
    final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
    final key =
        DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
    if (semanaAnterior == null || key.difference(semanaAnterior).inDays <= 7) {
      if (semanaAnterior != key) semanasConsecutivas++;
      semanaAnterior = key;
    } else {
      break;
    }
  }

  // Ejercicios recientes (de las ultimas 4 sesiones)
  final sesionesRecientesIds =
      sesionesRecientes.take(4).map((s) => s['id'] as String).toList();
  List<EjericicioRecienteDto> ejerciciosRecientes = [];
  if (sesionesRecientesIds.isNotEmpty) {
    final seriesData = await client
        .from('series_sesion')
        .select('seleccion_id, peso_kg, repeticiones_realizadas, '
            'seleccion_de_ejercicios!inner(ejercicio_id, ejercicios!inner(nombre))')
        .inFilter('sesion_id', sesionesRecientesIds)
        .order('creado_en', ascending: false);

    final seriesRaw = seriesData as List?;
    if (seriesRaw == null) return null;
    final Map<String, List<Map<String, dynamic>>> porEjercicio = {};
    for (final serie in seriesRaw.cast<Map<String, dynamic>>()) {
      final sel = serie['seleccion_de_ejercicios'];
      if (sel == null) continue;
      final ej = sel['ejercicios'];
      if (ej == null) continue;
      final nombre = ej['nombre'] as String? ?? 'Desconocido';
      porEjercicio.putIfAbsent(nombre, () => []).add(serie);
    }
    for (final entry in porEjercicio.entries) {
      final pesos = entry.value
          .map((s) => (s['peso_kg'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final reps = entry.value
          .map((s) => (s['repeticiones_realizadas'] as num?)?.toInt())
          .whereType<int>()
          .toList();
      if (pesos.isEmpty || reps.isEmpty) continue;
      ejerciciosRecientes.add(EjericicioRecienteDto(
        nombreEjercicio: entry.key,
        pesoPromedio: pesos.reduce((a, b) => a + b) / pesos.length,
        repsPromedio: (reps.reduce((a, b) => a + b) / reps.length).round(),
        rpePromedio: rpePromedio,
        ultimaFecha: DateTime.now(),
      ));
    }
  }

  // Volumen semanal estimado
  final volumenEstimado = ejerciciosRecientes.fold<int>(
      0, (sum, e) => sum + (e.pesoPromedio * e.repsPromedio).round());

  return HistorialSesionDto(
    totalSesionesCompletadas: sesiones.length,
    rpePromedio: rpePromedio,
    volumenSemanalEstimado: volumenEstimado,
    ejerciciosRecientes: ejerciciosRecientes,
    diasCompletadosUltimaSemana: sesionesRecientes.length,
    semanasConsecutivasEntrenando: semanasConsecutivas,
  );
});

// ---------------------------------------------------------------------------
// Estado diario — check-in de fatiga
// ---------------------------------------------------------------------------

final estadoDiarioHoyProvider = FutureProvider<EstadoDiarioDb?>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  final data = await client
      .from('estado_diario_usuario')
      .select()
      .eq('usuario_id', user.id)
      .eq('fecha', hoy)
      .maybeSingle();

  if (data == null) return null;
  return EstadoDiarioDb.fromMap(data);
});

Future<void> guardarEstadoDiario({
  required int calidadSueno,
  required int nivelEstres,
  required int nivelEnergia,
  required int dolorMuscular,
  required List<String> zonasDolor,
  required bool listoParaEntrenar,
  String? notas,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  await client.from('estado_diario_usuario').upsert({
    'usuario_id': user.id,
    'fecha': hoy,
    'calidad_sueno': calidadSueno,
    'nivel_estres': nivelEstres,
    'nivel_energia': nivelEnergia,
    'dolor_muscular': dolorMuscular,
    'zonas_dolor': zonasDolor,
    'listo_para_entrenar': listoParaEntrenar,
    if (notas != null) 'notas': notas,
  }, onConflict: 'usuario_id,fecha');

  ref.invalidate(estadoDiarioHoyProvider);
}

/// Determina el tipo de semana según periodización:
/// - 1 semana: carga única
/// - 2 semanas: adaptación → carga
/// - 3 semanas: adaptación → carga → pico
/// - 4+ semanas: adaptación → carga → carga → descarga (y repite)
String _calcularTipoSemana(int semanaNum, int totalSemanas) {
  if (totalSemanas <= 1) return 'carga';
  if (semanaNum == 1) return 'adaptacion';
  if (semanaNum == totalSemanas && totalSemanas >= 4) return 'descarga';
  if (semanaNum == totalSemanas && totalSemanas >= 3) return 'pico';
  return 'carga';
}

/// Detecta si el usuario necesita una semana de descarga automática.
/// Criterios: RPE > 8.0 sostenido 3+ semanas, volumen decreciente,
/// o puntuación de fatiga diaria > 50.
final estadoPeriodizacionProvider =
    FutureProvider<PeriodizacionEstado>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return const PeriodizacionEstado();

  final hace3Semanas =
      DateTime.now().subtract(const Duration(days: 21)).toIso8601String();
  final sesionesData = await client
      .from('sesiones_registradas')
      .select('rpe, duracion_minutos, completada_en, rutina_id')
      .eq('usuario_id', user.id)
      .gte('completada_en', hace3Semanas)
      .order('completada_en', ascending: false);

  if (sesionesData is! List || sesionesData.isEmpty) {
    return const PeriodizacionEstado();
  }

  final sesiones = sesionesData.cast<Map<String, dynamic>>();
  final rpes = sesiones
      .map((s) => (s['rpe'] as num?)?.toDouble())
      .whereType<double>()
      .toList();
  final rpePromedio =
      rpes.isNotEmpty ? rpes.reduce((a, b) => a + b) / rpes.length : 0.0;

  final Map<String, int> volumenPorSemana = {};
  for (final s in sesiones) {
    final fecha = DateTime.tryParse(s['completada_en'] as String? ?? '');
    if (fecha == null) continue;
    final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
    final key =
        '${inicioSemana.year}-${inicioSemana.month}-${inicioSemana.day}';
    volumenPorSemana[key] = (volumenPorSemana[key] ?? 0) +
        ((s['duracion_minutos'] as num?)?.toInt() ?? 0);
  }

  final volumenes = volumenPorSemana.values.toList();
  bool volumenDecreciente = false;
  if (volumenes.length >= 3) {
    volumenDecreciente =
        volumenes[volumenes.length - 1] < volumenes[volumenes.length - 2] &&
            volumenes[volumenes.length - 2] < volumenes[volumenes.length - 3];
  }

  int semanasConsecutivas = 0;
  DateTime? semanaAnterior;
  for (final s in sesiones) {
    final fecha = DateTime.tryParse(s['completada_en'] as String? ?? '');
    if (fecha == null) continue;
    final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
    final key =
        DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
    if (semanaAnterior == null || key.difference(semanaAnterior).inDays <= 7) {
      if (semanaAnterior != key) semanasConsecutivas++;
      semanaAnterior = key;
    } else {
      break;
    }
  }

  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  final estadoDiarioMap = await client
      .from('estado_diario_usuario')
      .select('calidad_sueno, nivel_estres, nivel_energia, dolor_muscular')
      .eq('usuario_id', user.id)
      .eq('fecha', hoy)
      .maybeSingle();
  int puntuacionFatigaDiaria = 0;
  if (estadoDiarioMap != null) {
    final ed = EstadoDiarioDb.fromMap(estadoDiarioMap);
    puntuacionFatigaDiaria = ed.puntuacionFatiga;
  }

  final necesitaDescarga =
      (rpePromedio > 8.0 && semanasConsecutivas >= 3 && volumenDecreciente) ||
          puntuacionFatigaDiaria > 50;

  return PeriodizacionEstado(
    necesitaDescarga: necesitaDescarga,
    rpePromedioReciente: rpePromedio,
    volumenDecreciente: volumenDecreciente,
    semanasConsecutivas: semanasConsecutivas,
    puntuacionFatigaDiaria: puntuacionFatigaDiaria,
  );
});

class PeriodizacionEstado {
  const PeriodizacionEstado({
    this.necesitaDescarga = false,
    this.rpePromedioReciente = 0.0,
    this.volumenDecreciente = false,
    this.semanasConsecutivas = 0,
    this.puntuacionFatigaDiaria = 0,
  });

  final bool necesitaDescarga;
  final double rpePromedioReciente;
  final bool volumenDecreciente;
  final int semanasConsecutivas;
  final int puntuacionFatigaDiaria;
}

class ProgresoRutinaDto {
  const ProgresoRutinaDto({
    required this.diasCompletados,
    required this.totalDias,
  });

  final int diasCompletados;
  final int totalDias;

  double get porcentaje =>
      totalDias > 0 ? (diasCompletados / totalDias).clamp(0.0, 1.0) : 0.0;
}

final progresoRutinasProvider =
    FutureProvider<Map<String, ProgresoRutinaDto>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return {};

  final rutinasData =
      await client.from('rutinas').select('id').eq('usuario_id', user.id);

  final ids = (rutinasData as List).map((r) => r['id'] as String).toList();
  if (ids.isEmpty) return {};

  final orSemanas = ids.map((id) => 'rutina_id.eq.$id').join(',');
  final semanasData =
      await client.from('semanas_rutina').select('id, rutina_id').or(orSemanas);

  final semanaIds =
      (semanasData as List).map((s) => s['id'] as String).toList();
  if (semanaIds.isEmpty) {
    return {
      for (final id in ids)
        id: const ProgresoRutinaDto(diasCompletados: 0, totalDias: 0)
    };
  }

  final orDias = semanaIds.map((id) => 'semana_id.eq.$id').join(',');
  final diasData =
      await client.from('dias_rutina').select('semana_id, estado').or(orDias);

  final rutinaDeSemana = <String, String>{};
  for (final s in semanasData) {
    rutinaDeSemana[s['id'] as String] = s['rutina_id'] as String;
  }

  final totalPorRutina = <String, int>{};
  final completadosPorRutina = <String, int>{};
  for (final d in diasData) {
    final semanaId = d['semana_id'] as String;
    final rutinaId = rutinaDeSemana[semanaId] ?? '';
    totalPorRutina[rutinaId] = (totalPorRutina[rutinaId] ?? 0) + 1;
    if (d['estado'] == 'completado') {
      completadosPorRutina[rutinaId] =
          (completadosPorRutina[rutinaId] ?? 0) + 1;
    }
  }

  return {
    for (final id in ids)
      id: ProgresoRutinaDto(
        diasCompletados: completadosPorRutina[id] ?? 0,
        totalDias: totalPorRutina[id] ?? 0,
      )
  };
});
