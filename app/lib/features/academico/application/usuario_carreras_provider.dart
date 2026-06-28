import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import 'asignaturas_provider.dart';

final usuarioCarrerasProvider =
    FutureProvider<List<UsuarioCarreraDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('usuario_carreras')
      .select()
      .eq('usuario_id', user.id)
      .order('creado_en', ascending: true);

  return data.map((e) => UsuarioCarreraDb.fromMap(e)).toList();
});

/// Carreras del usuario con el nombre de la carrera resuelto.
final carrerasUsuarioConNombreProvider =
    FutureProvider.family<List<CarreraDb>, List<UsuarioCarreraDb>>(
        (ref, usuarioCarreras) async {
  final client = Supabase.instance.client;
  final result = <CarreraDb>[];
  for (final uc in usuarioCarreras) {
    final data = await client
        .from('carreras')
        .select()
        .eq('id', uc.carreraId)
        .maybeSingle();
    if (data != null) {
      result.add(CarreraDb.fromMap(data));
    }
  }
  return result;
});

Future<void> agregarCarrera(String carreraId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  final existe = await client
      .from('usuario_carreras')
      .select('id')
      .eq('usuario_id', user.id)
      .eq('carrera_id', carreraId)
      .maybeSingle();

  if (existe == null) {
    await client.from('usuario_carreras').insert({
      'usuario_id': user.id,
      'carrera_id': carreraId,
    });
  }

  ref.invalidate(usuarioCarrerasProvider);
}

Future<void> eliminarCarrera(String carreraId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  await client
      .from('usuario_carreras')
      .delete()
      .eq('usuario_id', user.id)
      .eq('carrera_id', carreraId);

  ref.invalidate(usuarioCarrerasProvider);
}

/// Sincroniza asignaturas: crea las del catálogo que no existan ya en las
/// asignaturas del usuario. No elimina asignaturas existentes.
Future<int> sincronizarAsignaturasDeCarreras(WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return 0;

  // Carreras del usuario
  final ucData = await client
      .from('usuario_carreras')
      .select('carrera_id')
      .eq('usuario_id', user.id);

  if ((ucData as List).isEmpty) return 0;

  final carreraIds = ucData.map((r) => r['carrera_id'] as String).toList();
  int creadas = 0;

  for (final cid in carreraIds) {
    final catalogoData = await client
        .from('asignaturas_catalogo')
        .select()
        .eq('carrera_id', cid);

    for (final a in (catalogoData as List)) {
      final nombre = a['nombre'] as String;

      // Verificar si ya existe
      final existente = await client
          .from('asignaturas')
          .select('id')
          .eq('usuario_id', user.id)
          .eq('nombre', nombre)
          .maybeSingle();

      if (existente != null) continue;

      final desc = [
        if (a['curso'] != null) 'Curso ${a['curso']}',
        if (a['semestre'] != null) 'Sem ${a['semestre']}',
        if (a['caracter'] != null) a['caracter'],
        if (a['creditos'] != null) '${a['creditos']} ECTS',
      ].join(' · ');

      await client.from('asignaturas').insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'catalogo_asignatura_id': a['id'],
        'descripcion': desc.isNotEmpty ? desc : null,
        'archivado': true,
      });
      creadas++;
    }
  }

  ref.invalidate(asignaturasActivasProvider);
  ref.invalidate(asignaturasArchivadasProvider);
  return creadas;
}
