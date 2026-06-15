import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../application/analitica_provider.dart';

// ---------------------------------------------------------------------------
// Grafico de dispersion (scatter) que muestra la correlacion entre
// horas de estudio (eje X) y RPE promedio (eje Y) por semana.
// Incluye linea de tendencia y resumen del coeficiente.
// ---------------------------------------------------------------------------

class ChartCorrelacion extends ConsumerWidget {
  const ChartCorrelacion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puntosAsync = ref.watch(puntosCorrelacionProvider);
    final insightAsync = ref.watch(correlacionCargaProvider);

    return puntosAsync.when(
      loading: () => const SkeletonLoader(height: 240),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (puntos) {
        if (puntos.isEmpty) {
          return const EmptyState(
            icon: Icons.scatter_plot_rounded,
            title: 'Sin datos de correlacion',
            message:
                'Necesitas al menos 4 semanas con datos de estudio y entrenamiento.',
          );
        }

        // Convertir a FlSpot
        final spots = puntos.map((p) {
          return FlSpot(p['horasEstudio']!, p['rpe']!);
        }).toList();

        // Calcular limites
        final minX = puntos.map((p) => p['horasEstudio']!).reduce(min);
        final maxX = puntos.map((p) => p['horasEstudio']!).reduce(max);
        final minY = puntos.map((p) => p['rpe']!).reduce(min);
        final maxY = puntos.map((p) => p['rpe']!).reduce(max);

        final paddingX = (maxX - minX) * 0.15;
        final paddingY = (maxY - minY) * 0.2;

        // Calcular linea de regresion simple
        final regresionSpots = _calcularLineaRegresion(spots);

        // Insight opcional
        final insight = insightAsync.valueOrNull;

        return _ChartCard(
          title: 'Correlacion estudio vs RPE',
          subtitle: insight != null
              ? 'Coef. Pearson: ${insight.coeficiente.toStringAsFixed(3)} (${insight.magnitud})'
              : 'Relacion entre carga academica y rendimiento',
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: ScatterChart(
                  ScatterChartData(
                    scatterSpots: spots.map((spot) {
                      return ScatterSpot(
                        spot.x,
                        spot.y,
                        dotPainter: FlDotCirclePainter(
                          color: SVColors.secondary,
                          radius: 8,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        ),
                      );
                    }).toList(),
                    minX: (minX - paddingX).clamp(0, double.infinity),
                    maxX: maxX + paddingX,
                    minY: (minY - paddingY).clamp(0, 10),
                    maxY: (maxY + paddingY).clamp(1, 10),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: SVColors.outlineVariant.withValues(alpha: 0.3),
                          strokeWidth: 0.8,
                        );
                      },
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
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}h',
                              style: const TextStyle(
                                fontSize: 10,
                                color: SVColors.onSurfaceMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
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
                    scatterTouchData: ScatterTouchData(
                      touchTooltipData: ScatterTouchTooltipData(
                        getTooltipItems: (spot) {
                          return ScatterTooltipItem(
                            '${spot.x.toStringAsFixed(1)}h / RPE ${spot.y.toStringAsFixed(1)}',
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Linea de regresion
              if (regresionSpots.length >= 2) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: SVColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Linea de tendencia',
                      style: TextStyle(
                        fontSize: 11,
                        color: SVColors.onSurfaceMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (insight != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: insight.coeficiente.abs() >= 0.4
                              ? insight.coeficiente >= 0
                                  ? SVColors.secondary.withValues(alpha: 0.1)
                                  : SVColors.error.withValues(alpha: 0.1)
                              : SVColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'r = ${insight.coeficiente.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: insight.coeficiente.abs() >= 0.4
                                ? insight.coeficiente >= 0
                                    ? SVColors.secondary
                                    : SVColors.error
                                : SVColors.onSurfaceMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              // Etiquetas de ejes
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '← Horas estudio/semana →',
                    style: TextStyle(
                      fontSize: 10,
                      color: SVColors.onSurfaceMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    '← RPE →',
                    style: TextStyle(
                      fontSize: 10,
                      color: SVColors.onSurfaceMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return const _ChartCard(
      title: 'Correlacion estudio vs RPE',
      subtitle: 'Error al cargar los datos',
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No se pudieron cargar los datos de correlacion.',
            style: TextStyle(color: SVColors.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Calculo de linea de regresion simple (y = mx + b)
  // ───────────────────────────────────────────────────────────────────────────

  List<FlSpot> _calcularLineaRegresion(List<FlSpot> spots) {
    if (spots.length < 2) return [];

    final n = spots.length;
    final sumX = spots.fold<double>(0, (s, sp) => s + sp.x);
    final sumY = spots.fold<double>(0, (s, sp) => s + sp.y);
    final sumXY = spots.fold<double>(0, (s, sp) => s + sp.x * sp.y);
    final sumX2 = spots.fold<double>(0, (s, sp) => s + sp.x * sp.x);

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return [];

    final m = (n * sumXY - sumX * sumY) / denominator;
    final b = (sumY - m * sumX) / n;

    final minX = spots.map((s) => s.x).reduce(min);
    final maxX = spots.map((s) => s.x).reduce(max);

    return [
      FlSpot(minX, m * minX + b),
      FlSpot(maxX, m * maxX + b),
    ];
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
