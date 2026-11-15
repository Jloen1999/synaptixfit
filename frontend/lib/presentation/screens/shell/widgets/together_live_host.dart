import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_di.dart';
import '../../../extensions/context_extensions.dart';
import '../../home/home_routes.dart';
import '../../social/social_routes.dart';
import '../../social/together/widgets/together_labels.dart';
import '../../training/training_routes.dart';
import '../bloc/together_live_bloc.dart';

/// Canal en directo de «Con amigos» (ADR 0047), montado en `AchievementsHost`:
/// lo abre con la app en primer plano y lo cierra en segundo plano (y al cerrar
/// sesión, porque el armazón se desmonta). Si un amigo empieza un entreno
/// juntos en el que estoy y no estoy ya en él, avisa «Ana ha empezado a entrenar · Entrar».
/// Al abrir la app, lleva una vez al entreno o la sala en marcha.
class TogetherLiveHost extends StatefulWidget {
  const TogetherLiveHost({super.key, required this.child});

  final Widget child;

  @override
  State<TogetherLiveHost> createState() => _TogetherLiveHostState();
}

class _TogetherLiveHostState extends State<TogetherLiveHost> {
  late final TogetherLiveBloc _bloc = getIt<TogetherLiveBloc>()
    ..add(const TogetherLiveEvent.started());
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) => _bloc.add(switch (state) {
        AppLifecycleState.resumed => const TogetherLiveEvent.foregrounded(),
        _ => const TogetherLiveEvent.backgrounded(),
      }),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_bloc.close());
    super.dispose();
  }

  /// Dónde está la persona ahora: la pantalla de arriba, también si se abrió
  /// con `push` (la configuración del router guarda la de debajo).
  String _location() => GoRouter.of(context).state.uri.path;

  void _onStartedByFriend(TogetherLiveStart start) {
    final here = _location();
    // En la pantalla de espera ya entra sola; en su sesión no hace falta.
    if (here == SocialPaths.togetherWorkout(start.workoutId) ||
        here == TrainingPaths.session(start.sessionId)) {
      return;
    }
    final l10n = context.localizations;
    // En cola: un «Deshacer» abierto no se tapa (se confirmaría sin decidirlo).
    context.showActionSnack(
      l10n.togetherFriendStarted(togetherName(context, start.name)),
      actionLabel: l10n.togetherGo,
      replaceCurrent: false,
      onAction: () =>
          unawaited(context.push<void>(TrainingPaths.session(start.sessionId))),
    );
  }

  /// Solo si se ha entrado por la puerta normal (Inicio, sin nada encima): un
  /// aviso del móvil o un enlace de rutina que abrió la app ya llevan a otro
  /// sitio, y ese manda.
  void _onOpenOnLaunch(TogetherLiveOpen open) {
    final router = GoRouter.of(context);
    if (_location() != HomePaths.root || router.canPop()) return;
    unawaited(
      context.push<void>(switch (open) {
        TogetherLiveOpenSession(:final sessionId) => TrainingPaths.session(
          sessionId,
        ),
        TogetherLiveOpenStudyRoom(:final roomId) =>
          SocialPaths.togetherStudyRoom(roomId),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<TogetherLiveBloc, TogetherLiveState>(
        listenWhen: (p, c) =>
            (c.startedByFriend != null &&
                c.startedByFriend != p.startedByFriend) ||
            (c.openOnLaunch != null && c.openOnLaunch != p.openOnLaunch),
        listener: (context, state) {
          if (state.startedByFriend case final start?) {
            _onStartedByFriend(start);
          } else if (state.openOnLaunch case final open?) {
            _onOpenOnLaunch(open);
          }
        },
        child: widget.child,
      ),
    );
  }
}
