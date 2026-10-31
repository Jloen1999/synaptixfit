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
import '../../login/page/login_page.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_layout.dart';
import '../bloc/forgot_password_bloc.dart';

/// «¿Has olvidado tu contraseña?» (`/forgot-password`): pide el correo con el
/// enlace. Dice lo mismo exista o no la cuenta.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  static const path = '/forgot-password';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ForgotPasswordBloc>(),
    child: const _ForgotPasswordView(),
  );
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView>
    with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  /// «Enviar enlace» desaparece al enviarlo: el foco pasa al botón principal
  /// de «Revisa tu correo» (WCAG 2.4.3).
  final _backToLoginFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _backToLoginFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordEvent.submitted(_email.text),
    );
  }

  void _back() => context.canPop() ? context.pop() : context.go(LoginPage.path);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (a, b) => a.sentTo == null && b.sentTo != null,
      listener: (context, state) => WidgetsBinding.instance
          .addPostFrameCallback((_) => _backToLoginFocus.requestFocus()),
      builder: (context, state) {
        final sentTo = state.sentTo;
        return AuthLayout(
          appBar: AppPageBar(leading: BackButton(onPressed: _back)),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: sentTo == null
                        ? l10n.authForgotTitle
                        : l10n.authForgotSentTitle,
                    subtitle: sentTo == null
                        ? l10n.authForgotSubtitle
                        : l10n.authForgotSentSubtitle,
                  ),
                  const SizedBox(height: TokensSpacing.xl),
                  if (sentTo != null) ...[
                    AppInlineMessage(
                      message: state.resends == 0
                          ? l10n.authForgotSent(sentTo)
                          : l10n.authForgotResent,
                      tone: AppMessageTone.success,
                    ),
                    const SizedBox(height: TokensSpacing.l),
                    AppPrimaryButton(
                      label: l10n.authBackToLogin,
                      focusNode: _backToLoginFocus,
                      onPressed: () => context.go(LoginPage.path),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    TextButton(
                      onPressed: state.submitting ? null : _submit,
                      child: Text(l10n.authForgotResend),
                    ),
                  ] else ...[
                    AppTextField(
                      label: l10n.fieldEmail,
                      controller: _email,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      validator: (v) => Validators.email(v)?.text(context),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                  ],
                  if (state.error case final error?) ...[
                    if (sentTo != null) const SizedBox(height: TokensSpacing.s),
                    AppInlineMessage(message: errorMessage(context, error)),
                    const SizedBox(height: TokensSpacing.m),
                  ],
                  if (sentTo == null)
                    AppPrimaryButton(
                      label: l10n.authForgotSend,
                      loading: state.submitting,
                      onPressed: _submit,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
