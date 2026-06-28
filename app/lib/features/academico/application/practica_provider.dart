import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/db_models.dart';

final _clientePractica =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Repositorio para bancos de preguntas, preguntas e intentos.
final practicaRepositoryProvider = Provider<PracticaRepository>((ref) {
  return PracticaRepository(ref.watch(_clientePractica));
});

class PracticaRepository {
  final SupabaseClient _client;

  const PracticaRepository(this._client);

  /// Obtiene o crea un banco de preguntas para un material.
  Future<BancoPreguntasDb> obtenerOCrearBanco(String materialId) async {
    final existentes = await _client
        .from('bancos_preguntas')
        .select()
        .eq('material_id', materialId)
        .limit(1);

    if (existentes.isNotEmpty) {
      return BancoPreguntasDb.fromMap(existentes.first);
    }

    final userId = _client.auth.currentUser?.id;
    final row = await _client
        .from('bancos_preguntas')
        .insert({
          'material_id': materialId,
          if (userId != null) 'usuario_id': userId,
        })
        .select()
        .single();

    return BancoPreguntasDb.fromMap(row);
  }

  /// Busca o crea un material de estudio y luego su banco de preguntas.
  Future<BancoPreguntasDb> obtenerOCrearBancoPorFuente({
    required String tipoOrigen,
    required String origenId,
    String? asignaturaId,
    required String titulo,
  }) async {
    final materiales = await _client
        .from('materiales_estudio')
        .select()
        .eq('tipo_origen', tipoOrigen)
        .eq('origen_id', origenId)
        .limit(1);

    String materialId;
    if (materiales.isNotEmpty) {
      materialId = materiales.first['id'] as String;
    } else {
      final userId = _client.auth.currentUser?.id;
      final nuevo = await _client
          .from('materiales_estudio')
          .insert({
            if (asignaturaId != null) 'asignatura_id': asignaturaId,
            if (userId != null) 'usuario_id': userId,
            'tipo_origen': tipoOrigen,
            'origen_id': origenId,
            'titulo': titulo,
          })
          .select()
          .single();
      materialId = nuevo['id'] as String;
    }

    return obtenerOCrearBanco(materialId);
  }

  /// Obtiene las preguntas de un banco.
  Future<List<PreguntaDb>> obtenerPreguntas(String bancoId) async {
    final rows = await _client
        .from('preguntas')
        .select()
        .eq('banco_id', bancoId)
        .order('orden');

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PreguntaDb.fromMap)
        .toList();
  }

  /// Guarda un conjunto de preguntas generadas por IA para un banco.
  Future<void> guardarPreguntas(
    String bancoId,
    List<Map<String, dynamic>> preguntas,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < preguntas.length; i++) {
      final p = preguntas[i];
      rows.add({
        'banco_id': bancoId,
        'tipo': p['tipo'] as String? ?? 'opcion_multiple',
        'enunciado': p['enunciado'] as String? ?? '',
        'opciones': p['opciones'] as List<dynamic>?,
        'respuesta_correcta':
            p['respuesta_correcta'] as String? ?? '',
        'explicacion': p['explicacion'] as String?,
        'orden': i,
      });
    }
    await _client.from('preguntas').insert(rows);
  }

  /// Registra un intento del usuario en una pregunta.
  Future<void> registrarIntento({
    required String preguntaId,
    required bool esCorrecta,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('intentos_pregunta').insert({
      'pregunta_id': preguntaId,
      'es_correcta': esCorrecta,
      if (userId != null) 'usuario_id': userId,
    });
  }

  /// Verifica si ya se otorgó XP por este banco y lo marca.
  Future<bool> otorgarXpSiProcede(String bancoId) async {
    final row = await _client
        .from('bancos_preguntas')
        .select('xp_otorgado')
        .eq('id', bancoId)
        .single();

    if (row['xp_otorgado'] == true) return false;

    await _client
        .from('bancos_preguntas')
        .update({'xp_otorgado': true}).eq('id', bancoId);
    return true;
  }

  /// Cuenta intentos correctos y totales de un banco.
  Future<({int correctas, int totales})> estadisticasBanco(
    String bancoId,
  ) async {
    final preguntas = await obtenerPreguntas(bancoId);
    if (preguntas.isEmpty) return (correctas: 0, totales: 0);

    final ids = preguntas.map((p) => p.id).toList();
    final intentos = await _client
        .from('intentos_pregunta')
        .select()
        .inFilter('pregunta_id', ids);

    final correctas =
        (intentos as List<dynamic>).where((i) => i['es_correcta'] == true).length;

    return (correctas: correctas, totales: preguntas.length);
  }
}

/// Provider: banco de preguntas de un material (con sus preguntas).
final bancoPreguntasProvider = FutureProvider.autoDispose
    .family<({BancoPreguntasDb banco, List<PreguntaDb> preguntas}), String>(
        (ref, materialId) async {
  final repo = ref.watch(practicaRepositoryProvider);
  final banco = await repo.obtenerOCrearBanco(materialId);
  final preguntas = await repo.obtenerPreguntas(banco.id);
  return (banco: banco, preguntas: preguntas);
});
