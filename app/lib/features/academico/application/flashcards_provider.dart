import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../infrastructure/sm2_calculator.dart';

final flashcardIndiceProvider = StateProvider.autoDispose<int>((ref) => 0);

final flashcardResultadosProvider =
    StateProvider.autoDispose<Map<int, bool>>((ref) => {});

final flashcardPreguntasProvider = FutureProvider.autoDispose
    .family<List<PreguntaDb>, String>((ref, materialId) async {
  final client = Supabase.instance.client;

  final bancoResult = await client
      .from('bancos_preguntas')
      .select()
      .eq('material_id', materialId)
      .maybeSingle();
  if (bancoResult == null) return [];
  final bancoId = bancoResult['id'] as String;

  final rows = await client
      .from('preguntas')
      .select()
      .eq('banco_id', bancoId)
      .order('orden');

  return (rows as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(PreguntaDb.fromMap)
      .toList();
});

final flashcardServicioProvider = Provider.autoDispose<FlashcardService>((ref) {
  return FlashcardService();
});

class FlashcardService {
  Future<void> aplicarSrs({
    required String materialId,
    required bool dominado,
  }) async {
    final client = Supabase.instance.client;
    final existing = await client
        .from('materiales_estudio')
        .select()
        .eq('id', materialId)
        .maybeSingle();
    if (existing == null) return;
    final material = MaterialEstudioDb.fromMap(existing);

    final calidad = dominado ? 4.0 : 0.0;
    final sm2 = Sm2Calculator.calcular(
      calidad: calidad,
      intervaloActualDias: material.intervaloActualDias,
      facilidad: material.facilidad,
      repasosCompletados: material.repasosCompletados,
    );
    final siguiente = DateTime.now().add(Duration(days: sm2.intervaloDias));

    await client.from('materiales_estudio').update({
      'estado_dominio': sm2.estadoDominio,
      'intervalo_actual_dias': sm2.intervaloDias,
      'facilidad': sm2.facilidad,
      'repasos_completados': sm2.repasosCompletados,
      'siguiente_repaso_en': siguiente.toIso8601String(),
      'ultimo_repaso_en': DateTime.now().toIso8601String(),
    }).eq('id', materialId);
  }
}
