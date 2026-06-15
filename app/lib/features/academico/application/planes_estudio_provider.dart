import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../dashboard/application/timeline_provider.dart';

final planesEstudioProvider = FutureProvider<List<PlanEstudioDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('planes_estudio')
      .select()
      .eq('usuario_id', user.id)
      .order('semana_inicio', ascending: false);

  return data.map((e) => PlanEstudioDb.fromMap(e)).toList();
});

final bloquesPorPlanProvider =
    FutureProvider.family<List<HorarioAcademicoDb>, String>(
        (ref, planId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('horarios_academicos')
      .select()
      .eq('plan_estudio_id', planId)
      .eq('usuario_id', user.id)
      .order('hora_inicio', ascending: true);

  return data.map((e) => HorarioAcademicoDb.fromMap(e)).toList();
});

/// Provee los bloques del plan de estudio actual (esta semana), unificados
/// desde horarios_academicos con join a asignaturas y rutinas.
final bloquesPlanActualProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, planId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('horarios_academicos')
      .select(
          '*, asignaturas!inner(nombre), rutinas(nombre, objetivo, cantidad_ejercicios, estado)')
      .eq('plan_estudio_id', planId)
      .eq('usuario_id', user.id)
      .order('hora_inicio', ascending: true);

  return (data as List).cast<Map<String, dynamic>>();
});

/// Horarios de la semana actual del usuario (sin filtrar por plan).
final horariosSemanaActualProvider =
    FutureProvider<List<HorarioAcademicoDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final now = DateTime.now();
  final lunes = now.subtract(Duration(days: now.weekday - 1));
  final domingo = lunes.add(const Duration(days: 6));
  final lunesStr = lunes.toIso8601String().split('T')[0];
  final domingoStr =
      DateTime(domingo.year, domingo.month, domingo.day, 23, 59, 59)
          .toIso8601String();

  final data = await client
      .from('horarios_academicos')
      .select()
      .eq('usuario_id', user.id)
      .gte('hora_inicio', lunesStr)
      .lte('hora_inicio', domingoStr)
      .order('hora_inicio', ascending: true);

  return (data as List)
      .map((e) => HorarioAcademicoDb.fromMap(e as Map<String, dynamic>))
      .toList();
});

Future<PlanEstudioDb?> crearPlanEstudio({
  required String nombre,
  required DateTime semanaInicio,
  required DateTime semanaFin,
  String visibilidad = 'private',
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final data = await client
      .from('planes_estudio')
      .insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'semana_inicio': semanaInicio.toIso8601String().split('T')[0],
        'semana_fin': semanaFin.toIso8601String().split('T')[0],
        'visibilidad': visibilidad,
      })
      .select()
      .single();

  ref.invalidate(timelineHoyProvider);
  return PlanEstudioDb.fromMap(data);
}

Future<void> eliminarPlanEstudio(String id, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  await client
      .from('planes_estudio')
      .delete()
      .eq('id', id)
      .eq('usuario_id', user!.id);

  ref.invalidate(timelineHoyProvider);
}

Future<HorarioAcademicoDb?> crearBloqueEstudio({
  required String asignaturaId,
  required DateTime horaInicio,
  required DateTime horaFin,
  String? planEstudioId,
  String? ubicacion,
  String prioridad = 'media',
  String tipoActividad = 'estudio',
  String? rutinaId,
  String? temas,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final data = await client
      .from('horarios_academicos')
      .insert({
        'usuario_id': user.id,
        'asignatura_id': asignaturaId,
        'hora_inicio': horaInicio.toIso8601String(),
        'hora_fin': horaFin.toIso8601String(),
        'plan_estudio_id': planEstudioId,
        'ubicacion': ubicacion,
        'prioridad': prioridad,
        'tipo_actividad': tipoActividad,
        if (rutinaId != null) 'rutina_id': rutinaId,
        if (temas != null) 'temas': temas,
      })
      .select()
      .single();

  ref.invalidate(timelineHoyProvider);
  return HorarioAcademicoDb.fromMap(data);
}

Future<void> actualizarBloqueEstudio({
  required String id,
  String? asignaturaId,
  DateTime? horaInicio,
  DateTime? horaFin,
  String? planEstudioId,
  String? ubicacion,
  String? prioridad,
  String? tipoActividad,
  String? rutinaId,
  String? temas,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  final updates = <String, dynamic>{};
  if (asignaturaId != null) updates['asignatura_id'] = asignaturaId;
  if (horaInicio != null) updates['hora_inicio'] = horaInicio.toIso8601String();
  if (horaFin != null) updates['hora_fin'] = horaFin.toIso8601String();
  if (planEstudioId != null) updates['plan_estudio_id'] = planEstudioId;
  if (ubicacion != null) updates['ubicacion'] = ubicacion;
  if (prioridad != null) updates['prioridad'] = prioridad;
  if (tipoActividad != null) updates['tipo_actividad'] = tipoActividad;
  if (rutinaId != null) updates['rutina_id'] = rutinaId;
  if (temas != null) updates['temas'] = temas;

  await client
      .from('horarios_academicos')
      .update(updates)
      .eq('id', id)
      .eq('usuario_id', user!.id);

  ref.invalidate(timelineHoyProvider);
}

Future<void> eliminarBloqueEstudio(String id, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  await client
      .from('horarios_academicos')
      .delete()
      .eq('id', id)
      .eq('usuario_id', user!.id);

  ref.invalidate(timelineHoyProvider);
}

/// Crea un plan completo con entregas y bloques en una sola operación.
/// Retorna el ID del plan creado.
Future<String?> crearPlanCompleto({
  required String nombre,
  required DateTime semanaInicio,
  required DateTime semanaFin,
  String visibilidad = 'private',
  List<Map<String, dynamic>> entregas = const [],
  List<Map<String, dynamic>> bloques = const [],
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final planData = await client
      .from('planes_estudio')
      .insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'semana_inicio': semanaInicio.toIso8601String().split('T')[0],
        'semana_fin': semanaFin.toIso8601String().split('T')[0],
        'visibilidad': visibilidad,
      })
      .select('id')
      .single();

  final planId = planData['id'] as String;

  if (entregas.isNotEmpty) {
    final rows = entregas.map((e) => {
          'usuario_id': user.id,
          'plan_estudio_id': planId,
          'titulo': e['titulo'],
          'tipo': e['tipo'],
          'fecha_limite': e['fecha_limite'],
          'dificultad': e['dificultad'],
          if (e['asignatura_id'] != null) 'asignatura_id': e['asignatura_id'],
        });
    await client.from('entregas_examenes').insert(rows.toList());
  }

  if (bloques.isNotEmpty) {
    final rows = bloques.map((b) {
      final dia = b['dia_semana'] as int;
      final horaInicio =
          _fechaDesdeDiaYHora(semanaInicio, dia, b['hora_inicio'] as String);
      final horaFin =
          _fechaDesdeDiaYHora(semanaInicio, dia, b['hora_fin'] as String);
      return {
        'usuario_id': user.id,
        'plan_estudio_id': planId,
        'asignatura_id': b['asignatura_id'],
        'hora_inicio': horaInicio.toIso8601String(),
        'hora_fin': horaFin.toIso8601String(),
        'prioridad': b['prioridad'] ?? 'media',
        'tipo_actividad': b['tipo_actividad'] ?? 'estudio',
        if (b['rutina_id'] != null) 'rutina_id': b['rutina_id'],
        if (b['temas'] != null) 'temas': b['temas'],
        if (b['ubicacion'] != null) 'ubicacion': b['ubicacion'],
      };
    });
    await client.from('horarios_academicos').insert(rows.toList());
  }

  ref.invalidate(timelineHoyProvider);
  return planId;
}

/// Añade un bloque rápido al plan actual desde la vista principal.
Future<HorarioAcademicoDb?> crearBloqueRapido({
  required String planEstudioId,
  required String asignaturaId,
  required int diaSemana,
  required String horaInicio,
  required String horaFin,
  String tipoActividad = 'estudio',
  String? rutinaId,
  String? temas,
  String prioridad = 'media',
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final now = DateTime.now();
  final lunes = now.subtract(Duration(days: now.weekday - 1));
  final inicio = _fechaDesdeDiaYHora(lunes, diaSemana, horaInicio);
  final fin = _fechaDesdeDiaYHora(lunes, diaSemana, horaFin);

  final data = await client
      .from('horarios_academicos')
      .insert({
        'usuario_id': user.id,
        'plan_estudio_id': planEstudioId,
        'asignatura_id': asignaturaId,
        'hora_inicio': inicio.toIso8601String(),
        'hora_fin': fin.toIso8601String(),
        'prioridad': prioridad,
        'tipo_actividad': tipoActividad,
        if (rutinaId != null) 'rutina_id': rutinaId,
        if (temas != null) 'temas': temas,
      })
      .select()
      .single();

  ref.invalidate(timelineHoyProvider);
  return HorarioAcademicoDb.fromMap(data);
}

DateTime _fechaDesdeDiaYHora(DateTime lunes, int diaSemana, String hora) {
  final fecha = lunes.add(Duration(days: diaSemana - 1));
  final partes = hora.split(':');
  return DateTime(
    fecha.year,
    fecha.month,
    fecha.day,
    int.parse(partes[0]),
    int.parse(partes[1]),
  );
}
