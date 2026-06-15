import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../sync/application/sync_provider.dart';
import '../../sync/domain/connectivity_state.dart';
import '../application/analitica_provider.dart';
import 'widgets/selector_periodo.dart';
import 'widgets/chart_rpe_tendencia.dart';
import 'widgets/chart_volumen_semanal.dart';
import 'widgets/chart_correlacion.dart';
import 'widgets/insight_card.dart';

// ---------------------------------------------------------------------------
// Pantalla principal de Analitica.
// Muestra graficos de tendencia, volumen y correlacion con selector de
// periodo (4, 12 o 52 semanas).
// ---------------------------------------------------------------------------

class AnaliticaScreen extends ConsumerWidget {
  const AnaliticaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStateProvider).valueOrNull;
    final metricasAsync = ref.watch(analiticaSemanalProvider);
    final insightAsync = ref.watch(correlacionCargaProvider);

    return FeatureScaffold(
      title: 'Analitica',
      child: metricasAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLoader(height: 60),
              SizedBox(height: 16),
              SkeletonLoader(height: 200),
              SizedBox(height: 16),
              SkeletonLoader(height: 200),
              SizedBox(height: 16),
              SkeletonLoader(height: 240),
            ],
          ),
        ),
        error: (error, _) {
          final msg = error.toString();
          final esErrorRed = msg.contains('SocketException') ||
              msg.contains('Failed host lookup') ||
              msg.contains('No address associated') ||
              connectivity == ConnectivityState.offline;

          return Center(
            child: EmptyState(
              title: esErrorRed ? 'Sin conexion' : 'Error al cargar',
              message: esErrorRed
                  ? 'No se pudo conectar con el servidor. Comprueba tu conexion a internet.'
                  : 'No se pudieron cargar las metricas de analitica.',
              icon:
                  esErrorRed ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
              action: TextButton(
                onPressed: () {
                  ref.invalidate(analiticaSemanalProvider);
                  ref.invalidate(correlacionCargaProvider);
                },
                child: const Text('Reintentar'),
              ),
            ),
          );
        },
        data: (metricas) {
          if (metricas.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.analytics_outlined,
                title: 'Sin datos de analitica',
                message:
                    'Completa sesiones de entrenamiento y registra tu carga academica para ver tus estadisticas.',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Selector de periodo
              const SelectorPeriodo(),
              const SizedBox(height: 20),

              // Grafico de tendencia de RPE
              const ChartRpeTendencia(),
              const SizedBox(height: 16),

              // Grafico de volumen semanal
              const ChartVolumenSemanal(),
              const SizedBox(height: 16),

              // Grafico de correlacion
              const ChartCorrelacion(),
              const SizedBox(height: 16),

              // Insight card de correlacion (si hay datos)
              insightAsync.when(
                loading: () => const SkeletonLoader(height: 140),
                error: (_, __) => const SizedBox.shrink(),
                data: (insight) {
                  if (insight == null) return const SizedBox.shrink();
                  return InsightCard(insight: insight);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
