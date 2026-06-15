import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

final apuntesProvider = FutureProvider<List<ApunteDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('apuntes')
      .select()
      .eq('usuario_id', user.id)
      .order('actualizado_en', ascending: false);

  return data.map((e) => ApunteDb.fromMap(e)).toList();
});

/// DTO para apunte público con nombre del autor.
class ApuntePublicoDto {
  const ApuntePublicoDto({required this.apunte, required this.autorNombre});
  final ApunteDb apunte;
  final String autorNombre;
}

/// Apuntes visibles por el usuario actual que NO son propios.
/// RLS de Supabase filtra automáticamente: solo publico + solo_amigos.
final apuntesPublicosProvider =
    FutureProvider<List<ApuntePublicoDto>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('apuntes')
      .select('*, usuarios(nombre_completo)')
      .neq('usuario_id', user.id)
      .order('actualizado_en', ascending: false)
      .limit(50);

  return (data as List).map((row) {
    final autorData = row['usuarios'] as Map<String, dynamic>?;
    return ApuntePublicoDto(
      apunte: ApunteDb.fromMap(row as Map<String, dynamic>),
      autorNombre: autorData?['nombre_completo'] as String? ?? 'Usuario',
    );
  }).toList();
});

final apunteDetalleProvider =
    FutureProvider.autoDispose.family<ApunteDb?, String>((ref, id) async {
  final client = Supabase.instance.client;
  final data = await client.from('apuntes').select().eq('id', id).maybeSingle();
  if (data == null) return null;
  return ApunteDb.fromMap(data);
});

Future<ApunteDb?> crearApunte({
  required String titulo,
  required String contenido,
  String? asignaturaId,
  String visibilidad = 'private',
  bool esNotaRapida = false,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final data = await client
      .from('apuntes')
      .insert({
        'usuario_id': user.id,
        'titulo': titulo,
        'contenido': contenido,
        'asignatura_id': asignaturaId,
        'visibilidad': visibilidad,
        'es_nota_rapida': esNotaRapida,
      })
      .select()
      .single();

  return ApunteDb.fromMap(data);
}

Future<void> actualizarApunte({
  required String id,
  required String titulo,
  required String contenido,
  String? asignaturaId,
  String? visibilidad,
  bool? esNotaRapida,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  await client
      .from('apuntes')
      .update({
        'titulo': titulo,
        'contenido': contenido,
        'asignatura_id': asignaturaId,
        'visibilidad': visibilidad,
        if (esNotaRapida != null) 'es_nota_rapida': esNotaRapida,
        'actualizado_en': DateTime.now().toIso8601String(),
      })
      .eq('id', id)
      .eq('usuario_id', user!.id);
}

Future<void> eliminarApunte(String id) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  await client.from('apuntes').delete().eq('id', id).eq('usuario_id', user!.id);
}
