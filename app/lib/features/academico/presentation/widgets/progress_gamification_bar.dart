import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/calendar_dtos.dart';

class ProgressGamificationBar extends StatelessWidget {
  const ProgressGamificationBar({
    required this.metadata,
    required this.config,
    this.onEditEstudio,
    this.onEditDeporte,
    super.key,
  });

  final WeekPlanMetadata? metadata;
  final InboxConfig config;
  final VoidCallback? onEditEstudio;
  final VoidCallback? onEditDeporte;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final meta = metadata;

    final estudioCompleto = (meta?.progresoEstudio ?? 0) >= 1.0;
    final deporteCompleto = (meta?.progresoDeporte ?? 0) >= 1.0;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProgresoMini(
              icon: estudioCompleto
                  ? Icons.check_circle
                  : Icons.menu_book_rounded,
              label: 'Estudio',
              actual: meta != null
                  ? '${meta.horasEstudioColocadas.toStringAsFixed(1)}h'
                  : '0h',
              objetivo: '${config.horasEstudioObjetivo.toStringAsFixed(0)}h',
              progreso: meta?.progresoEstudio ?? 0,
              color: estudioCompleto
                  ? const Color(0xFF10B981)
                  : const Color(0xFF3B82F6),
              onEdit: onEditEstudio,
              completo: estudioCompleto,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ProgresoMini(
              icon: deporteCompleto
                  ? Icons.check_circle
                  : Icons.fitness_center_rounded,
              label: 'Deporte',
              actual: meta != null ? '${meta.sesionesDeporteColocadas}' : '0',
              objetivo:
                  '${config.sesionesDeporteObjetivo}×${config.minutosPorSesionDeporte}\'',
              progreso: meta?.progresoDeporte ?? 0,
              color: deporteCompleto
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF97316),
              onEdit: onEditDeporte,
              completo: deporteCompleto,
            ),
          ),
          if (meta != null && meta.bloquesTotales > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${meta.bloquesTotales}',
              style: tema.textTheme.labelSmall
                  ?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgresoMini extends StatelessWidget {
  const _ProgresoMini({
    required this.icon,
    required this.label,
    required this.actual,
    required this.objetivo,
    required this.progreso,
    required this.color,
    this.onEdit,
    this.completo = false,
  });

  final IconData icon;
  final String label;
  final String actual;
  final String objetivo;
  final double progreso;
  final Color color;
  final VoidCallback? onEdit;
  final bool completo;

  @override
  Widget build(BuildContext context) {
    final iconWidget = completo
        ? Icon(icon, size: 14, color: color).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
            )
        : Icon(icon, size: 14, color: color);

    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$label: $actual / $objetivo',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 11, color: Colors.grey.shade500),
            ],
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progreso,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );

    if (onEdit != null) {
      return InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: child,
        ),
      );
    }
    return child;
  }
}
