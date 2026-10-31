import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Botón secundario (contorno) con estado de carga opcional.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;

  /// Para llevar el foco al botón (p. ej. cuando aparece tras una acción).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    if (loading) {
      return OutlinedButton(
        onPressed: null,
        focusNode: focusNode,
        // Como en el botón principal: la carga se anuncia aunque el botón,
        // deshabilitado, pierda el foco.
        child: Semantics(
          liveRegion: true,
          label: '$label, ${context.localizations.commonLoading}',
          child: const ExcludeSemantics(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      );
    }
    return icon == null
        ? OutlinedButton(
            onPressed: onTap,
            focusNode: focusNode,
            child: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            focusNode: focusNode,
            icon: icon,
            label: Text(label),
          );
  }
}
