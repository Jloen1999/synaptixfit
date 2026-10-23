import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Datos de confirmación de la baja.
typedef DeleteAccountConfirmation = ({String? password, bool confirm});

/// Confirmación fuerte antes de eliminar la cuenta: hay que marcar que se
/// entiende la consecuencia, escribir la palabra de confirmación y, si la
/// cuenta tiene contraseña, introducirla. Devuelve `null` si se cancela.
Future<DeleteAccountConfirmation?> showDeleteAccountDialog(
  BuildContext context, {
  required bool hasPassword,
}) {
  return showDialog<DeleteAccountConfirmation>(
    context: context,
    builder: (_) => _DeleteAccountDialog(hasPassword: hasPassword),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.hasPassword});

  final bool hasPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  final _word = TextEditingController();
  bool _understood = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_refresh);
    _word.addListener(_refresh);
  }

  @override
  void dispose() {
    _password.dispose();
    _word.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final keyword = l10n.profileDeleteKeyword;
    final ready =
        _understood &&
        _word.text.trim().toUpperCase() == keyword.toUpperCase() &&
        (!widget.hasPassword || _password.text.isNotEmpty);
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: context.colors.error),
      title: Text(l10n.profileDeleteTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.profileDeleteMessage),
              const SizedBox(height: TokensSpacing.m),
              AppFocusOutline(
                child: CheckboxListTile(
                  value: _understood,
                  onChanged: (v) => setState(() => _understood = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.profileDeleteUnderstand),
                ),
              ),
              const SizedBox(height: TokensSpacing.s),
              AppTextField(
                label: l10n.profileDeleteTypeKeyword(keyword),
                controller: _word,
              ),
              if (widget.hasPassword) ...[
                const SizedBox(height: TokensSpacing.m),
                AppTextField(
                  label: l10n.fieldPassword,
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  autofillHints: const [AutofillHints.password],
                ),
              ] else ...[
                const SizedBox(height: TokensSpacing.s),
                Text(
                  l10n.profileDeleteGoogleOnly,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          onPressed: ready
              ? () => Navigator.pop<DeleteAccountConfirmation>(context, (
                  password: widget.hasPassword ? _password.text : null,
                  confirm: true,
                ))
              : null,
          child: Text(l10n.profileDeleteAction),
        ),
      ],
    );
  }
}
