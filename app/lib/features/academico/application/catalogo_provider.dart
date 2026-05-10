import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

final universidadesProvider =
    FutureProvider<List<CatalogoUniversidadDb>>((ref) async {
  final data = await Supabase.instance.client
      .from('catalogo_universidades')
      .select()
      .order('nombre', ascending: true);
  return data.map((e) => CatalogoUniversidadDb.fromMap(e)).toList();
});

final carrerasPorUniversidadProvider =
    FutureProvider.family<List<CatalogoCarreraDb>, String>(
        (ref, universidadId) async {
  final data = await Supabase.instance.client
      .from('catalogo_carreras')
      .select()
      .eq('universidad_id', universidadId)
      .order('nombre', ascending: true);
  return data.map((e) => CatalogoCarreraDb.fromMap(e)).toList();
});

final catalogoAsignaturasPorCarreraProvider =
    FutureProvider.family<List<CatalogoAsignaturaDb>, String>(
        (ref, carreraId) async {
  final data = await Supabase.instance.client
      .from('catalogo_asignaturas')
      .select()
      .eq('carrera_id', carreraId)
      .order('curso', ascending: true)
      .order('nombre', ascending: true);
  return data.map((e) => CatalogoAsignaturaDb.fromMap(e)).toList();
});
