import 'package:flutter/material.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_visuals.dart';

/// «¿Qué es?» de la hoja de evento: botones grandes con icono y texto para
/// elegir el tipo. Los más usados se ven siempre; el resto, en «Más tipos».
/// Qué tipos se ofrecen lo decide quien la usa (modo de uso).
class BlockTypePicker extends StatefulWidget {
  const BlockTypePicker({
    super.key,
    required this.label,
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  /// Tipos que se ven sin desplegar nada, en este orden.
  static const primary = [
    BlockType.study,
    BlockType.review,
    BlockType.sport,
    BlockType.classSession,
    BlockType.personal,
  ];

  /// Nombre del grupo que anuncia el lector de pantalla.
  final String label;

  /// Tipos que se pueden elegir (ya filtrados por el modo de uso).
  final List<BlockType> types;
  final BlockType selected;
  final ValueChanged<BlockType> onChanged;

  @override
  State<BlockTypePicker> createState() => _BlockTypePickerState();
}

class _BlockTypePickerState extends State<BlockTypePicker> {
  /// Abierto de entrada si el tipo elegido es de los menos usados (al editar
  /// un examen, por ejemplo), para que se vea cuál es.
  late bool _more = !BlockTypePicker.primary.contains(widget.selected);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final primary = [
      for (final t in BlockTypePicker.primary)
        if (widget.types.contains(t)) t,
    ];
    final secondary = [
      for (final t in widget.types)
        if (!BlockTypePicker.primary.contains(t)) t,
    ];
    Widget tile(BlockType t) => _ChoiceTile(
      icon: t.icon,
      iconColor: t.color(context),
      label: t.label(context),
      selected: widget.selected == t,
      onTap: () => widget.onChanged(t),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTileGrid(
            children: [
              for (final t in primary) tile(t),
              if (secondary.isNotEmpty)
                _ChoiceTile(
                  icon: _more
                      ? Icons.expand_less_rounded
                      : Icons.more_horiz_rounded,
                  iconColor: context.colors.onSurfaceVariant,
                  label: _more ? l10n.plannerFewerTypes : l10n.plannerMoreTypes,
                  expanded: _more,
                  onTap: () => setState(() => _more = !_more),
                ),
            ],
          ),
          if (_more && secondary.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.s),
            AppTileGrid(children: [for (final t in secondary) tile(t)]),
          ],
        ],
      ),
    );
  }
}

/// Botón grande con icono arriba y texto debajo. Elegido: fondo de acento,
/// borde grueso y texto en negrita (no solo color). Con [expanded] es el
/// botón que despliega más opciones, no una opción.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.expanded,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(TokensRadius.m);
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurface;
    return Semantics(
      button: true,
      selected: expanded == null ? selected : null,
      inMutuallyExclusiveGroup: expanded == null ? true : null,
      expanded: expanded,
      child: AppFocusOutline(
        borderRadius: radius,
        child: Material(
          color: selected
              ? colors.secondaryContainer
              : colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: selected
                ? BorderSide(color: colors.primary, width: TokensSize.focusRing)
                : BorderSide(color: colors.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            // El elegido lleva una marca de verificación, no solo otro color.
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                if (selected)
                  PositionedDirectional(
                    top: TokensSpacing.xs,
                    end: TokensSpacing.xs,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: TokensSize.iconXs,
                        color: foreground,
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: TokensLayout.minTouchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensSpacing.xs,
                      vertical: TokensSpacing.s,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExcludeSemantics(child: Icon(icon, color: iconColor)),
                        const SizedBox(height: TokensSpacing.xs),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: context.textStyles.labelLarge?.copyWith(
                            color: foreground,
                            fontWeight: selected ? FontWeight.w800 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
