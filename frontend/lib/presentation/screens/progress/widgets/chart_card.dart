import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Tarjeta para una gráfica: título, subtítulo, acción opcional y un resumen
/// textual para lectores de pantalla (la gráfica en sí se excluye).
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.semanticsSummary,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;

  /// Resumen de los valores clave que se lee en lugar de la gráfica.
  final String? semanticsSummary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          if (semanticsSummary == null)
            child
          else
            AppChartSummary(summary: semanticsSummary!, child: child),
          if (footer != null) ...[
            const SizedBox(height: TokensSpacing.s),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Mensaje discreto dentro de una tarjeta (sin datos o sección no disponible).
class InlineNotice extends StatelessWidget {
  const InlineNotice({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.m),
      child: Row(
        children: [
          Icon(icon, color: context.colors.onSurfaceVariant),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rejilla de métricas: 4 columnas en pantallas anchas y 2 en móvil.
class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        const gap = TokensSpacing.s;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
