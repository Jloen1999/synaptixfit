import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/application/timeline_provider.dart';
import '../../social/application/social_provider.dart';
import '../../social/infrastructure/social_repository.dart';
import '../../insignias/application/insignias_provider.dart';
import 'retos_core.dart';

export 'retos_core.dart';
import 'reto_dependencia_service.dart';
import '../domain/reto_grafo_dto.dart';

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
  ref.invalidate(timelineHoyProvider);
  ref.invalidate(hitosPendientesProvider);
  if (retoId != null) {
    ref.invalidate(retoDetalleProvider(retoId));
    ref.invalidate(tareasDeRetoProvider(retoId));
    ref.invalidate(retoTieneHitosProvider(retoId));
  }
}

Future<void> completarReto(String retoId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  await client.from('retos').update({
    'esta_completado': true,
  }).eq('id', retoId);
  await client.from('hitos_de_reto').update({
    'progreso_actual': 100,
    'esta_completado': true,
    'estado': 'completado',
  }).eq('reto_id', retoId);

  if (user != null) {
    final hitosData =
        await client.from('hitos_de_reto').select('id').eq('reto_id', retoId);
    final cantidadHitos = (hitosData as List).length;
    final xpGanado = cantidadHitos > 0 ? (cantidadHitos * 100) + 300 : 200;

    final xpResult = await otorgarXp(client, user.id, xpGanado);
    if (xpResult != null) {
      ref.invalidate(dashboardProvider);
    }

    // Publicar automáticamente en el feed social al completar el reto
    final retoData = await client
        .from('retos')
        .select('titulo')
        .eq('id', retoId)
        .maybeSingle();
    if (retoData != null) {
      final titulo = retoData['titulo'] as String? ?? 'Reto';
      try {
        final socialRepo = SocialRepository(client);
        await socialRepo.crearPublicacion(
          usuarioId: user.id,
          descripcion: '¡He completado el reto "$titulo"! 🎯',
          tipo: 'challenge_completed',
        );
        // Invalidar el feed social para que la publicación aparezca
        ref.invalidate(socialFeedProvider);
      } catch (_) {
        // El logro social es best-effort; no bloquea la completación del reto
      }
    }
  }

  _invalidarRetos(ref, retoId: retoId);

  // Evaluar insignias tras completar reto
  await evaluarInsignias(ref);
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
    'estado': completada ? 'completado' : 'en_progreso',
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
        'visibilidad': 'private',
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

// ---------------------------------------------------------------------------
// Sprint 7 — Providers de grafo de dependencias
// ---------------------------------------------------------------------------

/// Construye el grafo de dependencias para un reto con todos sus hitos.
final grafoRetoProvider =
    FutureProvider.family<GrafoReto?, String>((ref, retoId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final hitosData = await client
      .from('hitos_de_reto')
      .select()
      .eq('reto_id', retoId)
      .order('indice_orden', ascending: true);

  final hitosList = hitosData as List;
  if (hitosList.isEmpty) return null;

  final hitos = hitosList
      .map((h) => HitoRetoDb.fromMap(h as Map<String, dynamic>))
      .toList();

  const service = RetoDependenciaService();

  final error = service.validarDependencias(hitos);
  if (error != null) {
    debugPrint('[grafoRetoProvider] Error de dependencias: $error');
  }

  return service.construirGrafo(hitos);
});
