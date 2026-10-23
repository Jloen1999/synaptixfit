import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/validators/validators.dart';
import '../../../../../domain/enums/user_role.dart';
import '../../../../../domain/models/admin/admin_user.dart';
import '../../../../../domain/models/admin/erasure_report.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../extensions/validation_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_widgets.dart';

/// Diálogo para editar nombre y email. Devuelve solo los campos cambiados
/// (nulos si no cambian) o `null` si se cancela.
Future<({String? fullName, String? email})?> showAdminIdentityDialog(
  BuildContext context,
  AdminUserAccount account,
) => showDialog(
  context: context,
  builder: (_) => _IdentityDialog(account: account),
);

class _IdentityDialog extends StatefulWidget {
  const _IdentityDialog({required this.account});

  final AdminUserAccount account;

  @override
  State<_IdentityDialog> createState() => _IdentityDialogState();
}

class _IdentityDialogState extends State<_IdentityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account.fullName);
  late final _email = TextEditingController(text: widget.account.email);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    Navigator.of(context).pop((
      fullName: name == widget.account.fullName ? null : name,
      email: email == widget.account.email ? null : email,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AlertDialog(
      title: Text(l10n.adminUserEditIdentity),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 120,
                decoration: InputDecoration(labelText: l10n.fieldFullName),
                validator: (v) => Validators.minLength(v, 2)?.text(context),
              ),
              const SizedBox(height: TokensSpacing.s),
              TextFormField(
                controller: _email,
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.fieldEmail),
                validator: (v) => Validators.email(v)?.text(context),
              ),
            ],
          ),
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

/// Diálogo para fijar nivel y XP del nivel.
Future<({int level, int levelXp})?> showAdminProgressDialog(
  BuildContext context,
  AdminUserAccount account,
) => showDialog(
  context: context,
  builder: (_) => _ProgressDialog(account: account),
);

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({required this.account});

  final AdminUserAccount account;

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _level = TextEditingController(
    text: widget.account.level.toString(),
  );
  late final _xp = TextEditingController(
    text: widget.account.levelXp.toString(),
  );

  @override
  void dispose() {
    _level.dispose();
    _xp.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop((level: int.parse(_level.text), levelXp: int.parse(_xp.text)));
  }

  void _reset() {
    _level.text = '1';
    _xp.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AlertDialog(
      title: Text(l10n.adminUserSetProgress),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminUserProgressHint,
                style: context.textStyles.bodySmall,
              ),
              const SizedBox(height: TokensSpacing.m),
              TextFormField(
                controller: _level,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.adminFieldLevel),
                validator: (v) {
                  final value = int.tryParse(v ?? '');
                  return value == null || value < 1 || value > 1000
                      ? l10n.adminValidationLevel
                      : null;
                },
              ),
              const SizedBox(height: TokensSpacing.s),
              TextFormField(
                controller: _xp,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.adminFieldLevelXp),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? l10n.validationRequired
                    : null,
              ),
              const SizedBox(height: TokensSpacing.s),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l10n.adminUserResetXp),
                ),
              ),
            ],
          ),
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

/// Diálogo de selección de rol.
Future<UserRole?> showAdminRoleDialog(BuildContext context, UserRole current) =>
    showDialog<UserRole>(
      context: context,
      builder: (context) {
        final l10n = context.localizations;
        var selected = current;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.adminUserChangeRole),
            content: RadioGroup<UserRole>(
              groupValue: selected,
              onChanged: (value) => setState(() => selected = value!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final role in UserRole.values)
                    AppFocusOutline(
                      child: RadioListTile<UserRole>(
                        value: role,
                        title: Text(role.adminLabel(l10n)),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: selected == current
                    ? null
                    : () => Navigator.of(context).pop(selected),
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        );
      },
    );

/// Informe del borrado de datos devuelto por el servidor.
Future<void> showAdminErasureReportDialog(
  BuildContext context,
  ErasureReport report,
) => showDialog<void>(
  context: context,
  builder: (context) {
    final l10n = context.localizations;
    return AlertDialog(
      icon: Icon(Icons.task_alt_rounded, color: context.palette.success),
      title: Text(l10n.adminErasureReportTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminKeyValue(
              label: l10n.adminErasureMode,
              value: report.mode.label(l10n),
            ),
            AdminKeyValue(
              label: l10n.adminErasureRecords,
              value: AdminFormat.number(report.deletedRecords),
            ),
            AdminKeyValue(
              label: l10n.adminErasureFiles,
              value: AdminFormat.number(report.storedFiles),
            ),
            AdminKeyValue(
              label: l10n.adminErasureFailedFiles,
              value: AdminFormat.number(report.failedFileDeletions),
            ),
            if (report.failedFileDeletions > 0) ...[
              const SizedBox(height: TokensSpacing.s),
              Text(
                l10n.adminErasureFailedFilesHint,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  },
);
