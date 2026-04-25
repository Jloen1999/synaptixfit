import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

class RetoResumen {
  const RetoResumen({required this.reto, required this.progreso});

  final RetoDb reto;
  final double progreso;
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

  // Calcular progreso para cada reto
  final result = <RetoResumen>[];
  for (final reto in retos) {
    final progreso = await _calcularProgresoReto(client, reto.id);
    result.add(RetoResumen(reto: reto, progreso: progreso));
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
