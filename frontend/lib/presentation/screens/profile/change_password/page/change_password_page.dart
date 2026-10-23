import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../app/validators/validators.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../extensions/validation_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/change_password_bloc.dart';

/// Cambiar la contraseña, o crearla si la cuenta es solo de Google.
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChangePasswordBloc>(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView>
    with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  late final bool _hasPassword =
      context.read<SessionBloc>().account?.hasPassword ?? true;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ChangePasswordBloc>().add(
      ChangePasswordEvent.submitted(
        currentPassword: _hasPassword ? _current.text : null,
        newPassword: _new.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(
        title: Text(
          _hasPassword
              ? l10n.profilePasswordChangeTitle
              : l10n.profilePasswordCreateTitle,
        ),
      ),
      body: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
        listener: (context, state) {
          switch (state) {
            case ChangePasswordSuccess(:final account):
              if (account != null) {
                context.read<SessionBloc>().add(
                  SessionEvent.accountUpdated(account),
                );
              }
              context.showSnack(l10n.profilePasswordSaved);
              context.pop(true);
            case ChangePasswordFailure(:final error):
              context.showSnack(errorMessage(context, error));
            default:
              break;
          }
        },
        builder: (context, state) {
          return ProfileScrollBody(
            children: [
              if (!_hasPassword) ...[
                Text(
                  l10n.profilePasswordCreateHint,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.l),
              ],
              Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_hasPassword) ...[
                        AppTextField(
                          label: l10n.profilePasswordCurrent,
                          controller: _current,
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.password],
                          validator: (v) =>
                              Validators.requiredText(v)?.text(context),
                        ),
                        const SizedBox(height: TokensSpacing.m),
                      ],
                      AppTextField(
                        label: l10n.profilePasswordNew,
                        hint: l10n.fieldPasswordHint,
                        controller: _new,
                        icon: Icons.lock_reset_rounded,
                        obscure: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => Validators.password(v)?.text(context),
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      AppTextField(
                        label: l10n.profilePasswordConfirm,
                        controller: _confirm,
                        icon: Icons.lock_reset_rounded,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        validator: (v) => v != _new.text
                            ? l10n.profilePasswordMismatch
                            : null,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: TokensSpacing.l),
                      AppPrimaryButton(
                        label: l10n.commonSave,
                        loading: state is ChangePasswordSubmitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
