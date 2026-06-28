import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/models/timeline_item.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../retos/application/retos_core.dart';

final completionOverlayProvider = StateProvider<Map<String, bool>>((ref) => {});

/// Día seleccionado en las pestañas del timeline del inicio (por defecto hoy).
final selectedDiaProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

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
    // 3. Entregas (7 dias, incluye completadas)
    client
        .from('entregas_examenes')
        .select()
        .eq('usuario_id', user.id)
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
    // Exámenes/entregas se muestran vía la consulta de entregas_examenes;
    // evitamos duplicarlos desde su bloque del calendario.
    final tipoAct = map['tipo_actividad'] as String?;
    if (tipoAct == 'examen' || tipoAct == 'entrega') continue;
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

/// Línea de tiempo (tareas programadas) de un día concreto: horarios, sesiones
/// y entregas con fecha en ese día. Para HOY se usa [timelineHoyProvider], que
/// además incluye retos, hitos y el día de entrenamiento pendiente.
final timelineDiaProvider =
    FutureProvider.family<List<TimelineItem>, DateTime>((ref, dia) async {
  if (!EnvConfig.hasSupabase) return [];
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final inicio = DateTime(dia.year, dia.month, dia.day);
  final fin = DateTime(dia.year, dia.month, dia.day, 23, 59, 59);

  final res = await Future.wait([
    client
        .from('horarios_academicos')
        .select()
        .eq('usuario_id', user.id)
        .gte('hora_inicio', inicio.toIso8601String())
        .lte('hora_inicio', fin.toIso8601String())
        .order('hora_inicio', ascending: true),
    client
        .from('sesiones_registradas')
        .select()
        .eq('usuario_id', user.id)
        .gte('completada_en', inicio.toIso8601String())
        .lte('completada_en', fin.toIso8601String())
        .order('completada_en', ascending: true),
    client
        .from('entregas_examenes')
        .select()
        .eq('usuario_id', user.id)
        .gte('fecha_limite', inicio.toIso8601String())
        .lte('fecha_limite', fin.toIso8601String())
        .order('fecha_limite', ascending: true),
  ]);

  final items = <TimelineItem>[];
  for (final h in res[0] as List<dynamic>) {
    final map = h as Map<String, dynamic>;
    final tipoAct = map['tipo_actividad'] as String?;
    if (tipoAct == 'examen' || tipoAct == 'entrega') continue;
    items.add(TimelineItem.desdeHorario(HorarioAcademicoDb.fromMap(map)));
  }
  for (final s in res[1] as List<dynamic>) {
    items.add(TimelineItem.desdeSesion(
        SesionRegistradaDb.fromMap(s as Map<String, dynamic>)));
  }
  for (final e in res[2] as List<dynamic>) {
    items.add(TimelineItem.desdeEntrega(
        EntregaExamenDb.fromMap(e as Map<String, dynamic>)));
  }
  items.sort((a, b) => a.referenciaTemporal.compareTo(b.referenciaTemporal));
  return items;
});
