import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_di.dart';
import '../../auth/session/bloc/session_bloc.dart';
import '../bloc/achievements_bloc.dart';
import 'achievement_dialog.dart';
import 'reminders_host.dart';

/// Envuelve el armazón de pestañas con [AchievementsBloc]: pasa la cuenta
/// recargada a la sesión global y muestra la celebración de logros.
class AchievementsHost extends StatelessWidget {
  const AchievementsHost({super.key, required this.child});

  /// Pantalla de insignias (módulo de progreso).
  static const badgesPath = '/progress/badges';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AchievementsBloc>()
        ..add(
          AchievementsEvent.started(
            account: context.read<SessionBloc>().account,
          ),
        ),
      // Los recordatorios locales viven con el armazón, igual que los logros.
      child: _AchievementsListener(child: RemindersHost(child: child)),
    );
  }
}

class _AchievementsListener extends StatefulWidget {
  const _AchievementsListener({required this.child});

  final Widget child;

  @override
  State<_AchievementsListener> createState() => _AchievementsListenerState();
}

class _AchievementsListenerState extends State<_AchievementsListener> {
  /// Evita abrir una segunda celebración si llegan logros con una abierta:
  /// los nuevos se acumulan y se muestran al cerrarla.
  bool _showing = false;

  Future<void> _celebrate(AchievementsState state) async {
    if (_showing || !state.hasCelebration) return;
    _showing = true;
    final bloc = context.read<AchievementsBloc>();
    final result = await AchievementDialog.show(
      context,
      level: state.levelReached,
      badges: state.badges,
    );
    _showing = false;
    bloc.add(
      AchievementsEvent.celebrated(
        level: state.levelReached,
        badgeIds: [for (final badge in state.badges) badge.id],
      ),
    );
    if (result == AchievementDialogResult.seeBadges && mounted) {
      unawaited(context.push<void>(AchievementsHost.badgesPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AchievementsBloc, AchievementsState>(
          listenWhen: (previous, current) =>
              current.account != null && current.account != previous.account,
          listener: (context, state) => context.read<SessionBloc>().add(
            SessionEvent.accountUpdated(state.account!),
          ),
        ),
        BlocListener<AchievementsBloc, AchievementsState>(
          listenWhen: (previous, current) =>
              current.hasCelebration &&
              (current.levelReached != previous.levelReached ||
                  current.badges.length != previous.badges.length),
          listener: (context, state) => unawaited(_celebrate(state)),
        ),
      ],
      child: widget.child,
    );
  }
}
