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
