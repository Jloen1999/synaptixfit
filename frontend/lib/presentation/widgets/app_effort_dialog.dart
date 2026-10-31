import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Pide el esfuerzo percibido (1-10) de un entrenamiento o de un bloque de
/// deporte; devuelve `null` si se cancela. [confirmLabel] es la acción que
/// cierra (p. ej. «Finalizar» o «Marcar como hecho») y [subtitle], qué se
/// valora (p. ej. el título del bloque).
Future<int?> showEffortDialog(
  BuildContext context, {
  required String confirmLabel,
  String? subtitle,
}) => showDialog<int>(
  context: context,
  builder: (_) => _EffortDialog(confirmLabel: confirmLabel, subtitle: subtitle),
);

class _EffortDialog extends StatefulWidget {
  const _EffortDialog({required this.confirmLabel, this.subtitle});

  final String confirmLabel;
  final String? subtitle;

  @override
  State<_EffortDialog> createState() => _EffortDialogState();
}

class _EffortDialogState extends State<_EffortDialog> {
  int _effort = 6;

  String _description(BuildContext context) {
    final l10n = context.localizations;
    return switch (_effort) {
      <= 3 => l10n.commonEffortEasy,
      <= 6 => l10n.commonEffortModerate,
      <= 8 => l10n.commonEffortHard,
      _ => l10n.commonEffortMax,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final subtitle = widget.subtitle;
    // Desplazable: con texto grande o el móvil en horizontal no se desborda.
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.commonEffortTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null && subtitle.isNotEmpty) ...[
            Text(subtitle, style: context.textStyles.titleSmall),
            const SizedBox(height: TokensSpacing.xs),
          ],
          Text(l10n.commonEffortMessage),
          const SizedBox(height: TokensSpacing.l),
          // La cifra y la palabra ya las dice el control al lector de pantalla.
          ExcludeSemantics(
            child: Column(
              children: [
                Text(
                  '$_effort',
                  style: context.textStyles.displaySmall?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
                Text(
                  _description(context),
                  style: context.textStyles.labelLarge,
                ),
              ],
            ),
          ),
          Slider(
            autofocus: true,
            value: _effort.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_effort',
            semanticFormatterCallback: (v) =>
                l10n.commonEffortSemantics(v.round(), _description(context)),
            onChanged: (v) => setState(() => _effort = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_effort),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
