import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../profile_routes.dart';
import '../../widgets/delete_account_dialog.dart';
import '../../widgets/profile_layout.dart';
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
                      leading: const Icon(Icons.download_rounded),
                      title: Text(l10n.profileExportTitle),
                      subtitle: Text(l10n.profileExportHint),
                      trailing: state.exporting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                        style: TextStyle(color: context.colors.error),
                      ),
                      subtitle: Text(l10n.profileDeleteHint),
                      trailing: state.deleting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
