import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Un atajo de Entreno: icono, texto corto y qué hace al tocarlo.
class TrainingQuickAction {
  const TrainingQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.key,
    this.wideOnly = false,
  });

  final IconData icon;
  final String label;

  /// Nulo mientras la acción no se puede usar (p. ej. empezando una sesión).
  final VoidCallback? onTap;

  /// Para que la guía de la primera vez pueda señalar este atajo (ADR 0049).
  final Key? key;

  /// Solo a la vista si caben todos en una fila (tablet, escritorio): en el
  /// móvil esa acción vive en «Más».
  final bool wideOnly;
}

/// Fila de atajos de Gimnasio y de Correr (ADR 0055): lo que más se usa, a un
/// toque y sin bajar. Van juntos en una tarjeta: sobre su superficie se leen
/// igual en claro y en oscuro. Decide por el ancho real y el tamaño de letra:
/// - caben todos (también los [TrainingQuickAction.wideOnly]) → una fila;
/// - caben los de siempre → una fila, icono encima del nombre;
/// - no caben → filas de dos con el icono al lado (320 px, texto al 200 %).
/// Ninguna palabra se parte: el mínimo de cada atajo es su palabra más larga.
class TrainingQuickActions extends StatelessWidget {
  const TrainingQuickActions({super.key, required this.actions});

  final List<TrainingQuickAction> actions;

  static const _spacing = TokensSpacing.xxs;

  /// Relleno lateral de un atajo: lo que no es texto en la forma apilada.
  static const _stackedChrome = TokensSpacing.xxs * 2;

  /// Icono, hueco y relleno: lo que no es texto en la forma con icono al lado.
  static const _inlineChrome =
      TokensLayout.minTouchTarget + TokensSpacing.xs + TokensSpacing.s * 2;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(TokensSpacing.xs),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final style = context.textStyles.labelLarge;
        double widestWord(Iterable<TrainingQuickAction> list) {
          var widest = 0.0;
          for (final action in list) {
            for (final word in action.label.split(RegExp(r'\s+'))) {
              final w = context.textWidth(word, style);
              if (w > widest) widest = w;
            }
          }
          return widest;
        }

        bool fitsInRow(List<TrainingQuickAction> list) {
          final min = [
            context.scaled(TokensSize.quickActionMinWidth),
            widestWord(list) + _stackedChrome,
          ].reduce((a, b) => a > b ? a : b);
          return (width - _spacing * (list.length - 1)) / list.length >= min;
        }

        final base = [
          for (final a in actions)
            if (!a.wideOnly) a,
        ];
        final List<TrainingQuickAction> visible;
        final bool inline;
        if (base.length < actions.length && fitsInRow(actions)) {
          (visible, inline) = (actions, false);
        } else {
          (visible, inline) = (base, !fitsInRow(base));
        }
        final buttons = [
          for (final action in visible)
            _QuickActionButton(key: action.key, action: action, inline: inline),
        ];
        if (!inline) return _row(buttons);
        // Dos por fila si el icono y la palabra más larga caben; si no, uno.
        final columns =
            (width - _spacing) / 2 >= widestWord(visible) + _inlineChrome
            ? 2
            : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < buttons.length; i += columns) ...[
              if (i > 0) const SizedBox(height: _spacing),
              _row([
                for (var j = i; j < i + columns; j++)
                  j < buttons.length ? buttons[j] : const SizedBox.shrink(),
              ]),
            ],
          ],
        );
      },
    ),
  );

  /// Los atajos de una fila miden lo mismo aunque una etiqueta ocupe dos
  /// líneas.
  static Widget _row(List<Widget> children) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const SizedBox(width: _spacing),
          Expanded(child: child),
        ],
      ],
    ),
  );
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    super.key,
    required this.action,
    required this.inline,
  });

  final TrainingQuickAction action;

  /// Icono a la izquierda del nombre (filas de dos) en vez de encima.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = Container(
      width: TokensLayout.minTouchTarget,
      height: TokensLayout.minTouchTarget,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: AppPill.tintAlpha),
          colors.surface,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(action.icon, color: colors.primary),
    );
    // 14 px: más pequeño, el círculo de color pesa más que el texto y la
    // comprobación de contraste lo toma por fondo.
    final label = Text(
      action.label,
      textAlign: inline ? TextAlign.start : TextAlign.center,
      style: context.textStyles.labelLarge,
    );
    // La acción va también en el nodo del lector: con `excludeSemantics`, el
    // toque del InkWell no le llegaría (TalkBack y VoiceOver).
    return Semantics(
      container: true,
      button: true,
      enabled: action.onTap != null,
      label: action.label,
      onTap: action.onTap,
      excludeSemantics: true,
      child: AppFocusOutline(
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: Padding(
            padding: inline
                ? const EdgeInsets.all(TokensSpacing.s)
                : const EdgeInsets.symmetric(
                    horizontal: TokensSpacing.xxs,
                    vertical: TokensSpacing.s,
                  ),
            child: inline
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: TokensSpacing.xs),
                      Expanded(child: label),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(height: TokensSpacing.xs),
                      label,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
