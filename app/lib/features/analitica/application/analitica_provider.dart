import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/insight_correlacion_dto.dart';
import '../domain/metrica_semanal_dto.dart';
import '../domain/periodo_analitica.dart';
import '../infrastructure/analitica_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio
// ─────────────────────────────────────────────────────────────────────────────

/// Proveedor del repositorio de analitica. Se construye con el cliente
/// de Supabase para realizar las consultas.
final analiticaRepositoryProvider = Provider<AnaliticaRepository>((ref) {
  final client = Supabase.instance.client;
  return AnaliticaRepository(client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Periodo seleccionado (filtro de semanas)
// ─────────────────────────────────────────────────────────────────────────────

/// Permite alternar entre 4, 12 o 52 semanas de historico.
final periodoSeleccionadoProvider =
    StateProvider<PeriodoAnalitica>((ref) => PeriodoAnalitica.doceSemanas);

// ─────────────────────────────────────────────────────────────────────────────
// Metricas semanales (datos agregados)
// ─────────────────────────────────────────────────────────────────────────────

/// Obtiene las metricas semanales para el usuario autenticado,
/// filtrando por el periodo seleccionado.
final analiticaSemanalProvider =
    FutureProvider<List<MetricaSemanal>>((ref) async {
  if (!EnvConfig.hasSupabase) return [];

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final periodo = ref.watch(periodoSeleccionadoProvider);
  final repo = ref.watch(analiticaRepositoryProvider);

  return repo.obtenerMetricas(user.id, semanas: periodo.semanas);
});

// ─────────────────────────────────────────────────────────────────────────────
// Tendencia de RPE para grafico de linea
// ─────────────────────────────────────────────────────────────────────────────

/// Lista de pares {semana, rpe} ordenados por semana ascendente,
/// lista para alimentar un grafico de linea (eje X: semana, eje Y: rpe).
final tendenciaRpeProvider =
    FutureProvider<List<Map<String, double>>>((ref) async {
  final metricas = await ref.watch(analiticaSemanalProvider.future);

  // Ordenar ascendente para el grafico (semana mas antigua primero)
  final ordenadas = List<MetricaSemanal>.from(metricas)
    ..sort((a, b) => a.semanaInicio.compareTo(b.semanaInicio));

  return ordenadas.map((m) {
    // Usar el dia del mes como indice numerico relativo para el eje X
    final semanaIndex =
        m.semanaInicio.millisecondsSinceEpoch.toDouble() / 86400000.0;
    return {
      'semana': semanaIndex,
      'rpe': m.rpePromedio,
    };
  }).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Volumen semanal para grafico de barras
// ─────────────────────────────────────────────────────────────────────────────

/// Lista de pares {semana, minutos, calorias} para alimentar un grafico
/// de barras agrupadas (minutos y calorias por semana).
final volumenSemanalProvider =
    FutureProvider<List<Map<String, double>>>((ref) async {
  final metricas = await ref.watch(analiticaSemanalProvider.future);

  final ordenadas = List<MetricaSemanal>.from(metricas)
    ..sort((a, b) => a.semanaInicio.compareTo(b.semanaInicio));

  return ordenadas.map((m) {
    final semanaIndex =
        m.semanaInicio.millisecondsSinceEpoch.toDouble() / 86400000.0;
    return {
      'semana': semanaIndex,
      'minutos': m.minutosTotales.toDouble(),
      'calorias': m.caloriasTotales.toDouble(),
    };
  }).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Correlacion carga academica vs RPE
// ─────────────────────────────────────────────────────────────────────────────

/// Calcula la correlacion de Pearson entre horas de estudio y RPE promedio.
/// Retorna null si no hay suficientes datos.
final correlacionCargaProvider =
    FutureProvider<InsightCorrelacion?>((ref) async {
  if (!EnvConfig.hasSupabase) return null;

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final repo = ref.watch(analiticaRepositoryProvider);

  return repo.generarCorrelacionCargaVsRpe(user.id);
});

// ─────────────────────────────────────────────────────────────────────────────
// Puntos de correlacion para grafico de dispersion (scatter)
// ─────────────────────────────────────────────────────────────────────────────

/// Obtiene los pares {horasEstudio, rpe} para alimentar un grafico scatter
/// de correlacion carga academica vs rendimiento fisico.
final puntosCorrelacionProvider =
    FutureProvider<List<Map<String, double>>>((ref) async {
  if (!EnvConfig.hasSupabase) return [];

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final repo = ref.watch(analiticaRepositoryProvider);

  return repo.obtenerPuntosCorrelacion(user.id);
});
