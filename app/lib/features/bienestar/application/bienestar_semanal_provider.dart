import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

class BienestarSemanalDto {
  const BienestarSemanalDto({
    this.plan,
    required this.sesionesCompletadas,
    required this.sesionesPlanificadas,
    required this.cumplimiento,
    required this.cumplimientoAnterior,
    required this.sugerencia,
  });

  final PlanEntrenamientoSemanalDb? plan;
  final int sesionesCompletadas;
  final int sesionesPlanificadas;
  final double cumplimiento;
  final double cumplimientoAnterior;
  final String sugerencia;

  String get tendencia {
    final dif = cumplimiento - cumplimientoAnterior;
    if (dif > 0.05) return 'Mejorando';
    if (dif < -0.05) return 'Bajando';
    return 'Estable';
  }

  String get proximaAccion {
    if (plan == null) return 'Define un plan de entrenamiento desde tu perfil.';
    if (cumplimiento >= 1.0) return '¡Objetivo cumplido! Mantén el ritmo.';
    if (cumplimiento >= 0.7) return 'Vas bien. Intenta completar las sesiones pendientes.';
    if (cumplimiento >= 0.4) return 'Recupera el ritmo. Programa sesiones más cortas si es necesario.';
    return 'Revisa tu plan. Quizás necesitas ajustar la carga semanal.';
  }
}

final bienestarSemanalProvider =
    FutureProvider.autoDispose<BienestarSemanalDto>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    return const BienestarSemanalDto(
      sesionesCompletadas: 0,
      sesionesPlanificadas: 0,
      cumplimiento: 0,
      cumplimientoAnterior: 0,
      sugerencia: 'Inicia sesión para ver tu progreso.',
    );
  }

  // Calcular lunes de esta semana
  final now = DateTime.now();
  final lunesEstaSemana = now.subtract(Duration(days: now.weekday - 1));
  final lunesSemanaAnterior = lunesEstaSemana.subtract(const Duration(days: 7));

  // Plan de esta semana
  final planData = await client
      .from('plan_entrenamiento_semanal')
      .select()
      .eq('usuario_id', user.id)
      .eq('semana_inicio', lunesEstaSemana.toIso8601String().split('T')[0])
      .maybeSingle();

  final plan = planData != null
      ? PlanEntrenamientoSemanalDb.fromMap(planData)
      : null;
  final sesionesPlanificadas = plan?.sesionesPlanificadas ?? 0;

  // Sesiones completadas esta semana
  final inicioSemana = lunesEstaSemana.toIso8601String();
  final sesionesData = await client
      .from('sesiones_registradas')
      .select('id')
      .eq('usuario_id', user.id)
      .gte('completada_en', inicioSemana)
      .lt('completada_en',
          lunesEstaSemana.add(const Duration(days: 7)).toIso8601String());

  final sesionesCompletadas = (sesionesData as List).length;

  final cumplimiento = sesionesPlanificadas > 0
      ? (sesionesCompletadas / sesionesPlanificadas).clamp(0.0, 1.0)
      : 0.0;

  // Cumplimiento semana anterior
  final sesionesDataAnterior = await client
      .from('sesiones_registradas')
      .select('id')
      .eq('usuario_id', user.id)
      .gte('completada_en', lunesSemanaAnterior.toIso8601String())
      .lt('completada_en', lunesEstaSemana.toIso8601String());

  final planAnteriorData = await client
      .from('plan_entrenamiento_semanal')
      .select('sesiones_planificadas')
      .eq('usuario_id', user.id)
      .eq('semana_inicio', lunesSemanaAnterior.toIso8601String().split('T')[0])
      .maybeSingle();

  final sesionesAnterior = (sesionesDataAnterior as List).length;
  final planAnterior =
      planAnteriorData?['sesiones_planificadas'] as int? ?? 0;
  final cumplimientoAnterior = planAnterior > 0
      ? (sesionesAnterior / planAnterior).clamp(0.0, 1.0)
      : 0.0;

  // Sugerencia
  String sugerencia;
  if (plan == null) {
    sugerencia = 'Completa tu perfil de bienestar para recibir un plan semanal.';
  } else if (cumplimiento >= 1.0) {
    sugerencia = '¡Semana completada! Buen trabajo.';
  } else {
    final pendientes = sesionesPlanificadas - sesionesCompletadas;
    if (pendientes > 0) {
      sugerencia = 'Te quedan $pendientes sesiones esta semana. ¡Ánimo!';
    } else {
      sugerencia = 'Sin sesiones pendientes.';
    }
  }

  return BienestarSemanalDto(
    plan: plan,
    sesionesCompletadas: sesionesCompletadas,
    sesionesPlanificadas: sesionesPlanificadas,
    cumplimiento: cumplimiento,
    cumplimientoAnterior: cumplimientoAnterior,
    sugerencia: sugerencia,
  );
});
