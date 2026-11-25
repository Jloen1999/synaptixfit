import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.g.dart';

/// Botón de borrar, descartar o bloquear (ADR 0065): con borde y texto en el
/// color de error, siempre aparte de las demás acciones. El texto dice el
/// verbo, así que el rojo nunca es la única señal.
class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.delete,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Papelera por defecto; `null` deja el botón solo con texto.
  final IconData? icon;

  /// Estilo rojo con borde que conserva el anillo de foco del tema. Para un
  /// botón de borrar que necesita otro contenido (p. ej. un indicador de
  /// carga, panel de administración); si no, usa el widget.
  static ButtonStyle styleOf(BuildContext context) {
    final colors = context.colors;
    // El borde de reposo es rojo; con el foco de teclado, el anillo común
    // (`onSurface`, por fuera), como el resto de botones del tema.
    return OutlinedButton.styleFrom(foregroundColor: colors.error).copyWith(
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(
                color: colors.onSurface,
                width: TokensSize.focusRing,
                strokeAlign: BorderSide.strokeAlignOutside,
              )
            : BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? colors.outlineVariant
                    : colors.error,
              ),
      ),
    );
  }

  /// Relleno rojo de la acción que confirma un borrado dentro de un diálogo
  /// («¿Eliminar…?» → «Eliminar»): ahí ya se eligió borrar y es la acción
  /// principal del diálogo (ADR 0065). Fuera de un diálogo, nunca relleno.
  static ButtonStyle confirmStyleOf(BuildContext context) =>
      FilledButton.styleFrom(
        backgroundColor: context.colors.error,
        foregroundColor: context.colors.onError,
      );

  @override
  Widget build(BuildContext context) {
    final style = styleOf(context);
    final glyph = icon;
    return glyph == null
        ? OutlinedButton(style: style, onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(glyph),
            label: Text(label),
          );
  }
}
