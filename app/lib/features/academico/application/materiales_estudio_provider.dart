import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/db_models.dart';

final _cliente = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Repositorio ligero para consultar materiales_estudio directamente.
final materialesEstudioRepositoryProvider =
    Provider<MaterialesEstudioRepository>((ref) {
  return MaterialesEstudioRepository(ref.watch(_cliente));
});

class MaterialesEstudioRepository {
  final SupabaseClient _client;

  const MaterialesEstudioRepository(this._client);

  /// Obtiene todos los materiales de estudio de una asignatura.
  Future<List<MaterialEstudioDb>> obtenerPorAsignatura(
    String asignaturaId,
  ) async {
    final rows = await _client
        .from('materiales_estudio')
        .select()
        .eq('asignatura_id', asignaturaId)
        .order('creado_en', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MaterialEstudioDb.fromMap)
        .toList();
  }

  /// Busca un material por su fuente original (apunte o archivo).
  Future<MaterialEstudioDb?> obtenerPorFuente({
    required String tipoOrigen,
    required String origenId,
  }) async {
    final row = await _client
        .from('materiales_estudio')
        .select()
        .eq('tipo_origen', tipoOrigen)
        .eq('origen_id', origenId)
        .maybeSingle();
    if (row == null) return null;
    return MaterialEstudioDb.fromMap(row);
  }

  /// Vincula un apunte o archivo existente como material de estudio.
  /// Si ya existe (mismo origen), no hace nada.
  Future<MaterialEstudioDb?> vincular({
    required String asignaturaId,
    required String tipoOrigen,
    required String origenId,
    required String titulo,
  }) async {
    try {
      final rows = await _client
          .from('materiales_estudio')
          .upsert({
            'asignatura_id': asignaturaId,
            'tipo_origen': tipoOrigen,
            'origen_id': origenId,
            'titulo': titulo,
          })
          .select()
          .single();

      return MaterialEstudioDb.fromMap(rows);
    } catch (_) {
      return null;
    }
  }

  /// Actualiza el estado SM-2 de un material tras una evaluación.
  Future<void> actualizarEstadoSm2({
    required String materialId,
    required String estadoDominio,
    required int intervaloActualDias,
    required double facilidad,
    required int repasosCompletados,
    required DateTime siguienteRepasoEn,
    DateTime? ultimoRepasoEn,
  }) async {
    await _client.from('materiales_estudio').update({
      'estado_dominio': estadoDominio,
      'intervalo_actual_dias': intervaloActualDias,
      'facilidad': facilidad,
      'repasos_completados': repasosCompletados,
      'siguiente_repaso_en': siguienteRepasoEn.toIso8601String(),
      if (ultimoRepasoEn != null)
        'ultimo_repaso_en': ultimoRepasoEn.toIso8601String(),
    }).eq('id', materialId);
  }
}

/// Provider familia: materiales de estudio de una asignatura.
final materialesAsignaturaProvider = FutureProvider.autoDispose
    .family<List<MaterialEstudioDb>, String>((ref, asignaturaId) async {
  final repo = ref.watch(materialesEstudioRepositoryProvider);
  return repo.obtenerPorAsignatura(asignaturaId);
});

/// Busca el MaterialEstudioDb vinculado a una fuente (apunte/archivo).
final materialPorFuenteProvider = FutureProvider.autoDispose
    .family<MaterialEstudioDb?, ({String tipoOrigen, String origenId})>(
        (ref, key) async {
  final repo = ref.watch(materialesEstudioRepositoryProvider);
  return repo.obtenerPorFuente(
    tipoOrigen: key.tipoOrigen,
    origenId: key.origenId,
  );
});

/// Métricas de retención para una asignatura: conteo por estado_dominio.
final metricasRetencionProvider = FutureProvider.autoDispose.family<
    ({
      int dominados,
      int enCurso,
      int necesitaRepaso,
      int sinEvaluar,
      int total
    }),
    String>((ref, asignaturaId) async {
  final repo = ref.watch(materialesEstudioRepositoryProvider);
  final materiales = await repo.obtenerPorAsignatura(asignaturaId);
  final dominados =
      materiales.where((m) => m.estadoDominio == 'dominado').length;
  final enCurso =
      materiales.where((m) => m.estadoDominio == 'en_progreso').length;
  final necesitaRepaso =
      materiales.where((m) => m.estadoDominio == 'necesita_repaso').length;
  final sinEvaluar =
      materiales.where((m) => m.estadoDominio == 'sin_evaluar').length;
  return (
    dominados: dominados,
    enCurso: enCurso,
    necesitaRepaso: necesitaRepaso,
    sinEvaluar: sinEvaluar,
    total: materiales.length,
  );
});

/// Material con el siguiente_repaso_en más antiguo y vencido (< now())
/// a nivel global (todas las asignaturas). Nulo si no hay repasos urgentes.
final repasoUrgenteGlobalProvider =
    FutureProvider.autoDispose.family<MaterialEstudioDb?, void>((ref, _) async {
  final client = Supabase.instance.client;
  final row = await client
      .from('materiales_estudio')
      .select()
      .lt('siguiente_repaso_en', DateTime.now().toIso8601String())
      .order('siguiente_repaso_en')
      .limit(1)
      .maybeSingle();
  if (row == null) return null;
  return MaterialEstudioDb.fromMap(row);
});
