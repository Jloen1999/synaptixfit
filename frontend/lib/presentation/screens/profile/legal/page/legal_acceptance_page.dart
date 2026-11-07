import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../bloc/legal_acceptance_bloc.dart';
import '../widgets/legal_consent_field.dart';

/// Pantalla completa para aceptar la política y las condiciones (ADR 0034).
/// El router la abre antes que el onboarding o los permisos cuando hace falta
/// (quien entra con Google por primera vez, o tras cambiar la versión) y la
/// quita al aceptar. No se puede saltar: la única otra salida es cerrar sesión.
class LegalAcceptancePage extends StatelessWidget {
  const LegalAcceptancePage({super.key});

  static const path = '/legal-acceptance';

  @override
  Widget build(BuildContext context) => const _LegalAcceptanceView();
}

class _LegalAcceptanceView extends StatefulWidget {
  const _LegalAcceptanceView();

  @override
  State<_LegalAcceptanceView> createState() => _LegalAcceptanceViewState();
}

class _LegalAcceptanceViewState extends State<_LegalAcceptanceView>
    with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  bool _leaving = false;

  void _accept() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LegalAcceptanceBloc>().add(
      const LegalAcceptanceEvent.accepted(),
    );
  }

  void _logout() {
    setState(() => _leaving = true);
    context.read<SessionBloc>().add(const SessionEvent.logoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<LegalAcceptanceBloc, LegalAcceptanceState>(
      builder: (context, state) {
        final busy = state.accepting || _leaving;
        return PopScope(
          // Atrás no la salta: hay que aceptar o cerrar sesión.
          canPop: false,
          child: Scaffold(
            appBar: AppPageBar.reading(
              title: Text(l10n.appName),
              automaticallyImplyLeading: false,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(TokensSpacing.l),
                child: AppContentWidth.reading(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.privacy_tip_outlined,
                            size: TokensSize.iconXl,
                            color: context.colors.secondary,
                          ),
                        ),
                        const SizedBox(height: TokensSpacing.m),
                        Semantics(
                          header: true,
                          child: Text(
                            state.updated
                                ? l10n.profileLegalAcceptTitleUpdated
                                : l10n.profileLegalAcceptTitle,
                            style: context.textStyles.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: TokensSpacing.s),
                        Text(
                          state.updated
                              ? l10n.profileLegalAcceptMessageUpdated
                              : l10n.profileLegalAcceptMessage,
                          style: context.textStyles.bodyLarge,
                        ),
                        const SizedBox(height: TokensSpacing.m),
                        LegalConsentField(
                          enabled: !busy,
                          autofocus: true,
                          requiredMessage: l10n.profileLegalCheckboxRequired,
                        ),
                        if (state.error case final error?) ...[
                          const SizedBox(height: TokensSpacing.s),
                          AppInlineMessage(
                            message: errorMessage(context, error),
                          ),
                        ],
                        const SizedBox(height: TokensSpacing.l),
                        AppPrimaryButton(
                          label: l10n.profileLegalAcceptAction,
                          icon: Icons.check_rounded,
                          loading: state.accepting,
                          onPressed: busy ? null : _accept,
                        ),
                        const SizedBox(height: TokensSpacing.l),
                        Text(
                          l10n.profileLegalDeclineHint,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: TokensSpacing.s),
                        AppSecondaryButton(
                          label: l10n.profileLogoutAction,
                          icon: const Icon(AppIcons.leave),
                          loading: _leaving,
                          onPressed: busy ? null : _logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
