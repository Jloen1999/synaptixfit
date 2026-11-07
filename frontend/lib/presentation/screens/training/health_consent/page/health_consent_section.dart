import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/health_consent_bloc.dart';
import 'health_consent_sheet.dart';

/// Qué hacer con los registros anteriores al retirar el permiso.
enum _WithdrawChoice { keep, delete }

/// Fila de Ajustes › Privacidad y datos con el permiso de datos de salud del
/// registro diario (ADR 0034): si está dado, cuándo y «Retirar»; si no, «Dar
/// permiso», que abre la misma explicación que antes del registro.
class HealthConsentSection extends StatelessWidget {
  const HealthConsentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<HealthConsentBloc>()..add(const HealthConsentEvent.started()),
      child: const _HealthConsentTile(),
    );
  }
}

class _HealthConsentTile extends StatelessWidget with ErrorsMessageMixin {
  const _HealthConsentTile();

  Future<void> _withdraw(BuildContext context) async {
    final l10n = context.localizations;
    final choice = await showDialog<_WithdrawChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileHealthConsentWithdrawTitle),
        content: Text(l10n.profileHealthConsentWithdrawMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _WithdrawChoice.keep),
            child: Text(l10n.profileHealthConsentWithdrawKeep),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            onPressed: () =>
                Navigator.pop(dialogContext, _WithdrawChoice.delete),
            child: Text(l10n.profileHealthConsentWithdrawDelete),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    context.read<HealthConsentBloc>().add(
      HealthConsentEvent.withdrawn(
        deleteRecords: choice == _WithdrawChoice.delete,
      ),
    );
  }

  Future<void> _give(BuildContext context) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: context.read<HealthConsentBloc>(),
      child: const HealthConsentSheet(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<HealthConsentBloc, HealthConsentState>(
      listenWhen: (a, b) =>
          b.withdrawals > a.withdrawals ||
          (b.saveError != null && a.saveError != b.saveError),
      listener: (context, state) => context.showSnack(switch (state.saveError) {
        final error? => errorMessage(context, error),
        null => l10n.profileHealthConsentWithdrawn,
      }),
      builder: (context, state) {
        final String? subtitle;
        if (state.loading) {
          subtitle = null;
        } else if (state.error case final error?) {
          subtitle = errorMessage(context, error);
        } else if (state.given) {
          final date = state.consent?.givenAt;
          subtitle = date == null
              ? l10n.profileHealthConsentGivenNoDate
              : l10n.profileHealthConsentGiven(DateFormat.yMMMd().format(date));
        } else {
          subtitle = l10n.profileHealthConsentNotGiven;
        }
        final busy = state.loading || state.saving;
        return AppFocusOutline(
          child: ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: Text(l10n.profileHealthConsentTitle),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: busy
                ? const SizedBox.square(
                    dimension: TokensSize.iconS,
                    child: CircularProgressIndicator(
                      strokeWidth: TokensSize.spinnerStroke,
                    ),
                  )
                : Text(
                    state.error != null
                        ? l10n.commonRetry
                        : state.given
                        ? l10n.profileHealthConsentWithdraw
                        : l10n.profileHealthConsentGive,
                    style: context.textStyles.labelLarge,
                  ),
            enabled: !busy,
            onTap: () {
              if (state.error != null) {
                context.read<HealthConsentBloc>().add(
                  const HealthConsentEvent.started(),
                );
              } else if (state.given) {
                _withdraw(context);
              } else {
                _give(context);
              }
            },
          ),
        );
      },
    );
  }
}
