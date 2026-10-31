import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../app/validators/validators.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../extensions/validation_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../forgot_password/page/forgot_password_page.dart';
import '../../login/page/login_page.dart';
import '../../session/bloc/session_bloc.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_layout.dart';
import '../bloc/reset_password_bloc.dart';

/// Contraseña nueva desde el enlace del correo (`/reset-password?token=…`).
/// Funciona con o sin sesión; al terminar, todas las sesiones quedan cerradas,
/// también la de este dispositivo.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, required this.token});

  static const path = '/reset-password';

  final String token;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ResetPasswordBloc>(),
    child: _ResetPasswordView(token: token),
  );
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView({required this.token});

  final String token;

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView>
    with ErrorsMessageMixin {
  static const _invalidLink = AppError.business('AUTH_RESET_TOKEN_INVALID');

  final _formKey = GlobalKey<FormState>();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  /// «Guardar contraseña» desaparece al terminar o si el enlace ya no sirve: el
  /// foco pasa al botón principal nuevo (WCAG 2.4.3).
  final _nextFocus = FocusNode();

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    _nextFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ResetPasswordBloc>().add(
      ResetPasswordEvent.submitted(token: widget.token, newPassword: _new.text),
    );
  }

  void _onChanged(BuildContext context, ResetPasswordState state) {
    if (state is ResetPasswordDone) {
      // El servidor ya revocó todas las sesiones: se cierra también la local
      // para que «Iniciar sesión» no lleve a Inicio con una sesión muerta.
      final session = context.read<SessionBloc>();
      if (session.state is SessionAuthenticatedState) {
        session.add(const SessionEvent.logoutRequested());
      }
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _nextFocus.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
      listenWhen: (_, b) =>
          b is ResetPasswordDone ||
          (b is ResetPasswordFailure && b.error == _invalidLink),
      listener: _onChanged,
      builder: (context, state) {
        // Sin token (dirección incompleta) el enlace no sirve: no hace falta
        // preguntar al servidor.
        final error = widget.token.isEmpty
            ? _invalidLink
            : switch (state) {
                ResetPasswordFailure(:final error) => error,
                _ => null,
              };
        final done = state is ResetPasswordDone;
        final linkDead = error == _invalidLink;
        final (title, subtitle) = done
            ? (l10n.authResetDoneTitle, l10n.authResetDoneSubtitle)
            : linkDead
            ? (l10n.authResetExpiredTitle, l10n.authResetExpiredSubtitle)
            : (l10n.authResetTitle, l10n.authResetSubtitle);
        return AuthLayout(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(title: title, subtitle: subtitle),
                  const SizedBox(height: TokensSpacing.xl),
                  if (done) ...[
                    AppInlineMessage(
                      message: l10n.authResetDone,
                      tone: AppMessageTone.success,
                    ),
                    const SizedBox(height: TokensSpacing.l),
                    AppPrimaryButton(
                      label: l10n.loginAction,
                      focusNode: _nextFocus,
                      onPressed: () => context.go(LoginPage.path),
                    ),
                  ] else if (linkDead) ...[
                    AppInlineMessage(message: errorMessage(context, error!)),
                    const SizedBox(height: TokensSpacing.l),
                    AppPrimaryButton(
                      label: l10n.authResetRequestAnother,
                      focusNode: _nextFocus,
                      onPressed: () => context.go(ForgotPasswordPage.path),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    TextButton(
                      onPressed: () => context.go(LoginPage.path),
                      child: Text(l10n.authBackToLogin),
                    ),
                  ] else ...[
                    AppTextField(
                      label: l10n.profilePasswordNew,
                      helper: l10n.fieldPasswordHint,
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
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) =>
                          v != _new.text ? l10n.profilePasswordMismatch : null,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    if (error != null) ...[
                      AppInlineMessage(message: errorMessage(context, error)),
                      const SizedBox(height: TokensSpacing.m),
                    ],
                    AppPrimaryButton(
                      label: l10n.authResetSave,
                      loading: state is ResetPasswordSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    TextButton(
                      onPressed: () => context.go(LoginPage.path),
                      child: Text(l10n.authBackToLogin),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
