import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../academico/application/asignaturas_provider.dart';

class AsignaturaSeleccion {
  final AsignaturaCatalogoDb catalogo;
  final String? registroId;
  final bool seleccionada;

  const AsignaturaSeleccion({
    required this.catalogo,
    this.registroId,
    required this.seleccionada,
  });

  AsignaturaSeleccion copyWith({bool? seleccionada, String? registroId}) =>
      AsignaturaSeleccion(
        catalogo: catalogo,
        registroId: registroId ?? this.registroId,
        seleccionada: seleccionada ?? this.seleccionada,
      );
}

final selectorAsignaturasProvider =
    FutureProvider<List<AsignaturaSeleccion>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final carreraIds = await _getCarreraIds(client, user.id);
  if (carreraIds.isEmpty) return [];

  final catalogoData = <Map<String, dynamic>>[];
  for (final cid in carreraIds) {
    final rows = await client
        .from('asignaturas_catalogo')
        .select()
        .eq('carrera_id', cid)
        .order('curso', ascending: true)
        .order('semestre', ascending: true)
        .order('nombre', ascending: true);
    catalogoData.addAll((rows as List).cast<Map<String, dynamic>>());
  }

  final usuarioData = await client
      .from('asignaturas')
      .select('id, catalogo_asignatura_id, archivado')
      .eq('usuario_id', user.id);

  final registroMap = <String, ({String id, bool archivado})>{};
  for (final r in (usuarioData as List)) {
    final catId = r['catalogo_asignatura_id'] as String?;
    if (catId != null) {
      registroMap[catId] = (
        id: r['id'] as String,
        archivado: r['archivado'] as bool? ?? false,
      );
    }
  }

  return catalogoData.map((m) {
    final cat = AsignaturaCatalogoDb.fromMap(m);
    final reg = registroMap[cat.id];
    return AsignaturaSeleccion(
      catalogo: cat,
      registroId: reg?.id,
      seleccionada: reg != null && !reg.archivado,
    );
  }).toList();
});

Future<List<String>> _getCarreraIds(
    SupabaseClient client, String userId) async {
  final ucList = await client
      .from('usuario_carreras')
      .select('carrera_id')
      .eq('usuario_id', userId);
  var ids = (ucList as List).map((r) => r['carrera_id'] as String).toList();
  if (ids.isEmpty) {
    final perfil = await client
        .from('perfil_academico_usuario')
        .select('carrera')
        .eq('usuario_id', userId)
        .maybeSingle();
    final nombre = perfil?['carrera'] as String?;
    if (nombre == null || nombre.isEmpty) return [];
    final match = await client
        .from('carreras')
        .select('id')
        .eq('nombre', nombre)
        .maybeSingle();
    if (match != null) ids = [match['id'] as String];
  }
  return ids;
}

Future<void> toggleAsignatura({
  required AsignaturaSeleccion item,
  required bool activar,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  if (item.registroId != null) {
    await client
        .from('asignaturas')
        .update({'archivado': !activar}).eq('id', item.registroId!);
  } else if (activar) {
    final cat = item.catalogo;
    final desc = [
      if (cat.curso != null) 'Curso ${cat.curso}',
      if (cat.semestre != null) 'Sem ${cat.semestre}',
      if (cat.caracter != null) cat.caracter,
      if (cat.creditos != null) '${cat.creditos} ECTS',
    ].join(' · ');
    await client.from('asignaturas').insert({
      'usuario_id': user.id,
      'nombre': cat.nombre,
      'catalogo_asignatura_id': cat.id,
      'descripcion': desc.isNotEmpty ? desc : null,
      'archivado': false,
    });
  }
}

Future<void> aplicarSeleccionBatch({
  required List<AsignaturaSeleccion> items,
  required bool activar,
}) async {
  for (final item in items) {
    final yaActivo = item.seleccionada;
    if (activar && !yaActivo) {
      await toggleAsignatura(item: item, activar: true);
    } else if (!activar && yaActivo) {
      await toggleAsignatura(item: item, activar: false);
    }
  }
}

void invalidarProviders(dynamic ref) {
  ref.invalidate(selectorAsignaturasProvider);
  ref.invalidate(asignaturasActivasProvider);
  ref.invalidate(asignaturasArchivadasProvider);
}
