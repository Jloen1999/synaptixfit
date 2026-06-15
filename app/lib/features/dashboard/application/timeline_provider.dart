import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/models/timeline_item.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../retos/application/retos_core.dart';

/// Linea de tiempo unificada para HOY con retos y dia pendiente.
final timelineHoyProvider = FutureProvider<List<TimelineItem>>((ref) async {
  if (!EnvConfig.hasSupabase) return [];

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final ahora = DateTime.now();
  final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
  final finHoy = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
  final finSemana = inicioHoy.add(const Duration(days: 7));

  // 5 queries en paralelo
  final resultados = await Future.wait([
    // 1. Horarios academicos de hoy
    client
        .from('horarios_academicos')
        .select()
        .eq('usuario_id', user.id)
        .gte('hora_inicio', inicioHoy.toIso8601String())
        .lte('hora_inicio', finHoy.toIso8601String())
        .order('hora_inicio', ascending: true),
    // 2. Sesiones registradas hoy
    client
        .from('sesiones_registradas')
        .select()
        .eq('usuario_id', user.id)
        .gte('completada_en', inicioHoy.toIso8601String())
        .lte('completada_en', finHoy.toIso8601String())
        .order('completada_en', ascending: true),
    // 3. Entregas pendientes (7 dias, no completadas)
    client
        .from('entregas_examenes')
        .select()
        .eq('usuario_id', user.id)
        .eq('esta_completado', false)
        .gte('fecha_limite', inicioHoy.toIso8601String())
        .lte('fecha_limite', finSemana.toIso8601String())
        .order('fecha_limite', ascending: true)
        .limit(20),
    // 4. Retos activos
    client
        .from('retos')
        .select()
        .eq('usuario_id', user.id)
        .eq('esta_completado', false)
        .order('fecha_fin', ascending: true)
        .limit(5),
  ]);

  final items = <TimelineItem>[];

  for (final h in resultados[0] as List<dynamic>) {
    final map = h as Map<String, dynamic>;
    items.add(TimelineItem.desdeHorario(HorarioAcademicoDb.fromMap(map)));
  }
  for (final s in resultados[1] as List<dynamic>) {
    final map = s as Map<String, dynamic>;
    items.add(TimelineItem.desdeSesion(SesionRegistradaDb.fromMap(map)));
  }
  for (final e in resultados[2] as List<dynamic>) {
    final map = e as Map<String, dynamic>;
    items.add(TimelineItem.desdeEntrega(EntregaExamenDb.fromMap(map)));
  }
  // 4. Retos activos
  for (final r in resultados[3] as List<dynamic>) {
    final map = r as Map<String, dynamic>;
    final reto = RetoDb.fromMap(map);
    items.add(TimelineItem.desdeReto(reto));
  }

  // 4b. Hitos pendientes de retos complejos
  final hitosAsync = ref.watch(hitosPendientesProvider);
  if (hitosAsync.hasValue) {
    items.addAll(hitosAsync.value!);
  }

  // 5. Dia de entrenamiento pendiente
  final diaPend = ref.watch(diaPendienteProvider).valueOrNull;
  if (diaPend != null) {
    items.add(TimelineItem.desdeDiaPendiente(diaPend));
  }

  items.sort((a, b) => a.referenciaTemporal.compareTo(b.referenciaTemporal));

  return items;
});
