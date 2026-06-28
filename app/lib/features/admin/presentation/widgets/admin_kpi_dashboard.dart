import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_metricas_provider.dart';
import 'admin_kpi_card.dart';

/// Dashboard de KPIs globales para el panel de administración.
///
/// Muestra una cuadrícula de 6 tarjetas con las métricas principales
/// del sistema: usuarios, actividad diaria, rutinas, retos y contenido
/// reportado. Debajo del grid muestra un gráfico de línea con los
/// registros diarios de los últimos 30 días.
class AdminKpiDashboard extends ConsumerWidget {
  const AdminKpiDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricasAsync = ref.watch(adminMetricasProvider);
    final registrosDiariosAsync = ref.watch(adminRegistrosDiariosProvider(30));

    return metricasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Error al cargar métricas: $err'),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () => ref.invalidate(adminMetricasProvider),
            ),
          ],
        ),
      ),
      data: (m) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminMetricasProvider);
            ref.invalidate(adminRegistrosDiariosProvider(30));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Grid de KPIs
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    AdminKpiCard(
                      icon: Icons.people,
                      label: 'Total usuarios',
                      value: '${m.totalUsuarios}',
                      color: Colors.blue,
                    ),
                    AdminKpiCard(
                      icon: Icons.how_to_reg,
                      label: 'Activos hoy',
                      value: '${m.usuariosActivosHoy}',
                      color: Colors.green,
                    ),
                    AdminKpiCard(
                      icon: Icons.fitness_center,
                      label: 'Sesiones hoy',
                      value: '${m.sesionesHoy}',
                      color: Colors.orange,
                    ),
                    AdminKpiCard(
                      icon: Icons.list_alt,
                      label: 'Rutinas activas',
                      value: '${m.rutinasActivas}',
                      color: Colors.purple,
                    ),
                    AdminKpiCard(
                      icon: Icons.emoji_events,
                      label: 'Retos activos',
                      value: '${m.retosActivos}',
                      color: Colors.amber,
                    ),
                    AdminKpiCard(
                      icon: Icons.flag,
                      label: 'Reportado pendiente',
                      value: m.contenidoReportadoPendiente > 0
                          ? '${m.contenidoReportadoPendiente}'
                          : '0',
                      color: Colors.red,
                      badge: m.contenidoReportadoPendiente > 0
                          ? '${m.contenidoReportadoPendiente}'
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Gráfico de tendencia diaria
                _buildTendenciaChart(context, registrosDiariosAsync),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTendenciaChart(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> registrosAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.indigo),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sesiones diarias (últimos 30 días)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: registrosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Error al cargar datos',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
                data: (registros) {
                  if (registros.isEmpty) {
                    return const Center(
                      child: Text(
                        'Sin datos de sesiones',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return _buildLineChart(context, registros);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
      BuildContext context, List<Map<String, dynamic>> data) {
    final color = Theme.of(context).colorScheme.primary;

    // Crear spots: índice en X, count en Y
    final spots = List.generate(data.length, (i) {
      final count = (data[i]['count'] as num?)?.toDouble() ?? 0;
      return FlSpot(i.toDouble(), count);
    });

    // Calcular maxY con margen
    double maxY = 0;
    for (final spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY > 0 ? maxY * 1.3 : 10;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 20 ? (maxY / 4).ceilToDouble() : 1,
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
                value >= 0 ? '${value.toInt()}' : '',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: data.length > 10 ? (data.length / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final fechaStr = data[idx]['fecha'] as String? ?? '';
                // Mostrar solo día/mes
                final partes = fechaStr.split('-');
                final label =
                    partes.length >= 3 ? '${partes[2]}/${partes[1]}' : fechaStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
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
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 14,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
      ),
    );
  }
}
