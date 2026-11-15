import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_di.dart';
import '../../../../domain/enums/planner_enums.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/widgets.dart';
import '../../auth/session/bloc/session_bloc.dart';
import '../../planner/planner_routes.dart';
import '../../planner/pomodoro/bloc/pomodoro_bloc.dart';
import '../../planner/pomodoro/page/pomodoro_page.dart';
import '../bloc/study_room_bar_bloc.dart';

/// Al entrar en las pestañas recupera el Pomodoro que quedó en marcha (y
/// registra la fase si terminó con la app cerrada); al cerrar sesión lo para,
/// y también quita la barra y el aviso de la sala «Estudiar juntos». Se monta
/// dentro de `AchievementsHost`.
class FocusTimerHost extends StatefulWidget {
  const FocusTimerHost({super.key, required this.child});

  final Widget child;

  @override
  State<FocusTimerHost> createState() => _FocusTimerHostState();
}

class _FocusTimerHostState extends State<FocusTimerHost> {
  final _bloc = getIt<PomodoroBloc>();
  bool _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    _bloc.add(
      PomodoroEvent.restored(
        alertTexts: pomodoroAlertTexts(context),
        accountId: context.read<SessionBloc>().account?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<SessionBloc, SessionState>(
    listenWhen: (previous, current) =>
        previous is SessionAuthenticatedState &&
        current is! SessionAuthenticatedState,
    listener: (_, _) {
      _bloc.add(const PomodoroEvent.signedOut());
      getIt<StudyRoomBarBloc>().add(const StudyRoomBarEvent.signedOut());
    },
    child: widget.child,
  );
}

/// Barra fina con el Pomodoro en marcha, sobre la navegación: se puede usar
/// el resto de la app sin perderlo de vista. Tocarla vuelve al temporizador;
/// el botón lo pausa o lo reanuda. Sin fase en curso no ocupa nada.
class FocusTimerBar extends StatelessWidget {
  const FocusTimerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      bloc: getIt<PomodoroBloc>(),
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.phase != b.phase ||
          a.remainingSeconds != b.remainingSeconds,
      builder: (context, state) {
        if (state.status == PomodoroStatus.idle) return const SizedBox.shrink();
        final l10n = context.localizations;
        final bloc = getIt<PomodoroBloc>();
        final focus = state.phase == FocusPhase.focus;
        final phase = switch (state.phase) {
          FocusPhase.focus => l10n.plannerPhaseFocus,
          FocusPhase.shortBreak => l10n.plannerPhaseShortBreak,
          FocusPhase.longBreak => l10n.plannerPhaseLongBreak,
        };
        final color = focus ? context.palette.study : context.colors.secondary;
        final clock = PomodoroBloc.clockText(state.remainingSeconds);
        final running = state.status == PomodoroStatus.running;
        return AppTimerStrip(
          color: color,
          icon: focus ? Icons.psychology_rounded : Icons.free_breakfast_rounded,
          label: running ? phase : l10n.plannerPomodoroOngoingPaused,
          clock: clock,
          semanticLabel: running
              ? l10n.plannerPomodoroBarLabel(phase, clock)
              : l10n.plannerPomodoroBarPausedLabel(phase, clock),
          onTap: () => unawaited(context.push<void>(PlannerPaths.pomodoro)),
          trailing: IconButton(
            tooltip: running
                ? l10n.plannerPomodoroPause
                : l10n.plannerPomodoroResume,
            onPressed: () => bloc.add(
              running
                  ? const PomodoroEvent.pausePressed()
                  : const PomodoroEvent.resumePressed(),
            ),
            icon: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        );
      },
    );
  }
}
