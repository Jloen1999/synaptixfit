import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/connectivity_state.dart';
import '../infrastructure/connectivity_service.dart';
import '../infrastructure/offline_queue_service.dart';
import '../infrastructure/sync_merge_engine.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStateProvider = StreamProvider<ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStateChange;
});

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

final offlineQueueLengthProvider = Provider<int>((ref) {
  final service = ref.watch(offlineQueueServiceProvider);
  return service.longitud;
});

/// Motor de merge que resuelve conflictos multi-dispositivo.
/// Se construye con el cliente de Supabase y el servicio de cola offline.
final syncMergeEngineProvider = Provider<SyncMergeEngine>((ref) {
  final client = Supabase.instance.client;
  final queue = ref.watch(offlineQueueServiceProvider);
  return SyncMergeEngine(client: client, queueService: queue);
});

/// Progreso de sincronizacion como fraccion 0.0 a 1.0.
final syncProgressProvider = StateProvider<double>((ref) => 0.0);

/// Texto de progreso legible: "X/Y operaciones sincronizadas".
final syncProgressTextProvider = StateProvider<String>((ref) => '');

Future<void> sincronizarColaOffline(WidgetRef ref) async {
  final connService = ref.read(connectivityServiceProvider);
  final online = await connService.isOnline;
  if (!online) return;

  final mergeEngine = ref.read(syncMergeEngineProvider);
  final queueService = ref.read(offlineQueueServiceProvider);
  final total = queueService.longitud;

  if (total == 0) return;

  ref.read(syncProgressProvider.notifier).state = 0.01;

  await mergeEngine.procesarColaCompleta(
    onProgress: (procesadas, totalOps) {
      final progress = totalOps > 0 ? procesadas / totalOps : 1.0;
      ref.read(syncProgressProvider.notifier).state = progress.clamp(0.0, 1.0);
      ref.read(syncProgressTextProvider.notifier).state =
          '$procesadas/$totalOps operaciones sincronizadas';
    },
  );

  ref.read(syncProgressProvider.notifier).state = 1.0;
  ref.read(syncProgressTextProvider.notifier).state = '';
}
