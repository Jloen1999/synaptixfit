import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_di.dart';
import '../../../../domain/enums/reminder_kind.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/account/account.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/widgets.dart';
import '../../academic/academic_routes.dart';
import '../../auth/session/bloc/session_bloc.dart';
import '../../planner/planner_routes.dart';
import '../../progress/progress_routes.dart';
import '../../training/training_routes.dart';
import '../bloc/reminders_bloc.dart';
import 'l10n_reminder_texts.dart';

/// Envuelve el armazón de pestañas con [RemindersBloc]: programa los avisos
/// locales al entrar, los borra al cerrar sesión y, al tocar uno, lleva a su
/// pantalla. Se monta dentro de `AchievementsHost`.
class RemindersHost extends StatelessWidget {
  const RemindersHost({super.key, required this.child});

  final Widget child;

  /// Enfoque de uso de la cuenta; sin cuenta cargada, ambos.
  static UsageFocus focusOf(Account? account) =>
      account?.usageFocus ?? UsageFocus.both;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Sin pereza: nadie lee el bloc, pero debe arrancar al entrar.
      lazy: false,
      create: (context) => getIt<RemindersBloc>()
        ..add(
          RemindersEvent.started(
            focus: focusOf(context.read<SessionBloc>().account),
            texts: L10nReminderTexts(context.localizations),
          ),
        ),
      child: _RemindersListener(child: child),
    );
  }
}

class _RemindersListener extends StatelessWidget {
  const _RemindersListener({required this.child});

  final Widget child;

  /// Repasos y entrenar son pestañas (`go`); el planificador es una pantalla
  /// completa (`push`, para no destruir las pestañas).
  void _open(BuildContext context, ReminderKind kind) {
    switch (kind) {
      case ReminderKind.dueReviews:
        context.go(AcademicPaths.root);
      case ReminderKind.sportBlock:
        context.go(TrainingPaths.root);
      case ReminderKind.studyBlock:
        unawaited(context.push<void>(PlannerPaths.root));
      case ReminderKind.exam || ReminderKind.deadline:
        unawaited(context.push<void>(PlannerPaths.deadlines));
      case ReminderKind.weeklySummary:
        context.go(ProgressPaths.root);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Ofrecer los avisos una vez, justo después de planificar o estudiar.
        BlocListener<RemindersBloc, RemindersState>(
          listenWhen: (previous, current) =>
              !previous.offerReminders && current.offerReminders,
          listener: (context, _) async {
            final bloc = context.read<RemindersBloc>();
            // No encima de otro diálogo (p. ej. la celebración de una
            // insignia): se espera a que el armazón vuelva a estar delante.
            for (var i = 0; i < 60; i++) {
              if (!context.mounted) return;
              if (ModalRoute.of(context)?.isCurrent ?? true) break;
              await Future<void>.delayed(const Duration(seconds: 1));
            }
            if (!context.mounted) return;
            final l10n = context.localizations;
            final accepted = await showConfirmDialog(
              context,
              title: l10n.remindersOfferTitle,
              message: l10n.remindersOfferMessage,
              confirmLabel: l10n.remindersOfferAccept,
              cancelLabel: l10n.remindersOfferDecline,
              destructive: false,
              barrierDismissible: false,
            );
            bloc.add(RemindersEvent.offerAnswered(accepted: accepted));
          },
        ),
        BlocListener<RemindersBloc, RemindersState>(
          listenWhen: (previous, current) =>
              current.permissionDeniedCount > previous.permissionDeniedCount,
          listener: (context, _) => context.showSnack(
            context.localizations.remindersPermissionDeniedBody,
          ),
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) =>
              previous is SessionAuthenticatedState &&
              current is! SessionAuthenticatedState,
          listener: (context, _) => context.read<RemindersBloc>().add(
            const RemindersEvent.signedOut(),
          ),
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) =>
              current is SessionAuthenticatedState,
          listener: (context, state) => context.read<RemindersBloc>().add(
            RemindersEvent.focusChanged(
              RemindersHost.focusOf(context.read<SessionBloc>().account),
            ),
          ),
        ),
        BlocListener<RemindersBloc, RemindersState>(
          listenWhen: (previous, current) =>
              current.openRequest != null &&
              current.openRequest != previous.openRequest,
          listener: (context, state) {
            _open(context, state.openRequest!);
            context.read<RemindersBloc>().add(
              const RemindersEvent.openHandled(),
            );
          },
        ),
      ],
      child: child,
    );
  }
}
