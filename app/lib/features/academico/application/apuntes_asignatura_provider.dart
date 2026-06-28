import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';

/// Apuntes (notas de texto/Markdown) de una asignatura concreta, propios del
/// usuario, ordenados por última modificación.
final apuntesPorAsignaturaProvider =
    FutureProvider.family<List<ApunteDb>, String>((ref, asignaturaId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('apuntes')
      .select()
      .eq('usuario_id', user.id)
      .eq('asignatura_id', asignaturaId)
      .order('actualizado_en', ascending: false);

  return (data as List)
      .map((e) => ApunteDb.fromMap(e as Map<String, dynamic>))
      .toList();
});
