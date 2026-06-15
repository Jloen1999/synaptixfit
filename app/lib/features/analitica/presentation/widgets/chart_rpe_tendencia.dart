import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../application/analitica_provider.dart';

// ---------------------------------------------------------------------------
// Grafico de linea que muestra la tendencia del RPE promedio por semana.
// Eje X: semanas. Eje Y: RPE (escala 1-10).
// ---------------------------------------------------------------------------

class ChartRpeTendencia extends ConsumerWidget {
  const ChartRpeTendencia({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tendencia = ref.watch(tendenciaRpeProvider);

    return tendencia.when(
      loading: () => const SkeletonLoader(height: 200),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (puntos) {
        if (puntos.isEmpty) {
          return const EmptyState(
            icon: Icons.show_chart_rounded,
            title: 'Sin datos de RPE',
            message:
                'Completa sesiones de entrenamiento para ver tu tendencia de RPE.',
          );
        }

        // Convertir datos a FlSpot
        final spots = <FlSpot>[];
        final labels = <int, String>{};
        for (var i = 0; i < puntos.length; i++) {
          final p = puntos[i];
          spots.add(FlSpot(i.toDouble(), p['rpe']!));

          // Crear etiqueta legible (ej: "S1", "S2", ...)
          labels[i] = 'S${i + 1}';
        }

        final minRpe = puntos.map((p) => p['rpe']!).reduce(
              (a, b) => a < b ? a : b,
            );
        final maxRpe = puntos.map((p) => p['rpe']!).reduce(
              (a, b) => a > b ? a : b,
            );

        return _ChartCard(
          title: 'Tendencia de RPE',
          subtitle: 'Evolucion del esfuerzo percibido por semana',
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: (minRpe - 1).clamp(0, 9).toDouble(),
                maxY: (maxRpe + 1).clamp(2, 10).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: SVColors.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 0.8,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: spots.length <= 12,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= puntos.length) {
                          return const SizedBox.shrink();
                        }
                        // Mostrar algunas etiquetas para no saturar
                        final step = (puntos.length / 5).ceil().clamp(1, 999);
                        if (idx % step != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx] ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              color: SVColors.onSurfaceMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: SVColors.onSurfaceMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final rpe = spot.y.toStringAsFixed(1);
                        return LineTooltipItem(
                          '${labels[idx] ?? ""}: RPE $rpe',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: SVColors.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 12,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: SVColors.secondary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: SVColors.secondary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return const _ChartCard(
      title: 'Tendencia de RPE',
      subtitle: 'Error al cargar los datos',
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No se pudieron cargar los datos de RPE.',
            style: TextStyle(color: SVColors.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget auxiliar: tarjeta contenedora de grafico
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: SVShapes.large16,
        side: BorderSide(
          color: SVColors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: SVColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: SVColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
