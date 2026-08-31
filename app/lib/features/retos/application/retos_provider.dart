import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/dominio_evento.dart';
import '../../../core/sync/sync_hub.dart';
import '../../../shared/models/db_models.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../bienestar/infrastructure/calorie_calculator_service.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/application/timeline_provider.dart';
import '../../social/infrastructure/social_repository.dart';
import '../../insignias/application/insignias_provider.dart';
import '../../perfil/application/perfil_provider.dart';
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
  ref.invalidate(todosRetosProvider);
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

  final retoRow = await client
      .from('retos')
      .select('dificultad, xp_otorgado, titulo, tipo')
      .eq('id', retoId)
      .maybeSingle();
  final hitosRows = await client
      .from('hitos_de_reto')
      .select('id, dificultad, xp_otorgado, esta_completado')
      .eq('reto_id', retoId);

  var xpTotal = 0;
  final tieneHitos = (hitosRows as List).isNotEmpty;

  if (tieneHitos) {
    for (final h in hitosRows) {
      final yaCompletado = h['esta_completado'] == true;
      final yaXp = (h['xp_otorgado'] as num?)?.toInt() ?? 0;
      if (!yaCompletado || yaXp == 0) {
        final xp = xpPorDificultad((h['dificultad'] as String?) ?? 'media');
        xpTotal += xp;
        await client.from('hitos_de_reto').update({
          'progreso_actual': 100,
          'esta_completado': true,
          'estado': 'completado',
          'xp_otorgado': xp,
        }).eq('id', h['id']);
      }
    }
  } else {
    final yaXp = (retoRow?['xp_otorgado'] as num?)?.toInt() ?? 0;
    if (yaXp == 0) {
      final xp =
          xpPorDificultad((retoRow?['dificultad'] as String?) ?? 'media');
      xpTotal += xp;
      await client.from('retos').update({'xp_otorgado': xp}).eq('id', retoId);
    }
  }

  // ── Cálculo calórico transaccional (solo retos fitness) ──────────
  final esFitness = (retoRow?['tipo'] as String?) == 'fitness';
  var caloriasReto = 0;
  var duracionMinReto = 0;

  if (esFitness) {
    duracionMinReto = _estimarDuracionReto(
      hitos: tieneHitos ? hitosRows : null,
      dificultadReto: (retoRow?['dificultad'] as String?) ?? 'media',
    );

    final pesoKg = await _obtenerPesoUsuario(client);
    final totalKcal = _calcularCaloriasReto(
      hitos: tieneHitos ? hitosRows : null,
      dificultadReto: (retoRow?['dificultad'] as String?) ?? 'media',
      pesoUsuarioKg: pesoKg,
    );
    caloriasReto = CalorieCalculatorService.redondear(totalKcal);

    await client.from('sesiones_registradas').insert({
      'id': retoId,
      'usuario_id': user?.id,
      'rutina_id': null,
      'duracion_minutos': duracionMinReto,
      'calorias_quemadas': caloriasReto.toDouble(),
      'rpe': null,
      'completada_en': DateTime.now().toIso8601String(),
      'tipo': 'reto',
      'dia_id': null,
    });

    ref.invalidate(perfilActividadProvider);
  }
  // ──────────────────────────────────────────────────────────────────

  await client.from('retos').update({
    'esta_completado': true,
  }).eq('id', retoId);

  if (user != null) {
    if (xpTotal > 0) {
      await otorgarXp(client, user.id, xpTotal);
    }
    final titulo = retoRow?['titulo'] as String? ?? 'Reto';
    try {
      final socialRepo = SocialRepository(client);
      await socialRepo.crearPublicacion(
        usuarioId: user.id,
        descripcion: '¡He completado el reto "$titulo"!',
        tipo: 'challenge_completed',
      );
    } catch (_) {}
  }

  _invalidarRetos(ref, retoId: retoId);

  ref.read(syncHubProvider).dispatch(
        DominioEvento.retoCompletado,
        payload: EventoPayload(retoId: retoId),
      );

  await evaluarInsignias(ref);
}

Future<void> descompletarReto(String retoId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  final retoRow = await client
      .from('retos')
      .select('xp_otorgado, tipo')
      .eq('id', retoId)
      .maybeSingle();
  final hitosRows = await client
      .from('hitos_de_reto')
      .select('id, xp_otorgado')
      .eq('reto_id', retoId);

  var xpRestar = 0;

  if ((hitosRows as List).isNotEmpty) {
    for (final h in hitosRows) {
      xpRestar += (h['xp_otorgado'] as num?)?.toInt() ?? 0;
      await client.from('hitos_de_reto').update({
        'progreso_actual': 0,
        'esta_completado': false,
        'estado': 'disponible',
        'xp_otorgado': 0,
      }).eq('id', h['id']);
    }
  } else {
    xpRestar += (retoRow?['xp_otorgado'] as num?)?.toInt() ?? 0;
    await client.from('retos').update({'xp_otorgado': 0}).eq('id', retoId);
  }

  // ── Deshacer calorías transaccionales (solo retos fitness) ───────
  final esFitness = (retoRow?['tipo'] as String?) == 'fitness';
  if (esFitness) {
    await client.from('sesiones_registradas').delete().eq('id', retoId);
    ref.invalidate(perfilActividadProvider);
  }
  // ──────────────────────────────────────────────────────────────────

  await client.from('retos').update({
    'esta_completado': false,
  }).eq('id', retoId);

  if (user != null && xpRestar > 0) {
    await client.rpc('restar_xp',
        params: {'p_usuario_id': user.id, 'p_cantidad_xp': xpRestar});
  }

  _invalidarRetos(ref, retoId: retoId);
}

/// Elimina por completo un reto y sus hitos asociados.
Future<void> eliminarReto(String retoId, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  await client.from('hitos_de_reto').delete().eq('reto_id', retoId);

  var query = client.from('retos').delete().eq('id', retoId);
  if (user != null) query = query.eq('usuario_id', user.id);
  await query;

  _invalidarRetos(ref, retoId: retoId);
}

/// Edita los campos básicos de un reto (título, dificultad, asignatura y
/// fecha límite). No modifica los hitos.
Future<void> editarRetoSimple({
  required String retoId,
  required String titulo,
  required String dificultad,
  String? asignaturaId,
  required DateTime fechaFin,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  await client.from('retos').update({
    'titulo': titulo,
    'meta': titulo,
    'dificultad': dificultad,
    'tipo': asignaturaId != null ? 'academic' : 'fitness',
    'asignatura_id': asignaturaId,
    'fecha_fin': fechaFin.toIso8601String(),
  }).eq('id', retoId);

  _invalidarRetos(ref, retoId: retoId);
}

Future<void> toggleTareaCompletada(String hitoId, String retoId,
    {required bool completada, required WidgetRef ref}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  final hitoRow = await client
      .from('hitos_de_reto')
      .select('dificultad, xp_otorgado')
      .eq('id', hitoId)
      .maybeSingle();

  if (completada) {
    final yaXp = (hitoRow?['xp_otorgado'] as num?)?.toInt() ?? 0;
    final xp = yaXp == 0
        ? xpPorDificultad((hitoRow?['dificultad'] as String?) ?? 'media')
        : 0;
    await client.from('hitos_de_reto').update({
      'progreso_actual': 100,
      'esta_completado': true,
      'estado': 'completado',
      if (yaXp == 0) 'xp_otorgado': xp,
    }).eq('id', hitoId);
    if (user != null && xp > 0) {
      await otorgarXp(client, user.id, xp);
    }
  } else {
    final xp = (hitoRow?['xp_otorgado'] as num?)?.toInt() ?? 0;
    await client.from('hitos_de_reto').update({
      'progreso_actual': 0,
      'esta_completado': false,
      'estado': 'en_progreso',
      'xp_otorgado': 0,
    }).eq('id', hitoId);
    if (user != null && xp > 0) {
      await client.rpc('restar_xp',
          params: {'p_usuario_id': user.id, 'p_cantidad_xp': xp});
    }
  }

  // Completado bidireccional (de abajo hacia arriba): si todas las subtareas
  // están completas, el reto padre se completa; si no, queda activo.
  final restantes = await client
      .from('hitos_de_reto')
      .select('esta_completado')
      .eq('reto_id', retoId);
  final todasCompletas = (restantes as List).isNotEmpty &&
      restantes.every((h) => h['esta_completado'] == true);
  await client
      .from('retos')
      .update({'esta_completado': todasCompletas}).eq('id', retoId);

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

  // Referencia al propietario original (best-effort) para la distinción visual.
  final propId = retoMap['usuario_id'] as String?;
  String? propietarioNombre;
  if (propId != null) {
    final propRow = await client
        .from('usuarios')
        .select('nombre_completo')
        .eq('id', propId)
        .maybeSingle();
    propietarioNombre = propRow?['nombre_completo'] as String?;
  }

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
        'origen_id': retoId,
        if (propId != null) 'origen_propietario_id': propId,
        if (propietarioNombre != null)
          'origen_propietario_nombre': propietarioNombre,
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
          'id, reto_id, titulo, porcentaje_peso, indice_orden, progreso_actual, esta_completado, apunte_id, archivo_id')
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

// ───────────────────────────────────────────────────────────────────────────
// Helpers para cálculo calórico transaccional de retos fitness
// ───────────────────────────────────────────────────────────────────────────

double _metDesdeDificultad(String dificultad) => switch (dificultad) {
      'alta' => 8.0,
      'baja' => 3.0,
      _ => 4.5, // media
    };

int _segundosDesdeDificultad(String dificultad) => switch (dificultad) {
      'alta' => 1800, // 30 min
      'baja' => 600, // 10 min
      _ => 1200, // 20 min (media)
    };

int _estimarDuracionReto({
  List<dynamic>? hitos,
  required String dificultadReto,
}) {
  if (hitos == null || hitos.isEmpty) {
    return (_segundosDesdeDificultad(dificultadReto) ~/ 60);
  }

  var totalSeg = 0;
  for (final h in hitos) {
    final dif = (h['dificultad'] as String?) ?? 'media';
    totalSeg += _segundosDesdeDificultad(dif);
    totalSeg += 300; // 5 min de descanso entre tareas
  }
  return totalSeg ~/ 60;
}

double _calcularCaloriasReto({
  List<dynamic>? hitos,
  required String dificultadReto,
  required double pesoUsuarioKg,
}) {
  if (hitos == null || hitos.isEmpty) {
    return CalorieCalculatorService.calcular(
      valorMet: _metDesdeDificultad(dificultadReto),
      pesoUsuarioKg: pesoUsuarioKg,
      duracionSegundos: _segundosDesdeDificultad(dificultadReto),
    );
  }

  double total = 0;
  for (final h in hitos) {
    final met = _metDesdeDificultad((h['dificultad'] as String?) ?? 'media');
    final dur =
        _segundosDesdeDificultad((h['dificultad'] as String?) ?? 'media');
    total += CalorieCalculatorService.calcular(
      valorMet: met,
      pesoUsuarioKg: pesoUsuarioKg,
      duracionSegundos: dur,
    );
    total += CalorieCalculatorService.calcularDescanso(
      pesoUsuarioKg: pesoUsuarioKg,
      duracionSegundos: 300,
    );
  }
  return total;
}

Future<double> _obtenerPesoUsuario(SupabaseClient client) async {
  try {
    final user = client.auth.currentUser;
    if (user == null) return 70.0;
    final row = await client
        .from('perfil_bienestar_usuario')
        .select('peso_kg')
        .eq('usuario_id', user.id)
        .maybeSingle();
    final peso = (row?['peso_kg'] as num?)?.toDouble();
    return peso ?? 70.0;
  } catch (_) {
    return 70.0;
  }
}
