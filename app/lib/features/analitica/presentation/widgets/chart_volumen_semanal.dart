import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../application/analitica_provider.dart';

// ---------------------------------------------------------------------------
// Grafico de barras agrupadas que muestra minutos y calorias por semana.
// Barras emparejadas: minutos (azul) | calorias (naranja).
// ---------------------------------------------------------------------------

class ChartVolumenSemanal extends ConsumerWidget {
  const ChartVolumenSemanal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumen = ref.watch(volumenSemanalProvider);

    return volumen.when(
      loading: () => const SkeletonLoader(height: 200),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (puntos) {
        if (puntos.isEmpty) {
          return const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'Sin datos de volumen',
            message:
                'Registra sesiones de entrenamiento para ver tu volumen semanal.',
          );
        }

        // Convertir datos a grupos de barras (2 barras por semana)
        final barGroups = <BarChartGroupData>[];
        final labels = <int, String>{};
        for (var i = 0; i < puntos.length; i++) {
          final p = puntos[i];
          labels[i] = 'S${i + 1}';

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: p['minutos']!,
                  color: SVColors.kpiSesiones,
                  width: puntos.length > 8 ? 8 : 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: p['calorias']!,
                  color: SVColors.kpiCalorias,
                  width: puntos.length > 8 ? 8 : 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }

        final maxY = puntos.fold<double>(0, (max, p) {
          final localMax =
              p['minutos']! > p['calorias']! ? p['minutos']! : p['calorias']!;
          return localMax > max ? localMax : max;
        });

        return _ChartCard(
          title: 'Volumen semanal',
          subtitle: 'Minutos y calorias por semana',
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    groupsSpace: puntos.length > 8 ? 6 : 12,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? maxY / 4 : 50,
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
                          showTitles: puntos.length <= 12,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= puntos.length) {
                              return const SizedBox.shrink();
                            }
                            final step =
                                (puntos.length / 5).ceil().clamp(1, 999);
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
                          reservedSize: 40,
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
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = labels[group.x.toInt()] ?? '';
                          final unidad = rodIndex == 0 ? 'min' : 'kcal';
                          final valor = rod.toY.toInt().toString();
                          return BarTooltipItem(
                            '$label: $valor $unidad',
                            const TextStyle(
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
              const SizedBox(height: 14),
              // Leyenda
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(
                    color: SVColors.kpiSesiones,
                    label: 'Minutos',
                  ),
                  SizedBox(width: 24),
                  _LegendItem(
                    color: SVColors.kpiCalorias,
                    label: 'Calorias',
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
      title: 'Volumen semanal',
      subtitle: 'Error al cargar los datos',
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No se pudieron cargar los datos de volumen.',
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

// ─────────────────────────────────────────────────────────────────────────────
// Widget auxiliar: item de leyenda del grafico de barras
// ─────────────────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: SVColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
