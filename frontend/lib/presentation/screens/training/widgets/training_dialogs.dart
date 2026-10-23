import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'training_labels.dart';

/// Pide un texto (renombrar). Devuelve el texto recortado o `null` si se cancela.
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? initial,
  int maxLength = 120,
  bool allowEmpty = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextPromptDialog(
    title: title,
    label: label,
    initial: initial,
    maxLength: maxLength,
    allowEmpty: allowEmpty,
  ),
);

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.maxLength,
    required this.allowEmpty,
  });

  final String title;
  final String label;
  final String? initial;
  final int maxLength;
  final bool allowEmpty;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initial ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: widget.maxLength,
          decoration: InputDecoration(labelText: widget.label),
          validator: (v) => !widget.allowEmpty && (v?.trim().isEmpty ?? true)
              ? l10n.validationRequired
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.commonSave)),
      ],
    );
  }
}

/// Confirmación antes de una acción (destructiva o no).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = context.localizations;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          // Foco inicial en la opción segura si la acción es destructiva.
          TextButton(
            autofocus: destructive,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
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

/// Elige un día de la semana entre los disponibles (1 = lunes … 7 = domingo).
Future<int?> showWeekdayPicker(
  BuildContext context, {
  required Set<int> taken,
}) => showDialog<int>(
  context: context,
  builder: (context) {
    final l10n = context.localizations;
    return SimpleDialog(
      title: Text(l10n.trainingAddDay),
      children: [
        for (var day = 1; day <= 7; day++)
          SimpleDialogOption(
            onPressed: taken.contains(day)
                ? null
                : () => Navigator.of(context).pop(day),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      weekdayName(l10n, day),
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: taken.contains(day)
                            ? context.colors.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (taken.contains(day))
                    Text(
                      l10n.trainingDayTaken,
                      style: context.textStyles.labelSmall,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  },
);

/// Pide el esfuerzo percibido (RPE 1-10) al finalizar una sesión.
Future<int?> showRpeDialog(BuildContext context) =>
    showDialog<int>(context: context, builder: (_) => const _RpeDialog());

class _RpeDialog extends StatefulWidget {
  const _RpeDialog();

  @override
  State<_RpeDialog> createState() => _RpeDialogState();
}

class _RpeDialogState extends State<_RpeDialog> {
  int _rpe = 6;

  String _description(BuildContext context) {
    final l10n = context.localizations;
    return switch (_rpe) {
      <= 3 => l10n.trainingRpeEasy,
      <= 6 => l10n.trainingRpeModerate,
      <= 8 => l10n.trainingRpeHard,
      _ => l10n.trainingRpeMax,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AlertDialog(
      title: Text(l10n.trainingRpeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.trainingRpeMessage, style: context.textStyles.bodyMedium),
          const SizedBox(height: TokensSpacing.l),
          Text(
            '$_rpe',
            style: context.textStyles.displaySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          Text(_description(context), style: context.textStyles.labelLarge),
          Slider(
            value: _rpe.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_rpe',
            semanticFormatterCallback: (v) =>
                l10n.trainingRpeSemantics(v.round()),
            onChanged: (v) => setState(() => _rpe = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_rpe),
          child: Text(l10n.trainingFinishAction),
        ),
      ],
    );
  }
}
