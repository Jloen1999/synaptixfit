import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_focus_outline.dart';

/// Chip de un día: el día de la semana arriba («lun», «Hoy»), el número en
/// grande y, opcional, una marca debajo ([marker], p. ej. los puntos de la
/// agenda). El elegido va relleno del color de marca. Lo usan la agenda de
/// Inicio y la tira de días del calendario: un día se ve igual en toda la app.
class AppDayChip extends StatelessWidget {
  const AppDayChip({
    super.key,
    required this.caption,
    required this.dayNumber,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
    this.marker,
    this.width,
    this.today = false,
  });

  /// Día de la semana corto («lun») o «Hoy».
  final String caption;
  final int dayNumber;
  final bool selected;

  /// Lo que oye el lector («Lunes 16», «Hoy, 3 eventos…»): el contenido se
  /// excluye para no leerlo dos veces.
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget? marker;

  /// Ancho fijo; nulo, el que le dé el padre (p. ej. una fila con `Expanded`).
  final double? width;

  /// Es hoy: sin estar elegido, lleva el borde del color de marca.
  final bool today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    final radius = BorderRadius.circular(TokensRadius.l);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      // El contenido se excluye dentro del InkWell: así se conservan su acción
      // y su foco en web y con lector de pantalla.
      child: AppFocusOutline(
        borderRadius: radius,
        child: Material(
          color: selected ? colors.primary : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: today && !selected
                ? BorderSide(color: colors.primary, width: TokensSize.focusRing)
                : BorderSide(
                    color: selected ? colors.primary : colors.outlineVariant,
                  ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TokensLayout.minTouchTarget,
                ),
                child: SizedBox(
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // «Aujourd'hui» no cabe en el chip: se reduce, no se parte.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TokensSpacing.xxs,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            caption,
                            maxLines: 1,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: foreground,
                            ),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$dayNumber',
                          maxLines: 1,
                          style: context.textStyles.titleMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                      if (marker != null) ...[
                        const SizedBox(height: TokensSpacing.xxs),
                        marker!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
