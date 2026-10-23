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
import '../../session/bloc/session_bloc.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_layout.dart';
import '../bloc/register_bloc.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  static const path = '/register';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegisterBloc>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<RegisterBloc>().add(
      RegisterEvent.submitted(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        switch (state) {
          case RegisterSuccess(:final account):
            context.read<SessionBloc>().add(
              SessionEvent.authenticated(account),
            );
          case RegisterFailure(:final error):
            context.showSnack(errorMessage(context, error));
          default:
            break;
        }
      },
      builder: (context, state) {
        final busy = state is RegisterSubmitting;
        return AuthLayout(
          appBar: const AppPageBar(),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: l10n.registerTitle,
                    subtitle: l10n.registerSubtitle,
                  ),
                  const SizedBox(height: TokensSpacing.xl),
                  AppTextField(
                    label: l10n.fieldFullName,
                    controller: _name,
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => Validators.minLength(v, 2)?.text(context),
                  ),
                  const SizedBox(height: TokensSpacing.m),
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
                    hint: l10n.fieldPasswordHint,
                    controller: _password,
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => Validators.password(v)?.text(context),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: TokensSpacing.l),
                  AppPrimaryButton(
                    label: l10n.registerAction,
                    loading: busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  TextButton(
                    onPressed: busy ? null : () => context.go('/login'),
                    child: Text(l10n.registerGoToLogin),
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
