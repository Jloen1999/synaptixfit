import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Botón principal con estado de carga. Mientras carga queda deshabilitado,
/// conserva su etiqueta y el lector de pantalla anuncia «Cargando».
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    final Widget child = loading
        // `liveRegion`: la carga la provoca la persona al pulsar, así que se
        // anuncia aunque el foco ya no esté en el botón (queda deshabilitado).
        ? Semantics(
            liveRegion: true,
            label: '$label, ${context.localizations.commonLoading}',
            child: const ExcludeSemantics(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          )
        : Text(label);
    if (icon != null && !loading) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: child,
      );
    }
    return FilledButton(onPressed: onTap, child: child);
  }
}
