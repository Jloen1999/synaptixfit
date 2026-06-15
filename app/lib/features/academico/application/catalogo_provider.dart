import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

final universidadesProvider = FutureProvider<List<UniversidadDb>>((ref) async {
  final data = await Supabase.instance.client
      .from('universidades')
      .select()
      .order('nombre', ascending: true);
  return data.map((e) => UniversidadDb.fromMap(e)).toList();
});

/// Carreras filtradas por universidad (join vía centros)
final carrerasPorUniversidadProvider =
    FutureProvider.family<List<CarreraDb>, String>((ref, universidadId) async {
  final data = await Supabase.instance.client
      .from('centros')
      .select('carreras(*)')
      .eq('universidad_id', universidadId)
      .order('nombre', ascending: true);

  final result = <CarreraDb>[];
  for (final centro in (data as List)) {
    final carrerasAnidadas = centro['carreras'] as List? ?? [];
    for (final c in carrerasAnidadas) {
      result.add(CarreraDb.fromMap(c as Map<String, dynamic>));
    }
  }
  return result;
});

final catalogoAsignaturasPorCarreraProvider =
    FutureProvider.family<List<AsignaturaCatalogoDb>, String>(
        (ref, carreraId) async {
  final data = await Supabase.instance.client
      .from('asignaturas_catalogo')
      .select()
      .eq('carrera_id', carreraId)
      .order('curso', ascending: true)
      .order('nombre', ascending: true);
  return data.map((e) => AsignaturaCatalogoDb.fromMap(e)).toList();
});
