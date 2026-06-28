import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_usuario_stats_provider.dart';

/// Widget de gráficos de estadísticas de un usuario.
///
/// Muestra dos gráficos verticales: uno de línea para la evolución del RPE
/// y otro de barras para el volumen en minutos, ambos semanales.
class AdminGraficosUsuario extends ConsumerWidget {
  final String usuarioId;

  const AdminGraficosUsuario({required this.usuarioId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rpeAsync = ref.watch(adminRpeSemanalProvider(usuarioId));
    final volumenAsync = ref.watch(adminVolumenSemanalProvider(usuarioId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gráfico RPE
          _buildSeccionGrafico(context, 'RPE Promedio Semanal', rpeAsync,
              (data) => _buildLineChart(context, data)),
          const SizedBox(height: 24),

          // Gráfico Volumen
          _buildSeccionGrafico(context, 'Volumen Semanal (minutos)',
              volumenAsync, (data) => _buildBarChart(context, data)),
        ],
      ),
    );
  }

  Widget _buildSeccionGrafico(
    BuildContext context,
    String titulo,
    AsyncValue<List<dynamic>> asyncData,
    Widget Function(List<dynamic> data) chartBuilder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Error al cargar datos',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
            data: (data) {
              if (data.isEmpty) {
                return const Center(
                  child: Text(
                    'Sin datos suficientes',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return chartBuilder(data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, List<dynamic> data) {
    final spots = _buildSpots(data);
    final color = Theme.of(context).colorScheme.primary;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval:
                  spots.length > 6 ? (spots.length / 6).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final fecha = data[idx].fecha as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${fecha.day}/${fecha.month}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 3, color: color),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: _maxValor(data) * 1.2,
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<dynamic> data) {
    final color = Theme.of(context).colorScheme.secondary;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _maxValor(data) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final fecha = data[idx].fecha as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${fecha.day}/${fecha.month}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          final valor = data[i].valor;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: valor,
                color: color,
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        minY: 0,
        maxY: _maxValor(data) * 1.2,
      ),
    );
  }

  List<FlSpot> _buildSpots(List<dynamic> data) {
    return List.generate(data.length, (i) {
      return FlSpot(i.toDouble(), data[i].valor);
    });
  }

  double _maxValor(List<dynamic> data) {
    if (data.isEmpty) return 10;
    double max = 0;
    for (final d in data) {
      if (d.valor > max) max = d.valor;
    }
    return max > 0 ? max : 10;
  }
}
