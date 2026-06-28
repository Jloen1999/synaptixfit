import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/dominio_evento.dart';
import '../../../core/sync/sync_hub.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../insignias/application/insignias_provider.dart';

/// Marca un bloque de estudio como completado/no completado.
///
/// Efectos en cascada:
/// 1. Actualiza BD (completado, asistencia_registrada_en, xp_bloque_otorgado)
/// 2. Otorga XP: 10 XP por cada 30 min de bloque
/// 3. Recalcula carga_academica_semanal
/// 4. Dispara SyncHub.dispatch(bloqueEstudioCompletado)
Future<XpResultado?> toggleBloqueCompletado({
  required String bloqueId,
  required bool completado,
  required int duracionMinutos,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final ahora = DateTime.now().toIso8601String();

  await client
      .from('horarios_academicos')
      .update({
        'completado': completado,
        'asistencia_registrada_en': completado ? ahora : null,
      })
      .eq('id', bloqueId)
      .eq('usuario_id', user.id);

  XpResultado? xpResult;

  if (completado) {
    final bloqueData = await client
        .from('horarios_academicos')
        .select('xp_bloque_otorgado')
        .eq('id', bloqueId)
        .maybeSingle()
        .timeout(const Duration(seconds: 4));

    final yaOtorgado = bloqueData?['xp_bloque_otorgado'] as bool? ?? false;

    if (!yaOtorgado) {
      final xpGanado = (duracionMinutos / 30).ceil() * 10;
      xpResult = await otorgarXp(client, user.id, xpGanado);

      await client
          .from('horarios_academicos')
          .update({
            'xp_bloque_otorgado': true,
          })
          .eq('id', bloqueId)
          .eq('usuario_id', user.id);
    }
  }

  await syncCargaAcademicaSemanal(ref);

  ref.read(syncHubProvider).dispatch(
        DominioEvento.bloqueEstudioCompletado,
        payload:
            EventoPayload(bloqueId: bloqueId, duracionMinutos: duracionMinutos),
      );

  await evaluarInsignias(ref);

  return xpResult;
}
