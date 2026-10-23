import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Estilo común de las gráficas del módulo (ejes, rejilla y animación).
abstract final class ChartStyle {
  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : TokensDuration.slow;

  static FlGridData grid(BuildContext context) => FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) => FlLine(
      color: context.colors.outlineVariant.withValues(alpha: 0.6),
      strokeWidth: 1,
    ),
  );

  static TextStyle? _axisStyle(BuildContext context) => context
      .textStyles
      .labelSmall
      ?.copyWith(color: context.colors.onSurfaceVariant);

  /// Ejes con etiquetas abajo (por índice) y a la izquierda (valores).
  ///
  /// [bottom] devuelve la etiqueta del índice o `null` para omitirla; con
  /// muchas semanas solo se muestra una de cada varias.
  static FlTitlesData titles(
    BuildContext context, {
    required String? Function(int index) bottom,
    required int count,
    String Function(double value)? left,
  }) {
    final step = count <= 6 ? 1 : (count / 5).ceil();
    return FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            if (value == meta.max) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(
                left?.call(value) ?? meta.formattedValue,
                style: _axisStyle(context),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (value != index.toDouble() || index % step != 0) {
              return const SizedBox.shrink();
            }
            final label = bottom(index);
            if (label == null) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(label, style: _axisStyle(context)),
            );
          },
        ),
      ),
    );
  }
}
