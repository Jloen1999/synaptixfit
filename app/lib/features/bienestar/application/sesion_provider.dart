import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

final sesionesProvider =
    FutureProvider.autoDispose<List<SesionRegistradaDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('sesiones_registradas')
      .select()
      .eq('usuario_id', user.id)
      .order('completada_en', ascending: false)
      .limit(10);

  return data.map((e) => SesionRegistradaDb.fromMap(e)).toList();
});

final rutinasUsuarioProvider =
    FutureProvider.autoDispose<List<RutinaDb>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('rutinas')
      .select()
      .eq('usuario_id', user.id)
      .order('creado_en', ascending: false);

  return data.map((e) => RutinaDb.fromMap(e)).toList();
});

Future<SesionRegistradaDb?> registrarSesion({
  required String rutinaId,
  required int duracionMinutos,
  required int rpe,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final calorias = (duracionMinutos * rpe * 0.8).roundToDouble();

  final data = await client
      .from('sesiones_registradas')
      .insert({
        'usuario_id': user.id,
        'rutina_id': rutinaId,
        'duracion_minutos': duracionMinutos,
        'calorias_quemadas': calorias,
        'rpe': rpe,
        'completada_en': DateTime.now().toIso8601String(),
      })
      .select()
      .single();

  return SesionRegistradaDb.fromMap(data);
}
