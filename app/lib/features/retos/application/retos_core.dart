import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/models/timeline_item.dart';

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

/// Traduce el nivel de dificultad/esfuerzo a XP (Baja 20 · Media 40 · Alta 70).
int xpPorDificultad(String dificultad) => switch (dificultad) {
      'baja' => 20,
      'alta' => 70,
      _ => 40,
    };

/// Provider que devuelve TODOS los retos del usuario (activos + completados + vencidos).
/// Útil para la vista unificada de retos con filtros de estado.
final todosRetosProvider = FutureProvider<List<RetoResumen>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final retosData = await client
      .from('retos')
      .select(
          'id, titulo, tipo, meta, visibilidad, esta_completado, fecha_inicio, fecha_fin, usuario_id, creado_en')
      .eq('usuario_id', user.id)
      .order('fecha_fin', ascending: true);

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

  final result = <RetoResumen>[];
  for (final reto in retos) {
    final hitos = hitosPorReto[reto.id] ?? [];
    if (hitos.isEmpty) {
      result.add(RetoResumen(
        reto: reto,
        progreso: reto.estaCompletado ? 1.0 : 0.0,
        tieneHitos: false,
      ));
    } else {
      final completados =
          hitos.where((h) => h['esta_completado'] == true).length;
      final total = hitos.length;
      double progresoSum = 0;
      double pesoTotal = 0;
      for (final h in hitos) {
        final peso = (h['porcentaje_peso'] as num?)?.toDouble() ?? 0.0;
        final prog = (h['progreso_actual'] as num?)?.toDouble() ?? 0.0;
        pesoTotal += peso;
        progresoSum += (prog / 100) * peso;
      }
      final progreso =
          pesoTotal > 0 ? progresoSum / pesoTotal : completados / total;
      result.add(RetoResumen(
        reto: reto,
        progreso: progreso,
        tieneHitos: true,
      ));
    }
  }
  return result;
});

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
      .gte('fecha_fin', DateTime.now().toIso8601String())
      .order('fecha_fin', ascending: true);

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

  final result = <RetoResumen>[];
  for (final reto in retos) {
    final hitos = hitosPorReto[reto.id] ?? [];
    if (hitos.isEmpty) {
      result.add(RetoResumen(
        reto: reto,
        progreso: reto.estaCompletado ? 1.0 : 0.0,
        tieneHitos: false,
      ));
    } else {
      final completados =
          hitos.where((h) => h['esta_completado'] == true).length;
      final total = hitos.length;
      double progresoSum = 0;
      double pesoTotal = 0;
      for (final h in hitos) {
        final peso = (h['porcentaje_peso'] as num?)?.toDouble() ?? 0.0;
        final prog = (h['progreso_actual'] as num?)?.toDouble() ?? 0.0;
        pesoTotal += peso;
        progresoSum += (prog / 100) * peso;
      }
      final progreso =
          pesoTotal > 0 ? progresoSum / pesoTotal : completados / total;
      result.add(RetoResumen(
        reto: reto,
        progreso: progreso,
        tieneHitos: true,
      ));
    }
  }
  return result;
});

final retosPublicosProvider = FutureProvider<List<RetoResumen>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final retosData = await client
      .from('retos')
      .select(
          'id, titulo, tipo, meta, visibilidad, esta_completado, fecha_inicio, fecha_fin, usuario_id, creado_en')
      .eq('visibilidad', 'public')
      .neq('usuario_id', user.id)
      .eq('esta_completado', false)
      .gte('fecha_fin', DateTime.now().toIso8601String())
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

final hitosPendientesProvider = FutureProvider<List<TimelineItem>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final retosData = await client
      .from('retos')
      .select('id, titulo, tipo, fecha_inicio, fecha_fin, esta_completado')
      .eq('usuario_id', user.id)
      .eq('esta_completado', false)
      .gte('fecha_fin', DateTime.now().toIso8601String());
  final retos = (retosData as List)
      .map((r) => RetoDb.fromMap(r as Map<String, dynamic>))
      .toList();
  if (retos.isEmpty) return [];

  final retoMap = {for (final r in retos) r.id: r};
  final retoIds = retos.map((r) => r.id).toList();

  final hitosData = await client
      .from('hitos_de_reto')
      .select()
      .inFilter('reto_id', retoIds)
      .eq('esta_completado', false)
      .or('estado.eq.disponible,estado.eq.en_progreso')
      .order('indice_orden', ascending: true);

  final result = <TimelineItem>[];
  for (final h in hitosData as List) {
    final hito = HitoRetoDb.fromMap(h as Map<String, dynamic>);
    final reto = retoMap[hito.retoId];
    if (reto != null) {
      result.add(TimelineItem.desdeHito(hito, reto));
    }
  }
  return result;
});
