import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../infrastructure/cross_regulation_service.dart';

// =============================================================================
// Providers de estado neurofisiológico (Fase 3: Fórmulas Neurofisiológicas)
// =============================================================================

/// Estado cognitivo actual del usuario (1:1 con usuarios).
///
/// Lee la tabla estado_cognitivo_usuario que se muta en tiempo real
/// al completar/desmarcar bloques de estudio.
final estadoCognitivoProvider =
    FutureProvider<EstadoCognitivoUsuarioDb?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('estado_cognitivo_usuario')
      .select()
      .eq('usuario_id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return EstadoCognitivoUsuarioDb.fromMap(data);
});

/// Estado de regulación cruzada actual del usuario.
///
/// Cache materializado con ACWR, carga aguda 7d, carga crónica 28d
/// y días hasta el próximo examen. Recalculado vía la RPC
/// recalcular_regulacion_cruzada() al completar/desmarcar sesiones.
final estadoRegulacionCruzadaProvider =
    FutureProvider<EstadoRegulacionCruzadaDb?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('estado_regulacion_cruzada')
      .select()
      .eq('usuario_id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return EstadoRegulacionCruzadaDb.fromMap(data);
});

/// Gasto calórico total de estudio hoy (kcal).
///
/// Suma en tiempo real de calorias_quemadas en horarios_academicos
/// filtrados por completado = true y fecha de hoy (hora local).
/// Sin columna acumulativa — prevención de contención de escritura.
final caloriasEstudioHoyProvider = FutureProvider<double>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;
  final ahora = DateTime.now();
  final inicio = DateTime(ahora.year, ahora.month, ahora.day);
  final fin = inicio.add(const Duration(days: 1));

  final result = await Supabase.instance.client
      .from('horarios_academicos')
      .select('calorias_quemadas')
      .eq('usuario_id', user.id)
      .eq('completado', true)
      .gte('hora_inicio', inicio.toIso8601String())
      .lt('hora_inicio', fin.toIso8601String());

  double suma = 0;
  for (final row in result) {
    suma += (row['calorias_quemadas'] as num?)?.toDouble() ?? 0;
  }
  return suma;
});

/// Carga física del día actual (AU = session_rpe × duración_minutos).
///
/// Suma de carga_diaria desde registros_carga_fisica para la fecha local.
final cargaFisicaHoyProvider = FutureProvider<double>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;

  final ahora = DateTime.now();
  final inicio =
      DateTime.utc(ahora.year, ahora.month, ahora.day).toIso8601String();
  final fin = DateTime.utc(ahora.year, ahora.month, ahora.day)
      .add(const Duration(days: 1))
      .toIso8601String();

  final result = await Supabase.instance.client
      .from('registros_carga_fisica')
      .select('carga_diaria')
      .eq('usuario_id', user.id)
      .gte('fecha_registro', inicio.substring(0, 10))
      .lt('fecha_registro', fin.substring(0, 10));

  double suma = 0;
  for (final row in result) {
    suma += (row['carga_diaria'] as num?)?.toDouble() ?? 0;
  }
  return suma;
});

/// Máxima carga física diaria histórica del usuario (AU).
///
/// Se usa como denominador en la fórmula Q_adj = Q_real + η · (carga_hoy / carga_max).
final cargaFisicaMaximaProvider = FutureProvider<double>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;
  final result = await Supabase.instance.client
      .from('registros_carga_fisica')
      .select('carga_diaria')
      .eq('usuario_id', user.id)
      .order('carga_diaria', ascending: false)
      .limit(1)
      .maybeSingle();
  return (result?['carga_diaria'] as num?)?.toDouble() ?? 0;
});

/// Tiempo máximo recomendado para un bloque de estudio (minutos).
///
/// Derivado del estado de regulación cruzada. Si el ACWR es normal
/// devuelve 90 min (default). Si hay sobrecarga física, aplica la
/// penalización logarítmica o el hard cap.
final tMaxEstudioProvider = Provider<int>((ref) {
  final cross = ref.watch(estadoRegulacionCruzadaProvider).valueOrNull;
  if (cross == null) return 90;
  return CrossRegulationService.calcularTmaxEstudio(
    tBaseMinutos: 90,
    acwr: cross.acwrActual,
  );
});
