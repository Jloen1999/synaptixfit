import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Box de Hive para el caché inteligente (respuestas de IA, recomendaciones).
final hiveSmartCacheProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('smartcache');
});

/// Box de Hive para datos offline del dashboard.
final hiveOfflineDashProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('offline_dash');
});
