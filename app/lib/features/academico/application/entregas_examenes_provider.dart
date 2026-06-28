import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/dominio_evento.dart';
import '../../../core/sync/sync_hub.dart';
import '../../../shared/models/db_models.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../dashboard/application/timeline_provider.dart';

final entregasExamenesProvider =
    FutureProvider<List<EntregaExamenDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('entregas_examenes')
      .select()
      .eq('usuario_id', user.id)
      .order('fecha_limite', ascending: true);

  return (data as List)
      .map((e) => EntregaExamenDb.fromMap(e as Map<String, dynamic>))
      .toList();
});

final entregasPendientesProvider =
    FutureProvider<List<EntregaExamenDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('entregas_examenes')
      .select()
      .eq('usuario_id', user.id)
      .eq('esta_completado', false)
      .order('fecha_limite', ascending: true);

  return (data as List)
      .map((e) => EntregaExamenDb.fromMap(e as Map<String, dynamic>))
      .toList();
});

final entregasDePlanProvider =
    FutureProvider.family<List<EntregaExamenDb>, String>((ref, planId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('entregas_examenes')
      .select()
      .eq('usuario_id', user.id)
      .eq('plan_estudio_id', planId)
      .order('fecha_limite', ascending: true);

  return (data as List)
      .map((e) => EntregaExamenDb.fromMap(e as Map<String, dynamic>))
      .toList();
});

Future<EntregaExamenDb?> crearEntrega({
  required String titulo,
  required String tipo,
  required DateTime fechaLimite,
  required String dificultad,
  String? asignaturaId,
  String? planEstudioId,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final data = await client
      .from('entregas_examenes')
      .insert({
        'usuario_id': user.id,
        'titulo': titulo,
        'tipo': tipo,
        'fecha_limite': fechaLimite.toIso8601String(),
        'dificultad': dificultad,
        if (asignaturaId != null) 'asignatura_id': asignaturaId,
        if (planEstudioId != null) 'plan_estudio_id': planEstudioId,
      })
      .select()
      .single();

  ref.invalidate(timelineHoyProvider);
  ref.invalidate(cargaAcademicaSemanalProvider);
  ref.invalidate(adherenciaAcademicaProvider);
  ref.invalidate(estadoEnergeticoProvider);
  ref.invalidate(contextoAcademicoProvider);
  return EntregaExamenDb.fromMap(data);
}

Future<void> actualizarEntrega({
  required String id,
  String? titulo,
  String? tipo,
  DateTime? fechaLimite,
  String? dificultad,
  String? asignaturaId,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  final updates = <String, dynamic>{};
  if (titulo != null) updates['titulo'] = titulo;
  if (tipo != null) updates['tipo'] = tipo;
  if (fechaLimite != null) {
    updates['fecha_limite'] = fechaLimite.toIso8601String();
  }
  if (dificultad != null) updates['dificultad'] = dificultad;
  if (asignaturaId != null) updates['asignatura_id'] = asignaturaId;

  if (updates.isNotEmpty) {
    await client
        .from('entregas_examenes')
        .update(updates)
        .eq('id', id)
        .eq('usuario_id', user!.id);
    ref.invalidate(timelineHoyProvider);
    ref.invalidate(cargaAcademicaSemanalProvider);
    ref.invalidate(adherenciaAcademicaProvider);
    ref.invalidate(estadoEnergeticoProvider);
    ref.invalidate(contextoAcademicoProvider);
  }
}

Future<void> eliminarEntrega(String id, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  await client
      .from('entregas_examenes')
      .delete()
      .eq('id', id)
      .eq('usuario_id', user!.id);

  ref.invalidate(timelineHoyProvider);
  ref.invalidate(cargaAcademicaSemanalProvider);
  ref.invalidate(adherenciaAcademicaProvider);
  ref.invalidate(estadoEnergeticoProvider);
  ref.invalidate(contextoAcademicoProvider);
}

Future<void> toggleEntregaCompletada(String id, bool completada,
    {required WidgetRef ref}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  await client
      .from('entregas_examenes')
      .update({
        'esta_completado': completada,
        'actualizado_en': DateTime.now().toIso8601String(),
      })
      .eq('id', id)
      .eq('usuario_id', user!.id);

  if (completada) {
    final data = await client
        .from('entregas_examenes')
        .select('xp_entrega_otorgado')
        .eq('id', id)
        .maybeSingle()
        .timeout(const Duration(seconds: 4));

    final yaOtorgado = data?['xp_entrega_otorgado'] as bool? ?? false;
    if (!yaOtorgado) {
      await otorgarXp(client, user.id, 30);
      await client
          .from('entregas_examenes')
          .update({
            'xp_entrega_otorgado': true,
          })
          .eq('id', id)
          .eq('usuario_id', user.id);
    }
  }

  await syncCargaAcademicaSemanal(ref);

  ref.read(syncHubProvider).dispatch(
        DominioEvento.entregaCompletada,
        payload: EventoPayload(entregaId: id),
      );
}
