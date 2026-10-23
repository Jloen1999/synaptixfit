import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Pide confirmación antes de una acción. Si [typeToConfirm] no es nulo, el
/// botón solo se habilita tras escribir ese texto exacto (acciones irreversibles).
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  String? typeToConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
      typeToConfirm: typeToConfirm,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.destructive,
    required this.typeToConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;
  final String? typeToConfirm;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled =>
      widget.typeToConfirm == null ||
      _controller.text.trim() == widget.typeToConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    return AlertDialog(
      icon: widget.destructive
          ? Icon(Icons.warning_amber_rounded, color: colors.error)
          : null,
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            if (widget.typeToConfirm != null) ...[
              const SizedBox(height: TokensSpacing.m),
              Text(
                l10n.adminConfirmTypeHint(widget.typeToConfirm!),
                style: context.textStyles.labelMedium,
              ),
              const SizedBox(height: TokensSpacing.s),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_enabled) Navigator.of(context).pop(true);
                },
                decoration: InputDecoration(labelText: widget.typeToConfirm),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                )
              : null,
          onPressed: _enabled ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Guarda un texto JSON como archivo (descarga en web, diálogo en el resto).
/// Devuelve `true` si se guardó y `false` si se canceló o falló.
Future<bool> saveAdminJsonFile({
  required String fileName,
  required String json,
}) => FilePicker.saveFile(
  fileName: fileName,
  bytes: utf8.encode(json),
  mimeType: 'application/json',
  type: FileType.custom,
  allowedExtensions: const ['json'],
).then((uri) => uri != null, onError: (Object _) => false);
