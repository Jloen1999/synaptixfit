import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conteos rápidos por asignatura (apuntes y archivos) para las métricas en
/// miniatura del panel de asignaturas ("3 apuntes • 5 archivos").
typedef ConteosAsignatura = ({int apuntes, int archivos});

final conteosAsignaturaProvider =
    FutureProvider.family<ConteosAsignatura, String>((ref, asignaturaId) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return (apuntes: 0, archivos: 0);

  final apuntesData = await client
      .from('apuntes')
      .select('id')
      .eq('usuario_id', user.id)
      .eq('asignatura_id', asignaturaId);

  final archivosData = await client
      .from('archivos_asignatura')
      .select('id')
      .eq('usuario_id', user.id)
      .eq('asignatura_id', asignaturaId);

  return (
    apuntes: (apuntesData as List).length,
    archivos: (archivosData as List).length,
  );
});
