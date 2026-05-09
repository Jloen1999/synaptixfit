import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

final planesEstudioProvider =
    FutureProvider.autoDispose<List<PlanEstudioDb>>((ref) async {
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

final bloquesPorPlanProvider = FutureProvider.autoDispose
    .family<List<HorarioAcademicoDb>, String>((ref, planId) async {
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

Future<PlanEstudioDb?> crearPlanEstudio({
  required String nombre,
  required DateTime semanaInicio,
  required DateTime semanaFin,
  String visibilidad = 'privado',
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

  return PlanEstudioDb.fromMap(data);
}

Future<void> eliminarPlanEstudio(String id) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  await client.from('planes_estudio').delete().eq('id', id).eq(
      'usuario_id', user!.id);
}

Future<HorarioAcademicoDb?> crearBloqueEstudio({
  required String asignaturaId,
  required DateTime horaInicio,
  required DateTime horaFin,
  String? planEstudioId,
  String? ubicacion,
  String prioridad = 'media',
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
      })
      .select()
      .single();

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

  await client
      .from('horarios_academicos')
      .update(updates)
      .eq('id', id)
      .eq('usuario_id', user!.id);
}

Future<void> eliminarBloqueEstudio(String id) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  await client
      .from('horarios_academicos')
      .delete()
      .eq('id', id)
      .eq('usuario_id', user!.id);
}
