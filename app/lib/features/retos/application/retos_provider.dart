import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../dashboard/application/dashboard_provider.dart';

class RetoResumen {
  const RetoResumen({
    required this.reto,
    required this.progreso,
    required this.tieneHitos,
  });

  final RetoDb reto;
  final double progreso;
  final bool tieneHitos;
}

class RetoDetalle {
  const RetoDetalle({
    required this.reto,
    required this.progresoGeneral,
    required this.hitos,
    this.actividadRelacionada,
    required this.likes,
    required this.comentarios,
  });

  final RetoDb reto;
  final double progresoGeneral;
  final List<HitoRetoDb> hitos;
  final ActividadSocialDb? actividadRelacionada;
  final int likes;
  final int comentarios;
}

// ---------------------------------------------------------------------------
// Provider de retos activos del usuario (desde Supabase)
// ---------------------------------------------------------------------------
final retosProvider = FutureProvider<List<RetoResumen>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final retosData = await client
      .from('retos')
      .select(
          'id, titulo, tipo, meta, visibilidad, esta_completado, fecha_inicio, fecha_fin, usuario_id, creado_en')
      .eq('usuario_id', user.id)
      .eq('esta_completado', false)
      .order('fecha_fin', ascending: true);

  final retos = (retosData as List)
      .map((r) => RetoDb.fromMap(r as Map<String, dynamic>))
      .toList();

  if (retos.isEmpty) return [];

  // Batch único: todos los hitos de todos los retos activos
  final retoIds = retos.map((r) => r.id).toList();
  final todosHitosData = await client
      .from('hitos_de_reto')
      .select('reto_id, porcentaje_peso, progreso_actual, esta_completado')
      .inFilter('reto_id', retoIds);

  final hitosPorReto = <String, List<Map<String, dynamic>>>{};
  for (final h in (todosHitosData as List)) {
    final rid = h['reto_id'] as String;
    hitosPorReto.putIfAbsent(rid, () => []).add(h);
  }

  final retosConHitos = hitosPorReto.keys.toSet();

  final result = <RetoResumen>[];
  for (final reto in retos) {
    final hitos = hitosPorReto[reto.id] ?? [];
    double progreso = 0.0;
    if (hitos.isNotEmpty) {
      final weighted = hitos.fold<double>(
        0,
        (t, h) =>
            t +
            ((h['porcentaje_peso'] as num).toDouble() / 100) *
                ((h['progreso_actual'] as num).toDouble() / 100),
      );
      progreso = weighted.clamp(0.0, 1.0);
    }
    result.add(RetoResumen(
      reto: reto,
      progreso: progreso,
      tieneHitos: retosConHitos.contains(reto.id),
    ));
  }

  return result;
});

// ---------------------------------------------------------------------------
// Provider de detalle de un reto
// ---------------------------------------------------------------------------
final retoDetalleProvider =
    FutureProvider.family<RetoDetalle?, String>((ref, retoId) async {
  final client = Supabase.instance.client;

  final retoMap =
      await client.from('retos').select().eq('id', retoId).maybeSingle();

  if (retoMap == null) return null;
  final reto = RetoDb.fromMap(retoMap);

  // Hitos
  final hitosData = await client
      .from('hitos_de_reto')
      .select()
      .eq('reto_id', retoId)
      .order('indice_orden', ascending: true);

  final hitos = (hitosData as List)
      .map((h) => HitoRetoDb.fromMap(h as Map<String, dynamic>))
      .toList();

  double progreso = 0.0;
  if (hitos.isNotEmpty) {
    final weighted = hitos.fold<double>(
      0,
      (t, h) => t + ((h.porcentajePeso / 100) * (h.progresoActual / 100)),
    );
    progreso = weighted.clamp(0.0, 1.0);
  }

  return RetoDetalle(
    reto: reto,
    progresoGeneral: progreso,
    hitos: hitos,
    actividadRelacionada: null, // TODO: Conectar con actividades sociales
    likes: 0,
    comentarios: 0,
  );
});

// ---------------------------------------------------------------------------
// Mutaciones — ahora auto-invalidan todos los providers dependientes
// ---------------------------------------------------------------------------

void _invalidarRetos(WidgetRef ref, {String? retoId}) {
  ref.invalidate(retosProvider);
  ref.invalidate(retosPublicosProvider);
  ref.invalidate(logrosCountProvider);
  ref.invalidate(dashboardProvider);
  if (retoId != null) {
    ref.invalidate(retoDetalleProvider(retoId));
    ref.invalidate(tareasDeRetoProvider(retoId));
    ref.invalidate(retoTieneHitosProvider(retoId));
  }
}

Future<void> completarReto(String retoId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client.from('retos').update({
    'esta_completado': true,
  }).eq('id', retoId);
  await client.from('hitos_de_reto').update({
    'progreso_actual': 100,
    'esta_completado': true,
  }).eq('reto_id', retoId);
  _invalidarRetos(ref, retoId: retoId);
}

Future<void> descompletarReto(String retoId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  await client.from('retos').update({
    'esta_completado': false,
  }).eq('id', retoId);
  _invalidarRetos(ref, retoId: retoId);
}

Future<void> toggleTareaCompletada(String hitoId, String retoId,
    {required bool completada, required WidgetRef ref}) async {
  final client = Supabase.instance.client;
  await client.from('hitos_de_reto').update({
    'progreso_actual': completada ? 100 : 0,
    'esta_completado': completada,
  }).eq('id', hitoId);
  _invalidarRetos(ref, retoId: retoId);
}

Future<void> reordenarTareas(String retoId, List<String> idsOrdenados,
    {required WidgetRef ref}) async {
  final client = Supabase.instance.client;
  for (var i = 0; i < idsOrdenados.length; i++) {
    await client.from('hitos_de_reto').update({
      'indice_orden': -(i + 1),
    }).eq('id', idsOrdenados[i]);
  }
  for (var i = 0; i < idsOrdenados.length; i++) {
    await client.from('hitos_de_reto').update({
      'indice_orden': i + 1,
    }).eq('id', idsOrdenados[i]);
  }
  _invalidarRetos(ref, retoId: retoId);
}

Future<String?> clonarReto(String retoId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final retoMap =
      await client.from('retos').select().eq('id', retoId).maybeSingle();
  if (retoMap == null) return null;

  final retoData = await client
      .from('retos')
      .insert({
        'usuario_id': user.id,
        'titulo': retoMap['titulo'],
        'tipo': retoMap['tipo'],
        'meta': retoMap['meta'],
        'visibilidad': 'privado',
        'esta_completado': false,
        'fecha_inicio': DateTime.now().toIso8601String(),
        'fecha_fin': retoMap['fecha_fin'],
      })
      .select('id')
      .single();

  final nuevoId = retoData['id'] as String;

  final hitosData = await client
      .from('hitos_de_reto')
      .select()
      .eq('reto_id', retoId)
      .order('indice_orden', ascending: true);

  if ((hitosData as List).isNotEmpty) {
    final nuevosHitos = hitosData
        .map((h) => {
              'reto_id': nuevoId,
              'titulo': h['titulo'],
              'porcentaje_peso': h['porcentaje_peso'],
              'indice_orden': h['indice_orden'],
              'progreso_actual': 0,
              'esta_completado': false,
            })
        .toList();
    await client.from('hitos_de_reto').insert(nuevosHitos);
  }

  _invalidarRetos(ref);
  return nuevoId;
}

/// Retos completados del usuario (para logros en perfil)
final logrosCountProvider = FutureProvider<int>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return 0;
  final data = await client
      .from('retos')
      .select('id')
      .eq('usuario_id', user.id)
      .eq('esta_completado', true);
  return (data as List).length;
});

final tareasDeRetoProvider =
    FutureProvider.family<List<HitoRetoDb>, String>((ref, retoId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('hitos_de_reto')
      .select(
          'id, reto_id, titulo, porcentaje_peso, indice_orden, progreso_actual, esta_completado')
      .eq('reto_id', retoId)
      .order('indice_orden', ascending: true);
  return (data as List)
      .map((h) => HitoRetoDb.fromMap(h as Map<String, dynamic>))
      .toList();
});

final retoTieneHitosProvider =
    FutureProvider.family<bool, String>((ref, retoId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('hitos_de_reto')
      .select('id')
      .eq('reto_id', retoId)
      .limit(1);
  return (data as List).isNotEmpty;
});

// ---------------------------------------------------------------------------
// Provider de retos públicos (para explorar y clonar)
// ---------------------------------------------------------------------------
final retosPublicosProvider = FutureProvider<List<RetoResumen>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final retosData = await client
      .from('retos')
      .select(
          'id, titulo, tipo, meta, visibilidad, esta_completado, fecha_inicio, fecha_fin, usuario_id, creado_en')
      .eq('visibilidad', 'publico')
      .neq('usuario_id', user.id)
      .eq('esta_completado', false)
      .order('fecha_fin', ascending: true)
      .limit(20);

  final retos = (retosData as List)
      .map((r) => RetoDb.fromMap(r as Map<String, dynamic>))
      .toList();

  if (retos.isEmpty) return [];

  final retoIds = retos.map((r) => r.id).toList();
  final todosHitosData = await client
      .from('hitos_de_reto')
      .select('reto_id, porcentaje_peso, progreso_actual, esta_completado')
      .inFilter('reto_id', retoIds);

  final hitosPorReto = <String, List<Map<String, dynamic>>>{};
  for (final h in (todosHitosData as List)) {
    final rid = h['reto_id'] as String;
    hitosPorReto.putIfAbsent(rid, () => []).add(h);
  }

  final retosConHitos = hitosPorReto.keys.toSet();

  final result = <RetoResumen>[];
  for (final reto in retos) {
    final hitos = hitosPorReto[reto.id] ?? [];
    double progreso = 0.0;
    if (hitos.isNotEmpty) {
      final weighted = hitos.fold<double>(
        0,
        (t, h) =>
            t +
            ((h['porcentaje_peso'] as num).toDouble() / 100) *
                ((h['progreso_actual'] as num).toDouble() / 100),
      );
      progreso = weighted.clamp(0.0, 1.0);
    }
    result.add(RetoResumen(
      reto: reto,
      progreso: progreso,
      tieneHitos: retosConHitos.contains(reto.id),
    ));
  }
  return result;
});
