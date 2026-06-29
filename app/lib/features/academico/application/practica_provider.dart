import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/db_models.dart';

final _clientePractica =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

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

  /// Busca o crea un material y su banco de preguntas.
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

  /// Cuenta cuántas preguntas hay en un banco.
  Future<int> contarPreguntas(String bancoId) async {
    final result =
        await _client.from('preguntas').select('id').eq('banco_id', bancoId);
    return (result as List).length;
  }

  /// Elimina preguntas previas y guarda las nuevas generadas por IA.
  Future<void> guardarPreguntas(
    String bancoId,
    List<Map<String, dynamic>> preguntas,
  ) async {
    await _client.from('preguntas').delete().eq('banco_id', bancoId);

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < preguntas.length; i++) {
      final p = preguntas[i];
      rows.add({
        'banco_id': bancoId,
        'tipo': p['tipo'] as String? ?? 'opcion_multiple',
        'enunciado': p['enunciado'] as String? ?? '',
        'opciones': p['opciones'] as List<dynamic>?,
        'respuesta_correcta': p['respuesta_correcta'] as String? ?? '',
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

  /// Verifica si ya se otorgó XP por esta sesión y lo marca.
  Future<bool> otorgarXpSiProcede(String sessionId) async {
    final row = await _client
        .from('test_sessions')
        .select('xp_otorgado')
        .eq('id', sessionId)
        .single();

    if (row['xp_otorgado'] == true) return false;

    await _client
        .from('test_sessions')
        .update({'xp_otorgado': true}).eq('id', sessionId);
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

    final correctas = (intentos as List<dynamic>)
        .where((i) => i['es_correcta'] == true)
        .length;

    return (correctas: correctas, totales: preguntas.length);
  }

  // ═══════════════════════════════════════════════════════════════
  // Sesiones de práctica (TestSession)
  // ═══════════════════════════════════════════════════════════════

  /// Crea una nueva sesión de práctica con N preguntas del banco,
  /// priorizando las falladas anteriormente.
  Future<TestSessionDb> crearSesion({
    required String materialId,
    required String bancoId,
    int n = 10,
  }) async {
    final todas = await obtenerPreguntas(bancoId);
    if (todas.isEmpty) {
      throw Exception('El banco de preguntas está vacío.');
    }

    final intentos = await _client
        .from('intentos_pregunta')
        .select()
        .inFilter('pregunta_id', todas.map((p) => p.id).toList());

    final intentosPorPregunta = <String, List<Map<String, dynamic>>>{};
    for (final i in (intentos as List<dynamic>)) {
      final pid = i['pregunta_id'] as String;
      intentosPorPregunta.putIfAbsent(pid, () => []);
      intentosPorPregunta[pid]!.add(i as Map<String, dynamic>);
    }

    final falladas = <PreguntaDb>[];
    final noIntentadas = <PreguntaDb>[];
    final acertadas = <PreguntaDb>[];

    for (final p in todas) {
      final intentosP = intentosPorPregunta[p.id] ?? [];
      if (intentosP.isEmpty) {
        noIntentadas.add(p);
      } else if (intentosP.any((i) => i['es_correcta'] == true)) {
        acertadas.add(p);
      } else {
        falladas.add(p);
      }
    }

    falladas.shuffle();
    noIntentadas.shuffle();
    acertadas.shuffle();

    final seleccionadas = <PreguntaDb>[
      ...falladas,
      ...noIntentadas,
      ...acertadas,
    ].take(n).toList();
    seleccionadas.shuffle();

    final nReal = seleccionadas.length;
    final userId = _client.auth.currentUser?.id;
    final row = await _client
        .from('test_sessions')
        .insert({
          'material_id': materialId,
          'preguntas_ids': seleccionadas.map((p) => p.id).toList(),
          'total_preguntas': nReal,
          if (userId != null) 'usuario_id': userId,
        })
        .select()
        .single();

    return TestSessionDb.fromMap(row);
  }

  /// Busca una sesión activa (in_progress) para un material.
  Future<TestSessionDb?> obtenerSesionActiva(String materialId) async {
    final row = await _client
        .from('test_sessions')
        .select()
        .eq('material_id', materialId)
        .eq('status', 'in_progress')
        .order('iniciado_en', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return TestSessionDb.fromMap(row);
  }

  /// Obtiene las preguntas de una sesión (por sus IDs).
  Future<List<PreguntaDb>> obtenerPreguntasDeSesion(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client.from('preguntas').select().inFilter('id', ids);

    final preguntas = (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PreguntaDb.fromMap)
        .toList();

    return ids.map((id) => preguntas.firstWhere((p) => p.id == id)).toList();
  }

  /// Guarda el progreso de una sesión (respuestas, resultados, índice).
  Future<void> guardarProgresoSesion({
    required String sessionId,
    required Map<String, dynamic> respuestas,
    required Map<String, dynamic> resultados,
    required int indiceActual,
    required int score,
  }) async {
    await _client.from('test_sessions').update({
      'respuestas': respuestas,
      'resultados': resultados,
      'indice_actual': indiceActual,
      'score': score,
    }).eq('id', sessionId);
  }

  /// Marca una sesión como completada.
  Future<void> completarSesion(String sessionId, int score) async {
    await _client.from('test_sessions').update({
      'status': 'completed',
      'score': score,
      'completado_en': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }
}

/// Provider: banco de preguntas de un material (con sus preguntas).
final bancoPreguntasProvider = FutureProvider.autoDispose.family<
    ({BancoPreguntasDb banco, List<PreguntaDb> preguntas, int total}),
    String>((ref, materialId) async {
  final repo = ref.watch(practicaRepositoryProvider);
  final banco = await repo.obtenerOCrearBanco(materialId);
  final preguntas = await repo.obtenerPreguntas(banco.id);
  return (banco: banco, preguntas: preguntas, total: preguntas.length);
});

/// Provider: sesión activa de un material (si existe).
final sesionActivaProvider = FutureProvider.autoDispose
    .family<TestSessionDb?, String>((ref, materialId) async {
  final repo = ref.watch(practicaRepositoryProvider);
  return repo.obtenerSesionActiva(materialId);
});

/// Provider: preguntas cargadas para una sesión concreta.
final preguntasSesionProvider = FutureProvider.autoDispose
    .family<List<PreguntaDb>, String>((ref, sessionId) async {
  final repo = ref.watch(practicaRepositoryProvider);
  final session = await ref.watch(sesionSesionProvider(sessionId).future);
  return repo.obtenerPreguntasDeSesion(session.preguntasIds);
});

/// Provider interno: TestSession por ID.
final sesionSesionProvider = FutureProvider.autoDispose
    .family<TestSessionDb, String>((ref, sessionId) async {
  final client = Supabase.instance.client;
  final row =
      await client.from('test_sessions').select().eq('id', sessionId).single();
  return TestSessionDb.fromMap(row);
});
