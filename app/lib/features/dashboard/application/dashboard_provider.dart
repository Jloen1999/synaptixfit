import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/models/db_models.dart';

class DashboardData {
  const DashboardData({
    required this.usuario,
    required this.calorias,
    required this.sesiones,
    required this.horasEstudio,
    required this.retosActivos,
    required this.notificacionesNoLeidas,
    required this.progresosRetos,
    this.perfilBienestar,
    this.planSemanal,
  });

  final Map<String, double> progresosRetos;

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

  // Obtener usuario de la BD
  final usuarioMap =
      await client.from('usuarios').select().eq('id', user.id).maybeSingle();

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

  // Sesiones de hoy
  final now = DateTime.now();
  final hoyInicio = DateTime(now.year, now.month, now.day).toIso8601String();
  final sesionesHoy = await client
      .from('sesiones_registradas')
      .select()
      .eq('usuario_id', user.id)
      .gte('completada_en', hoyInicio);

  final caloriasHoy = (sesionesHoy as List).fold<int>(
    0,
    (total, s) => total + ((s['calorias_quemadas'] ?? 0) as num).round(),
  );

  // Retos activos
  final retosData = await client
      .from('retos')
      .select()
      .eq('usuario_id', user.id)
      .eq('esta_completado', false)
      .order('fecha_fin', ascending: true);

  final retos = (retosData as List)
      .map((r) => RetoDb.fromMap(r as Map<String, dynamic>))
      .toList();

  // Notificaciones no leídas
  final notifData = await client
      .from('notificaciones')
      .select()
      .eq('usuario_id', user.id)
      .eq('esta_leida', false)
      .order('creado_en', ascending: false);

  final notificaciones = (notifData as List)
      .map((n) => NotificacionDb.fromMap(n as Map<String, dynamic>))
      .toList();

  // Perfil bienestar
  final perfilMap = await client
      .from('perfil_bienestar_usuario')
      .select()
      .eq('usuario_id', user.id)
      .maybeSingle();

  final perfil =
      perfilMap != null ? PerfilBienestarDb.fromMap(perfilMap) : null;

  // Plan semanal
  final planMap = await client
      .from('plan_entrenamiento_semanal')
      .select()
      .eq('usuario_id', user.id)
      .eq('estado', 'activo')
      .maybeSingle();

  final plan =
      planMap != null ? PlanEntrenamientoSemanalDb.fromMap(planMap) : null;

  // Horas de estudio de hoy
  final hoyFin =
      DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
  final horariosHoy = await client
      .from('horarios_academicos')
      .select()
      .eq('usuario_id', user.id)
      .gte('hora_inicio', hoyInicio)
      .lte('hora_inicio', hoyFin);

  double horasEstudioCalculadas = 0;
  for (final horario in horariosHoy as List) {
    final inicio = DateTime.parse(horario['hora_inicio'].toString());
    final fin = DateTime.parse(horario['hora_fin'].toString());
    horasEstudioCalculadas += fin.difference(inicio).inMinutes / 60.0;
  }

  // Progreso de los retos activos
  final Map<String, double> progresos = {};
  for (final reto in retos) {
    try {
      final progressResult = await client
          .rpc('calcular_progreso_de_reto', params: {'p_reto_id': reto.id});
      progresos[reto.id] = (progressResult as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      progresos[reto.id] = 0.0;
    }
  }

  return DashboardData(
    usuario: usuario,
    calorias: caloriasHoy,
    sesiones: (sesionesHoy as List).length,
    horasEstudio: horasEstudioCalculadas,
    retosActivos: retos,
    notificacionesNoLeidas: notificaciones,
    progresosRetos: progresos,
    perfilBienestar: perfil,
    planSemanal: plan,
  );
});
