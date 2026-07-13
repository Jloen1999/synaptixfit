import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Tarjeta individual de KPI para el dashboard de administracion.
///
/// Muestra un icono, un valor grande animado, una etiqueta descriptiva y,
/// opcionalmente, un badge de alerta y una sparkline (micro-grafico de
/// tendencia). La sparkline se renderiza como un [LineChart] en miniatura
/// sin ejes ni etiquetas.
class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.badge,
    this.sparklineValues,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? badge;
  final List<double>? sparklineValues;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparkline(List<double> values, Color color) {
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final diff = maxVal - minVal;

    final spots = List.generate(values.length, (i) {
      final y = diff == 0 ? 1.0 : (values[i] - minVal) / diff;
      return FlSpot(i.toDouble(), y);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 1.8,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.20),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: 1,
        clipData: const FlClipData.all(),
      ),
      duration: const Duration(milliseconds: 600),
    );
  }
}
