import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/admin_metricas_provider.dart';
import '../../application/admin_provider.dart'
    show lockdownStateProvider, toggleLockdown;
import 'admin_kpi_card.dart';

/// Dashboard de KPIs globales con diseno Clean UI.
///
/// Cabecera con fecha del sistema, grid de 2 columnas con 6 tarjetas KPI
/// y grafico de tendencia diaria de los ultimos 30 dias con tooltips.
class AdminKpiDashboard extends ConsumerWidget {
  const AdminKpiDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricasAsync = ref.watch(adminMetricasProvider);
    final registrosDiariosAsync = ref.watch(adminRegistrosDiariosProvider(30));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return metricasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error al cargar metricas',
                style: TextStyle(
                    fontSize: 15, color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              onPressed: () {
                ref.invalidate(adminMetricasProvider);
                ref.invalidate(adminRegistrosDiariosProvider(30));
              },
            ),
          ],
        ),
      ),
      data: (m) {
        List<double>? sparklineSesiones;
        registrosDiariosAsync.whenOrNull(data: (registros) {
          if (registros.isNotEmpty) {
            sparklineSesiones = registros
                .map((r) => (r['count'] as num?)?.toDouble() ?? 0.0)
                .toList();
          }
        });

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminMetricasProvider);
            ref.invalidate(adminRegistrosDiariosProvider(30));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D3B66),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Resumen General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM yyyy', 'es').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLockdownBanner(context, ref, cs),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    AdminKpiCard(
                      icon: Icons.people_rounded,
                      label: 'Total usuarios',
                      value: _formatearNumero(m.totalUsuarios),
                      color: const Color(0xFF0D3B66),
                      sparklineValues: null,
                    ),
                    AdminKpiCard(
                      icon: Icons.how_to_reg_rounded,
                      label: 'Activos hoy',
                      value: _formatearNumero(m.usuariosActivosHoy),
                      color: const Color(0xFF006E2D),
                    ),
                    AdminKpiCard(
                      icon: Icons.fitness_center_rounded,
                      label: 'Sesiones hoy',
                      value: _formatearNumero(m.sesionesHoy),
                      color: const Color(0xFF00A896),
                      sparklineValues: sparklineSesiones,
                    ),
                    AdminKpiCard(
                      icon: Icons.list_alt_rounded,
                      label: 'Rutinas activas',
                      value: _formatearNumero(m.rutinasActivas),
                      color: const Color(0xFF7B2D8E),
                    ),
                    AdminKpiCard(
                      icon: Icons.emoji_events_rounded,
                      label: 'Retos activos',
                      value: _formatearNumero(m.retosActivos),
                      color: const Color(0xFFE67E22),
                    ),
                    AdminKpiCard(
                      icon: Icons.flag_rounded,
                      label: 'Reportado pendiente',
                      value: m.contenidoReportadoPendiente > 0
                          ? '${m.contenidoReportadoPendiente}'
                          : '—',
                      color: const Color(0xFFC0392B),
                      badge: m.contenidoReportadoPendiente > 0
                          ? '${m.contenidoReportadoPendiente}'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A896),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tendencia de Sesiones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTrendChart(context, cs, registrosDiariosAsync),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockdownBanner(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    final lockdownAsync = ref.watch(lockdownStateProvider);

    return lockdownAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (enLockdown) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: enLockdown
                  ? const Color(0xFFC0392B).withValues(alpha: 0.5)
                  : Colors.grey.shade200,
            ),
          ),
          color: enLockdown
              ? const Color(0xFFC0392B).withValues(alpha: 0.06)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: enLockdown
                        ? const Color(0xFFC0392B).withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    enLockdown ? Icons.shield_rounded : Icons.shield_outlined,
                    color: enLockdown
                        ? const Color(0xFFC0392B)
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enLockdown ? 'Modo Pánico ACTIVO' : 'Modo Pánico',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: enLockdown
                              ? const Color(0xFFC0392B)
                              : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enLockdown
                            ? 'Nuevo contenido social bloqueado'
                            : 'Interruptor maestro de emergencia',
                        style: TextStyle(
                          fontSize: 12,
                          color: enLockdown
                              ? const Color(0xFFC0392B).withValues(alpha: 0.7)
                              : cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enLockdown,
                  activeColor: const Color(0xFFC0392B),
                  inactiveTrackColor: Colors.grey.shade300,
                  onChanged: (val) async {
                    try {
                      await toggleLockdown(ref, val);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Modo Pánico ACTIVADO'
                                  : 'Modo Pánico DESACTIVADO',
                            ),
                            backgroundColor:
                                val ? const Color(0xFFC0392B) : Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatearNumero(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }

  Widget _buildTrendChart(
    BuildContext context,
    ColorScheme cs,
    AsyncValue<List<Map<String, dynamic>>> registrosAsync,
  ) {
    const colorTeal = Color(0xFF00A896);
    const colorDark = Color(0xFF0D3B66);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded,
                    size: 18, color: colorTeal.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  'Sesiones diarias (ultimos 30 dias)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: registrosAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (err, _) => Center(
                  child: Text('Error al cargar',
                      style: TextStyle(
                          color: cs.error, fontWeight: FontWeight.w500)),
                ),
                data: (registros) {
                  if (registros.isEmpty) {
                    return Center(
                      child: Text('Sin datos de sesiones',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.4))),
                    );
                  }
                  return _buildLineChart(registros, colorTeal, colorDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List<Map<String, dynamic>> data,
    Color lineColor,
    Color tooltipColor,
  ) {
    final spots = List.generate(data.length, (i) {
      final count = (data[i]['count'] as num?)?.toDouble() ?? 0;
      return FlSpot(i.toDouble(), count);
    });

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
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value >= 0 ? '${value.toInt()}' : '',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
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
                final partes = fechaStr.split('-');
                final label =
                    partes.length >= 3 ? '${partes[2]}/${partes[1]}' : fechaStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
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
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tooltipColor.withValues(alpha: 0.92),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final fechaStr = data[idx]['fecha'] as String? ?? '';
                final partes = fechaStr.split('-');
                final label =
                    partes.length >= 3 ? '${partes[2]}/${partes[1]}' : fechaStr;
                return LineTooltipItem(
                  '$label\n${spot.y.toInt()} sesiones',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 14,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: lineColor,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.22),
                  lineColor.withValues(alpha: 0.01),
                ],
              ),
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
