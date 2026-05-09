import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

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
      .select()
      .eq('usuario_id', user.id)
      .eq('esta_completado', false)
      .order('fecha_fin', ascending: true);

  final retos = (retosData as List)
      .map((r) => RetoDb.fromMap(r as Map<String, dynamic>))
      .toList();

  if (retos.isEmpty) return [];

  // Batch query: qué retos tienen hitos
  final retoIds = retos.map((r) => r.id).toList();
  final hitosData = await client
      .from('hitos_de_reto')
      .select('reto_id')
      .inFilter('reto_id', retoIds);
  final retosConHitos =
      (hitosData as List).map((h) => h['reto_id'] as String).toSet();

  final result = <RetoResumen>[];
  for (final reto in retos) {
    final progreso = await _calcularProgresoReto(client, reto.id);
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

  final progreso = await _calcularProgresoReto(client, retoId);

  return RetoDetalle(
    reto: reto,
    progresoGeneral: progreso,
    hitos: hitos,
    actividadRelacionada: null, // TODO: Conectar con actividades sociales
    likes: 0,
    comentarios: 0,
  );
});

/// Calcula el progreso normalizado de un reto basándose en sus hitos.
Future<double> _calcularProgresoReto(
    SupabaseClient client, String retoId) async {
  final hitosData =
      await client.from('hitos_de_reto').select().eq('reto_id', retoId);

  final hitos = (hitosData as List)
      .map((h) => HitoRetoDb.fromMap(h as Map<String, dynamic>))
      .toList();

  if (hitos.isEmpty) return 0.0;

  final weightedProgress = hitos.fold<double>(
    0,
    (total, hito) =>
        total + ((hito.porcentajePeso / 100) * (hito.progresoActual / 100)),
  );
  return weightedProgress.clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// Mutaciones
// ---------------------------------------------------------------------------

Future<void> completarReto(String retoId) async {
  final client = Supabase.instance.client;
  await client.from('retos').update({
    'esta_completado': true,
  }).eq('id', retoId);
}

Future<void> descompletarReto(String retoId) async {
  final client = Supabase.instance.client;
  await client.from('retos').update({
    'esta_completado': false,
  }).eq('id', retoId);
}

Future<void> actualizarProgresoHito(
    String hitoId, double progreso) async {
  final client = Supabase.instance.client;
  final valor = progreso.clamp(0.0, 100.0).round();
  await client.from('hitos_de_reto').update({
    'progreso_actual': valor,
    'esta_completado': valor >= 100,
  }).eq('id', hitoId);
}

Future<String?> clonarReto(String retoId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final retoMap =
      await client.from('retos').select().eq('id', retoId).maybeSingle();
  if (retoMap == null) return null;

  final retoData = await client.from('retos').insert({
    'usuario_id': user.id,
    'titulo': retoMap['titulo'],
    'tipo': retoMap['tipo'],
    'meta': retoMap['meta'],
    'visibilidad': 'privado',
    'esta_completado': false,
    'fecha_inicio': DateTime.now().toIso8601String(),
    'fecha_fin': retoMap['fecha_fin'],
  }).select('id').single();

  final nuevoId = retoData['id'] as String;

  final hitosData = await client
      .from('hitos_de_reto')
      .select()
      .eq('reto_id', retoId)
      .order('indice_orden', ascending: true);

  if ((hitosData as List).isNotEmpty) {
    final nuevosHitos = hitosData.map((h) => {
      'reto_id': nuevoId,
      'titulo': h['titulo'],
      'porcentaje_peso': h['porcentaje_peso'],
      'indice_orden': h['indice_orden'],
      'progreso_actual': 0,
      'esta_completado': false,
    }).toList();
    await client.from('hitos_de_reto').insert(nuevosHitos);
  }

  return nuevoId;
}

// ---------------------------------------------------------------------------
// Provider de retos públicos (para explorar y clonar)
// ---------------------------------------------------------------------------
final retosPublicosProvider =
    FutureProvider.autoDispose<List<RetoResumen>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final retosData = await client
      .from('retos')
      .select()
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
  final hitosData = await client
      .from('hitos_de_reto')
      .select('reto_id')
      .inFilter('reto_id', retoIds);
  final retosConHitos =
      (hitosData as List).map((h) => h['reto_id'] as String).toSet();

  final result = <RetoResumen>[];
  for (final reto in retos) {
    final progreso = await _calcularProgresoReto(client, reto.id);
    result.add(RetoResumen(
      reto: reto,
      progreso: progreso,
      tieneHitos: retosConHitos.contains(reto.id),
    ));
  }
  return result;
});
