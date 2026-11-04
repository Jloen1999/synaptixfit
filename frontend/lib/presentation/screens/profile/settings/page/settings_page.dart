import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/app_language.dart';
import '../../../../../domain/enums/legal_document_kind.dart';
import '../../language/bloc/language_bloc.dart';
import '../../../../../domain/enums/appearance_mode.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../training/health_consent/page/health_consent_section.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../profile_routes.dart';
import '../../widgets/delete_account_dialog.dart';
import '../../widgets/profile_layout.dart';
import '../../appearance/bloc/appearance_bloc.dart';
import '../bloc/settings_bloc.dart';

/// Versión mostrada en Ajustes (coincide con `version` de pubspec.yaml).
const String profileAppVersion = '1.0.0';

/// Ajustes (`/profile/settings`).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsBloc>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget with ErrorsMessageMixin {
  const _SettingsView();

  Future<void> _delete(BuildContext context, bool hasPassword) async {
    final bloc = context.read<SettingsBloc>();
    final confirmation = await showDeleteAccountDialog(
      context,
      hasPassword: hasPassword,
    );
    if (confirmation == null) return;
    bloc.add(
      SettingsEvent.deleteRequested(
        password: confirmation.password,
        confirm: confirmation.confirm,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = context.localizations;
    final session = context.read<SessionBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileLogoutTitle),
        content: Text(l10n.profileLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.profileLogoutAction),
          ),
        ],
      ),
    );
    if (ok ?? false) session.add(const SessionEvent.logoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final account = context.select((SessionBloc b) => b.account);
    final hasPassword = account?.hasPassword ?? true;
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.profileSettingsTitle)),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (a, b) => a.outcome != b.outcome || a.error != b.error,
        listener: (context, state) {
          if (state.error case final error?) {
            context.showSnack(errorMessage(context, error));
            return;
          }
          switch (state.outcome) {
            case SettingsOutcome.exported:
              context.showSnack(l10n.profileExportDone);
            case SettingsOutcome.exportCancelled:
              context.showSnack(l10n.profileExportCancelled);
            case SettingsOutcome.deleted:
              context.showSnack(l10n.profileDeleteDone);
              context.read<SessionBloc>().add(
                const SessionEvent.logoutRequested(),
              );
            case null:
              break;
          }
        },
        builder: (context, state) {
          return ProfileScrollBody(
            children: [
              _Group(
                title: l10n.profileSettingsAccountGroup,
                children: [
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.password_rounded),
                      title: Text(
                        hasPassword
                            ? l10n.profilePasswordChangeTitle
                            : l10n.profilePasswordCreateTitle,
                      ),
                      subtitle: hasPassword
                          ? null
                          : Text(l10n.profilePasswordCreateHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(ProfilePaths.changePassword),
                    ),
                  ),
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.manage_accounts_outlined),
                      title: Text(l10n.profileEditAccountTitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(ProfilePaths.editAccount),
                    ),
                  ),
                ],
              ),
              const _AppearanceGroup(),
              const _LanguageGroup(),
              _Group(
                title: l10n.profileSettingsNotificationsGroup,
                children: [
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(l10n.profileNotificationsTitle),
                      subtitle: Text(l10n.profileNotificationsHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(ProfilePaths.notifications),
                    ),
                  ),
                ],
              ),
              _Group(
                title: l10n.profileSettingsPrivacyGroup,
                children: [
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(l10n.profilePermissionsTitle),
                      subtitle: Text(l10n.profilePermissionsHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(ProfilePaths.permissions),
                    ),
                  ),
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.profileLegalPrivacy),
                      subtitle: Text(l10n.profileLegalPrivacyHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(
                        ProfilePaths.legal(LegalDocumentKind.privacy),
                      ),
                    ),
                  ),
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(l10n.profileLegalTerms),
                      subtitle: Text(l10n.profileLegalTermsHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(
                        ProfilePaths.legal(LegalDocumentKind.terms),
                      ),
                    ),
                  ),
                  const HealthConsentSection(),
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: Text(l10n.profileExportTitle),
                      subtitle: Text(l10n.profileExportHint),
                      trailing: state.exporting
                          ? const SizedBox.square(
                              dimension: TokensSize.iconS,
                              child: CircularProgressIndicator(
                                strokeWidth: TokensSize.spinnerStroke,
                              ),
                            )
                          : null,
                      enabled: !state.exporting,
                      onTap: () => context.read<SettingsBloc>().add(
                        const SettingsEvent.exportRequested(),
                      ),
                    ),
                  ),
                  AppFocusOutline(
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_forever_rounded,
                        color: context.colors.error,
                      ),
                      title: Text(
                        l10n.profileDeleteTitle,
                        style: context.textStyles.bodyLarge?.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                      subtitle: Text(l10n.profileDeleteHint),
                      trailing: state.deleting
                          ? const SizedBox.square(
                              dimension: TokensSize.iconS,
                              child: CircularProgressIndicator(
                                strokeWidth: TokensSize.spinnerStroke,
                              ),
                            )
                          : null,
                      enabled: !state.deleting,
                      onTap: () => _delete(context, hasPassword),
                    ),
                  ),
                ],
              ),
              _Group(
                children: [
                  AppFocusOutline(
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: Text(l10n.profileLogoutAction),
                      onTap: () => _logout(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              Center(
                child: Text(
                  l10n.profileAppVersion(profileAppVersion),
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: TokensSpacing.l),
            ],
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) AppSectionHeader(title: title!),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Idioma: los textos cambian al momento y se guarda en este dispositivo. Los
/// nombres de idioma van en su propio idioma, para encontrar el tuyo aunque la
/// app esté en otro.
class _LanguageGroup extends StatelessWidget {
  const _LanguageGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final language = context.select((LanguageBloc b) => b.state.language);
    final options = [
      (AppLanguage.system, l10n.profileLanguageSystem),
      (AppLanguage.es, l10n.languageNameEs),
      (AppLanguage.en, l10n.languageNameEn),
      (AppLanguage.fr, l10n.languageNameFr),
      (AppLanguage.pt, l10n.languageNamePt),
    ];
    return _Group(
      title: l10n.profileSettingsLanguageGroup,
      children: [
        RadioGroup<AppLanguage>(
          groupValue: language,
          onChanged: (value) {
            if (value != null) {
              context.read<LanguageBloc>().add(LanguageEvent.changed(value));
            }
          },
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: l10n.profileSettingsLanguageGroup,
            child: Column(
              children: [
                for (final (value, label) in options)
                  AppFocusOutline(
                    child: RadioListTile<AppLanguage>(
                      value: value,
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: value == AppLanguage.system
                          ? const Icon(Icons.phone_iphone_rounded)
                          : null,
                      title: value.languageCode == null
                          ? Text(label)
                          : Semantics(
                              attributedLabel: AttributedString(
                                label,
                                attributes: [
                                  LocaleStringAttribute(
                                    range: TextRange(
                                      start: 0,
                                      end: label.length,
                                    ),
                                    locale: Locale(value.languageCode!),
                                  ),
                                ],
                              ),
                              child: ExcludeSemantics(child: Text(label)),
                            ),
                      subtitle: value == AppLanguage.system
                          ? Text(l10n.profileLanguageSystemHint)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Apariencia: se aplica al momento y se guarda en este dispositivo.
class _AppearanceGroup extends StatelessWidget {
  const _AppearanceGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final mode = context.select((AppearanceBloc b) => b.state.mode);
    final options = [
      (
        AppearanceMode.dark,
        Icons.dark_mode_outlined,
        l10n.profileAppearanceDark,
      ),
      (
        AppearanceMode.light,
        Icons.light_mode_outlined,
        l10n.profileAppearanceLight,
      ),
      (
        AppearanceMode.system,
        Icons.brightness_auto_outlined,
        l10n.profileAppearanceSystem,
      ),
    ];
    return _Group(
      title: l10n.profileSettingsAppearanceGroup,
      children: [
        RadioGroup<AppearanceMode>(
          groupValue: mode,
          onChanged: (value) {
            if (value != null) {
              context.read<AppearanceBloc>().add(
                AppearanceEvent.changed(value),
              );
            }
          },
          // El lector anuncia el grupo («Apariencia») antes de cada opción.
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: l10n.profileSettingsAppearanceGroup,
            child: Column(
              children: [
                for (final (value, icon, label) in options)
                  AppFocusOutline(
                    child: RadioListTile<AppearanceMode>(
                      value: value,
                      // Icono delante y radio al final, como el resto de ajustes.
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: Icon(icon),
                      title: Text(label),
                      subtitle: value == AppearanceMode.system
                          ? Text(l10n.profileAppearanceSystemHint)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
