import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/models/timeline_item.dart';

/// Tareas de una asignatura (bloques del calendario + entregas/exámenes), desde
/// HOY en adelante, convertidas a [TimelineItem] y ordenadas cronológicamente.
///
/// Reutiliza el mismo modelo y los mismos factories que el timeline de la
/// pantalla de inicio ([timelineHoyProvider]), pero filtra estrictamente por
/// `asignatura_id`, de modo que la pantalla de detalle de asignatura muestre
/// únicamente los bloques de dicha asignatura siguiendo el mismo esquema.
final tareasAsignaturaProvider =
    FutureProvider.family<List<TimelineItem>, String>(
        (ref, asignaturaId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final ahora = DateTime.now();
  final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);

  final res = await Future.wait([
    // 1. Bloques del calendario de esta asignatura, desde hoy en adelante.
    client
        .from('horarios_academicos')
        .select()
        .eq('usuario_id', user.id)
        .eq('asignatura_id', asignaturaId)
        .gte('hora_inicio', inicioHoy.toIso8601String())
        .order('hora_inicio', ascending: true)
        .limit(100),
    // 2. Entregas y exámenes de esta asignatura, desde hoy en adelante.
    client
        .from('entregas_examenes')
        .select()
        .eq('usuario_id', user.id)
        .eq('asignatura_id', asignaturaId)
        .gte('fecha_limite', inicioHoy.toIso8601String())
        .order('fecha_limite', ascending: true)
        .limit(100),
  ]);

  final items = <TimelineItem>[];

  for (final h in res[0] as List<dynamic>) {
    final map = h as Map<String, dynamic>;
    // examen/entrega se muestran vía entregas_examenes para evitar duplicados.
    final tipoAct = map['tipo_actividad'] as String?;
    if (tipoAct == 'examen' || tipoAct == 'entrega') continue;
    items.add(TimelineItem.desdeHorario(HorarioAcademicoDb.fromMap(map)));
  }
  for (final e in res[1] as List<dynamic>) {
    items.add(TimelineItem.desdeEntrega(
        EntregaExamenDb.fromMap(e as Map<String, dynamic>)));
  }

  items.sort((a, b) => a.referenciaTemporal.compareTo(b.referenciaTemporal));
  return items;
});
