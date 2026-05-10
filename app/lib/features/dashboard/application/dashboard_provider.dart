import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/models/db_models.dart';
import '../../retos/application/retos_provider.dart';

class DashboardData {
  const DashboardData({
    required this.usuario,
    required this.calorias,
    required this.sesiones,
    required this.horasEstudio,
    required this.retosActivos,
    required this.notificacionesNoLeidas,
    required this.progresosRetos,
    required this.retosTienenHitos,
    this.perfilBienestar,
    this.planSemanal,
  });

  final Map<String, double> progresosRetos;
  final Map<String, bool> retosTienenHitos;

  final UsuarioDb usuario;
  final int calorias;
  final int sesiones;
  final double horasEstudio;
  final List<RetoDb> retosActivos;
  final List<NotificacionDb> notificacionesNoLeidas;
  final PerfilBienestarDb? perfilBienestar;
  final PlanEntrenamientoSemanalDb? planSemanal;

  int get racha => usuario.rachaActual;
  int get xpParaSiguienteNivel => 1000 * usuario.nivel;
  double get xpProgreso => usuario.xpTotal / xpParaSiguienteNivel;
  double progresoReto(String retoId) => progresosRetos[retoId] ?? 0.0;
  bool tieneHitosReto(String retoId) => retosTienenHitos[retoId] ?? false;

  int get sesionesRestantesSemana {
    if (planSemanal == null) return 0;
    return (planSemanal!.sesionesPlanificadas - sesiones).clamp(0, 7);
  }
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  if (!EnvConfig.hasSupabase) {
    throw Exception('Supabase no configurado');
  }

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    throw Exception('Sesión no activa');
  }

  final now = DateTime.now();
  final hoyInicio = DateTime(now.year, now.month, now.day).toIso8601String();
  final hoyFin =
      DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

  // Queries en paralelo con tipado explícito
  final (
    usuarioFuture,
    sesionesFuture,
    notifFuture,
    perfilFuture,
    planFuture,
    horariosFuture,
  ) = (
    client.from('usuarios').select().eq('id', user.id).maybeSingle(),
    client
        .from('sesiones_registradas')
        .select()
        .eq('usuario_id', user.id)
        .gte('completada_en', hoyInicio),
    client
        .from('notificaciones')
        .select()
        .eq('usuario_id', user.id)
        .eq('esta_leida', false)
        .order('creado_en', ascending: false),
    client
        .from('perfil_bienestar_usuario')
        .select()
        .eq('usuario_id', user.id)
        .maybeSingle(),
    client
        .from('plan_entrenamiento_semanal')
        .select()
        .eq('usuario_id', user.id)
        .eq('estado', 'activo')
        .maybeSingle(),
    client
        .from('horarios_academicos')
        .select()
        .eq('usuario_id', user.id)
        .gte('hora_inicio', hoyInicio)
        .lte('hora_inicio', hoyFin),
  );

  final results = await Future.wait<Object?>([
    usuarioFuture,
    sesionesFuture,
    notifFuture,
    perfilFuture,
    planFuture,
    horariosFuture,
  ]);

  final usuarioMap = results[0] as Map<String, dynamic>?;
  final sesionesHoy = results[1] as List<dynamic>;
  final notifData = results[2] as List<dynamic>;
  final perfilMap = results[3] as Map<String, dynamic>?;
  final planMap = results[4] as Map<String, dynamic>?;
  final horariosHoy = results[5] as List<dynamic>;

  final usuario = usuarioMap != null
      ? UsuarioDb.fromMap(usuarioMap)
      : UsuarioDb(
          id: user.id,
          email: user.email ?? '',
          nombreCompleto:
              user.userMetadata?['full_name']?.toString() ?? 'Usuario',
          urlAvatar: user.userMetadata?['avatar_url']?.toString(),
          nivel: 1,
          xpTotal: 0,
          rachaActual: 0,
          creadoEn: DateTime.now(),
          actualizadoEn: DateTime.now(),
        );

  final caloriasHoy = sesionesHoy.fold<int>(
    0,
    (total, s) => total + ((s['calorias_quemadas'] ?? 0) as num).round(),
  );

  final notificaciones = notifData
      .map((n) => NotificacionDb.fromMap(n as Map<String, dynamic>))
      .toList();

  final perfil =
      perfilMap != null ? PerfilBienestarDb.fromMap(perfilMap) : null;

  final plan =
      planMap != null ? PlanEntrenamientoSemanalDb.fromMap(planMap) : null;

  double horasEstudioCalculadas = 0;
  for (final horario in horariosHoy) {
    final inicio = DateTime.parse(horario['hora_inicio'].toString());
    final fin = DateTime.parse(horario['hora_fin'].toString());
    horasEstudioCalculadas += fin.difference(inicio).inMinutes / 60.0;
  }

  // Retos: reutiliza retosProvider (batch único, sin N+1 RPC)
  final retosResumen = await ref.watch(retosProvider.future);
  final retos = retosResumen.map((r) => r.reto).toList();
  final progresos = <String, double>{};
  final tienenHitos = <String, bool>{};
  for (final r in retosResumen) {
    progresos[r.reto.id] = r.progreso;
    tienenHitos[r.reto.id] = r.tieneHitos;
  }

  return DashboardData(
    usuario: usuario,
    calorias: caloriasHoy,
    sesiones: sesionesHoy.length,
    horasEstudio: horasEstudioCalculadas,
    retosActivos: retos,
    notificacionesNoLeidas: notificaciones,
    progresosRetos: progresos,
    retosTienenHitos: tienenHitos,
    perfilBienestar: perfil,
    planSemanal: plan,
  );
});
