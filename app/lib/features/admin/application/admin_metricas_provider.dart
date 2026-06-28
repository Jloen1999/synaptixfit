import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_kpi_dto.dart';
import '../infrastructure/admin_metricas_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositorio
// ─────────────────────────────────────────────────────────────────────────────

/// Proveedor del repositorio de métricas de administración.
final adminMetricasRepositoryProvider =
    Provider<AdminMetricasRepository>((ref) {
  return AdminMetricasRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// KPIs globales
// ─────────────────────────────────────────────────────────────────────────────

/// Métricas globales del panel de administración (usuarios, sesiones, etc.).
final adminMetricasProvider =
    FutureProvider<AdminMetricasGlobales>((ref) async {
  final repo = ref.watch(adminMetricasRepositoryProvider);
  return repo.obtenerMetricas();
});

// ─────────────────────────────────────────────────────────────────────────────
// Registros diarios para gráficos
// ─────────────────────────────────────────────────────────────────────────────

/// Serie temporal de sesiones diarias para los últimos [dias] días.
final adminRegistrosDiariosProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, dias) async {
  final repo = ref.watch(adminMetricasRepositoryProvider);
  return repo.obtenerRegistrosDiarios(dias);
});
