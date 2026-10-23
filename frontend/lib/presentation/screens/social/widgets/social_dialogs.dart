import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';

/// Pide confirmación antes de una acción (destructiva o de reporte).
Future<bool> confirmSocialAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final l10n = context.localizations;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        // Foco inicial en la opción segura si la acción es destructiva.
        TextButton(
          autofocus: destructive,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          autofocus: !destructive,
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: dialogContext.colors.error,
                  foregroundColor: dialogContext.colors.onError,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Diálogo para editar un comentario (1-500 caracteres). Devuelve el texto o `null`.
Future<String?> editCommentDialog(BuildContext context, String initial) {
  return showDialog<String>(
    context: context,
    builder: (_) => _EditCommentDialog(initial: initial),
  );
}

class _EditCommentDialog extends StatefulWidget {
  const _EditCommentDialog({required this.initial});

  final String initial;

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AlertDialog(
      title: Text(l10n.socialCommentEditTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          maxLength: commentMaxLength,
          decoration: InputDecoration(labelText: l10n.socialCommentLabel),
          validator: (value) => validateComment(context, value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
      ],
    );
  }
}

/// Longitud máxima de un comentario (la valida también la API).
const commentMaxLength = 500;

/// Valida un comentario: obligatorio y como mucho [commentMaxLength] caracteres.
String? validateComment(BuildContext context, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return context.localizations.validationRequired;
  if (text.length > commentMaxLength) {
    return context.localizations.socialCommentTooLong(commentMaxLength);
  }
  return null;
}
