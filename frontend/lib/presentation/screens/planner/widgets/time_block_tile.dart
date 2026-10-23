import 'package:flutter/material.dart';

import '../../../../domain/models/planner/calendar_block.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_visuals.dart';

/// Bloque del lienzo: franja de color por tipo, icono, título y horario.
/// Gestiona el toque, el arrastre (pulsación larga) y el redimensionado (asa
/// inferior); los desplazamientos se comunican en píxeles al lienzo. Con
/// teclado se enfoca y se abre con Intro; mover o cambiar la duración se hace
/// desde el editor que abre.
class TimeBlockTile extends StatelessWidget {
  const TimeBlockTile({
    super.key,
    required this.block,
    required this.title,
    required this.start,
    required this.end,
    required this.busy,
    required this.dragging,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.onLockedTouched,
  });

  final CalendarBlock block;
  final String title;

  /// Horario mostrado (puede ser la vista previa durante el arrastre).
  final DateTime start;
  final DateTime end;
  final bool busy;
  final bool dragging;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  /// Incremento vertical (px) del asa desde el último evento.
  final ValueChanged<double> onResizeUpdate;
  final VoidCallback onResizeEnd;
  final VoidCallback onLockedTouched;

  bool get _movable => !block.isLocked && !block.completed;

  @override
  Widget build(BuildContext context) {
    final color = block.type.color(context);
    final l10n = context.localizations;
    final timeText = l10n.plannerTimeRange(
      PlannerFormats.time(start),
      PlannerFormats.time(end),
    );
    return Semantics(
      container: true,
      button: true,
      label: [
        l10n.plannerBlockSemantics(
          block.type.label(context),
          PlannerFormats.time(start),
          PlannerFormats.time(end),
        ),
        title,
        if (block.completed) l10n.plannerCompletedLabel,
        if (block.isLocked) l10n.plannerFixedLabel,
      ].join(', '),
      // El toque va en el InkWell (enfocable, con resaltado de foco); aquí solo
      // queda la pulsación larga que inicia el arrastre.
      child: GestureDetector(
        onLongPressStart: (_) => _movable ? onDragStart() : onLockedTouched(),
        onLongPressMoveUpdate: _movable
            ? (d) => onDragUpdate(d.offsetFromOrigin)
            : null,
        onLongPressEnd: _movable ? (_) => onDragEnd() : null,
        child: AnimatedOpacity(
          duration: context.motion(TokensDuration.fast),
          opacity: busy ? 0.6 : 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 44;
              return AppFocusOutline(
                borderRadius: BorderRadius.circular(TokensRadius.s),
                child: Material(
                  color: Color.alphaBlend(
                    color.withValues(alpha: block.completed ? 0.10 : 0.20),
                    context.colors.surface,
                  ),
                  elevation: dragging ? 6 : 0,
                  borderRadius: BorderRadius.circular(TokensRadius.s),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    // La etiqueta del bloque ya resume el contenido.
                    child: ExcludeSemantics(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: color, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              TokensSpacing.s,
                              TokensSpacing.xxs,
                              TokensSpacing.xs,
                              TokensSpacing.xxs,
                            ),
                            child: _content(context, color, timeText, compact),
                          ),
                          if (_movable && !compact)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 14,
                              child: _ResizeHandle(
                                color: color,
                                onUpdate: onResizeUpdate,
                                onEnd: onResizeEnd,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    Color color,
    String timeText,
    bool compact,
  ) {
    final titleStyle = context.textStyles.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: context.colors.onSurface,
      decoration: block.completed ? TextDecoration.lineThrough : null,
    );
    final statusIcons = [
      if (block.completed)
        Icon(Icons.check_circle_rounded, size: 14, color: color),
      if (block.isLocked)
        Icon(
          Icons.lock_rounded,
          size: 12,
          color: context.colors.onSurfaceVariant,
        ),
    ];
    final header = Row(
      children: [
        Icon(block.type.icon, size: 14, color: color),
        const SizedBox(width: TokensSpacing.xs),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        ...statusIcons,
      ],
    );
    if (compact) return header;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Text(
          timeText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.color,
    required this.onUpdate,
    required this.onEnd,
  });

  final Color color;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.localizations.plannerResizeHandle,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) => onUpdate(d.delta.dy),
          onVerticalDragEnd: (_) => onEnd(),
          onVerticalDragCancel: onEnd,
          child: Center(
            child: Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(TokensRadius.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
