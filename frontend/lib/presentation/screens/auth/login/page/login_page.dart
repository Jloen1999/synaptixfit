import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/config/app_config.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../app/validators/validators.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../extensions/validation_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../session/bloc/session_bloc.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/google_sign_in_button.dart';
import '../bloc/login_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const path = '/login';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginBloc>().add(
      LoginEvent.submitted(email: _email.text, password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        switch (state) {
          case LoginSuccess(:final account):
            context.read<SessionBloc>().add(
              SessionEvent.authenticated(account),
            );
          case LoginFailure(:final error):
            context.showSnack(errorMessage(context, error));
          default:
            break;
        }
      },
      builder: (context, state) {
        final busy = state is LoginSubmitting;
        return AuthLayout(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: l10n.loginTitle,
                    subtitle: l10n.loginSubtitle,
                  ),
                  const SizedBox(height: TokensSpacing.xl),
                  AppTextField(
                    label: l10n.fieldEmail,
                    controller: _email,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => Validators.email(v)?.text(context),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  AppTextField(
                    label: l10n.fieldPassword,
                    controller: _password,
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => Validators.requiredText(v)?.text(context),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: TokensSpacing.l),
                  AppPrimaryButton(
                    label: l10n.loginAction,
                    loading: busy,
                    onPressed: _submit,
                  ),
                  if (getIt<AppConfig>().googleSignInAvailable) ...[
                    const SizedBox(height: TokensSpacing.m),
                    _OrDivider(label: l10n.commonOr),
                    const SizedBox(height: TokensSpacing.m),
                    GoogleSignInButton(
                      label: l10n.loginWithGoogle,
                      enabled: !busy,
                      onPressed: () => context.read<LoginBloc>().add(
                        const LoginEvent.googleRequested(
                          awaitsWebButton: kIsWeb,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.l),
                  TextButton(
                    onPressed: busy ? null : () => context.go('/register'),
                    child: Text(l10n.loginGoToRegister),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
          child: Text(label, style: context.textStyles.labelMedium),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
