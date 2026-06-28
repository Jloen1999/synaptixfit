import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

final asignaturasActivasProvider =
    FutureProvider<List<AsignaturaDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('asignaturas')
      .select()
      .eq('usuario_id', user.id)
      .eq('archivado', false)
      .order('nombre', ascending: true);

  return data.map((e) => AsignaturaDb.fromMap(e)).toList();
});

final asignaturaPorIdProvider =
    FutureProvider.family<AsignaturaDb?, String>((ref, id) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final data = await client
      .from('asignaturas')
      .select()
      .eq('id', id)
      .eq('usuario_id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return AsignaturaDb.fromMap(data);
});

final asignaturasArchivadasProvider =
    FutureProvider<List<AsignaturaDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('asignaturas')
      .select()
      .eq('usuario_id', user.id)
      .eq('archivado', true)
      .order('nombre', ascending: true);

  return data.map((e) => AsignaturaDb.fromMap(e)).toList();
});

Future<AsignaturaDb?> crearAsignatura({
  required String nombre,
  String? codigo,
  String? descripcion,
  String? docente,
  String? catalogoAsignaturaId,
  bool archivado = false,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final data = await client
      .from('asignaturas')
      .insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
        'docente': docente,
        'catalogo_asignatura_id': catalogoAsignaturaId,
        'archivado': archivado,
      })
      .select()
      .single();

  return AsignaturaDb.fromMap(data);
}

Future<AsignaturaDb?> actualizarAsignatura({
  required String id,
  required String nombre,
  String? codigo,
  String? descripcion,
  String? docente,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  final data = await client
      .from('asignaturas')
      .update({
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
        'docente': docente,
      })
      .eq('id', id)
      .eq('usuario_id', user!.id)
      .select()
      .single();

  return AsignaturaDb.fromMap(data);
}

Future<void> archivarAsignatura(String id, bool archivado) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  await client
      .from('asignaturas')
      .update({'archivado': archivado})
      .eq('id', id)
      .eq('usuario_id', user!.id);
}

Future<void> eliminarAsignatura(String id) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  await client
      .from('asignaturas')
      .delete()
      .eq('id', id)
      .eq('usuario_id', user!.id);
}
