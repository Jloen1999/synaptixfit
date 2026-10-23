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
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    if (loading) {
      return OutlinedButton(
        onPressed: null,
        child: Semantics(
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
        ? OutlinedButton(onPressed: onTap, child: Text(label))
        : OutlinedButton.icon(onPressed: onTap, icon: icon, label: Text(label));
  }
}
