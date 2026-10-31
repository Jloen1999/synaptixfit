import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Confirmación antes de una acción. Si es [destructive] el botón va en color
/// de error y el foco inicial en Cancelar (la opción segura); si no, en la
/// acción principal (regla 7 de `docs/05-design/accessibility.md`).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
  String? cancelLabel,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      final l10n = context.localizations;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            autofocus: destructive,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? l10n.commonCancel),
          ),
          FilledButton(
            autofocus: !destructive,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: context.colors.error,
                    foregroundColor: context.colors.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
