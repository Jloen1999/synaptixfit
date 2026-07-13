import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import 'practica_provider.dart';

final modoSeleccionActivoProvider = StateProvider<bool>((ref) => false);

final seleccionMaterialesProvider = StateProvider<Set<String>>((ref) => {});

final seleccionItemsProvider = StateProvider<Set<String>>((ref) => {});

final crearSesionCombinadaProvider = FutureProvider.autoDispose
    .family<TestSessionDb, List<String>>((ref, materialIds) async {
  final repo = ref.read(practicaRepositoryProvider);
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) throw Exception('Usuario no autenticado');

  final total = materialIds.length;
  final preguntasPorMaterial = <String>[];

  for (final mId in materialIds) {
    final banco = await repo.obtenerOCrearBanco(mId);
    final preguntas =
        await client.from('preguntas').select().eq('banco_id', banco.id);
    final all = (preguntas as List)
        .map((p) => PreguntaDb.fromMap(p as Map<String, dynamic>))
        .toList();
    final n = (20 / total).round().clamp(3, 15);

    final falladas = await client
        .from('intentos_pregunta')
        .select()
        .eq('usuario_id', user.id)
        .eq('es_correcta', false)
        .inFilter('pregunta_id', all.map((p) => p.id).toList());
    final falladasIds =
        (falladas as List).map((f) => f['pregunta_id'] as String).toSet();

    final priorizadas = <PreguntaDb>[];
    priorizadas.addAll(all.where((p) => falladasIds.contains(p.id)));
    priorizadas.addAll(all.where((p) => !falladasIds.contains(p.id)));
    priorizadas.shuffle();

    final tomadas = priorizadas.take(n).toList();
    preguntasPorMaterial.addAll(tomadas.map((p) => p.id));
  }

  final info = <String, dynamic>{};
  for (final mId in materialIds) {
    info[mId] = {
      'material_id': mId,
      'titulo': '', // se resuelve en UI
    };
  }

  final session = await repo.crearSesion(
    materialId: materialIds.first,
    bancoId: '',
    n: preguntasPorMaterial.length,
    preguntasPersonalizadas: preguntasPorMaterial,
    metadata: info,
  );

  return session;
});
