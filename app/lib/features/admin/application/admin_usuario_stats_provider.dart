import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_timeline_dto.dart';
import '../domain/admin_usuario_estadisticas_dto.dart';
import '../infrastructure/admin_usuario_stats_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio
// ─────────────────────────────────────────────────────────────────────────────

/// Proveedor del repositorio de estadísticas de usuario.
final adminUsuarioStatsRepositoryProvider =
    Provider<AdminUsuarioStatsRepository>((ref) {
  return AdminUsuarioStatsRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Estadísticas de RPE semanal
// ─────────────────────────────────────────────────────────────────────────────

/// Serie temporal de RPE promedio semanal para un usuario específico.
final adminRpeSemanalProvider =
    FutureProvider.family<List<AdminDataPoint>, String>((ref, usuarioId) async {
  final repo = ref.watch(adminUsuarioStatsRepositoryProvider);
  return repo.obtenerRpeSemanal(usuarioId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Estadísticas de volumen semanal
// ─────────────────────────────────────────────────────────────────────────────

/// Serie temporal de volumen en minutos semanal para un usuario específico.
final adminVolumenSemanalProvider =
    FutureProvider.family<List<AdminDataPoint>, String>((ref, usuarioId) async {
  final repo = ref.watch(adminUsuarioStatsRepositoryProvider);
  return repo.obtenerVolumenSemanal(usuarioId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Línea de tiempo del usuario
// ─────────────────────────────────────────────────────────────────────────────

/// Línea de tiempo paginada de un usuario. El parámetro [params] incluye
/// el ID del usuario y la página.
final adminTimelineUsuarioProvider = FutureProvider.family<
    List<AdminTimelineEntry>, ({String usuarioId, int page})>(
  (ref, params) async {
    final repo = ref.watch(adminUsuarioStatsRepositoryProvider);
    return repo.obtenerTimeline(params.usuarioId, page: params.page);
  },
);
