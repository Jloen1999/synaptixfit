import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/focus.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../widgets/pomodoro_ring_painter.dart';
import '../bloc/pomodoro_bloc.dart';

/// Temporizador Pomodoro (`/planner/pomodoro`). Con [subjectId]/[blockId] las
/// fases cuentan para esa asignatura o bloque; [title] dice qué se estudia.
/// Con [startWithBreak] empieza por una pausa («Descanso guiado»).
class PomodoroPage extends StatefulWidget {
  const PomodoroPage({
    super.key,
    this.subjectId,
    this.blockId,
    this.title,
    this.startWithBreak = false,
  });

  final String? subjectId;
  final String? blockId;
  final String? title;
  final bool startWithBreak;

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  // Una sola instancia en toda la app: al salir sigue contando.
  final _bloc = getIt<PomodoroBloc>();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Una vez al abrir (los textos necesitan el idioma del contexto).
    if (_started) return;
    _started = true;
    _bloc.add(
      PomodoroEvent.started(
        subjectId: widget.subjectId,
        blockId: widget.blockId,
        startWithBreak: widget.startWithBreak,
        alertTexts: pomodoroAlertTexts(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: _PomodoroView(title: widget.title),
  );
}

/// Textos del aviso de fin de fase y de la notificación fija, en el idioma de
/// la app. Los usan esta pantalla y el armazón de pestañas.
PomodoroAlertTexts pomodoroAlertTexts(BuildContext context) {
  final l10n = context.localizations;
  final time = DateFormat.Hm(l10n.localeName);
  return PomodoroAlertTexts(
    focusEndTitle: l10n.plannerPomodoroAlertFocusTitle,
    focusEndBody: l10n.plannerPomodoroAlertFocusBody,
    breakEndTitle: l10n.plannerPomodoroAlertBreakTitle,
    breakEndBody: l10n.plannerPomodoroAlertBreakBody,
    channelName: l10n.plannerPomodoroAlertChannel,
    focusRunningTitle: l10n.plannerPomodoroOngoingFocus,
    breakRunningTitle: l10n.plannerPomodoroOngoingBreak,
    pausedTitle: l10n.plannerPomodoroOngoingPaused,
    endsAtBody: (endsAt) =>
        l10n.plannerPomodoroOngoingEndsAt(time.format(endsAt.toLocal())),
    remainingBody: l10n.plannerPomodoroOngoingRemaining,
    ongoingChannelName: l10n.plannerPomodoroOngoingChannel,
  );
}

class _PomodoroView extends StatelessWidget with ErrorsMessageMixin {
  const _PomodoroView({this.title});

  final String? title;

  static String _phaseLabel(BuildContext context, FocusPhase phase) {
    final l10n = context.localizations;
    return switch (phase) {
      FocusPhase.focus => l10n.plannerPhaseFocus,
      FocusPhase.shortBreak => l10n.plannerPhaseShortBreak,
      FocusPhase.longBreak => l10n.plannerPhaseLongBreak,
    };
  }

  static Color _phaseColor(BuildContext context, FocusPhase phase) =>
      switch (phase) {
        FocusPhase.focus => context.palette.study,
        FocusPhase.shortBreak => context.colors.secondary,
        FocusPhase.longBreak => context.palette.accent,
      };

  static String _clock(int seconds) => PomodoroBloc.clockText(seconds);

  void _onNotice(BuildContext context, PomodoroNotice notice) {
    final l10n = context.localizations;
    switch (notice) {
      // Saltar una fase no se celebra: la pantalla ya muestra la siguiente.
      case PomodoroNoticePhaseFinished(completed: false):
        return;
      case PomodoroNoticePhaseFinished(:final finished):
        // Refuerzo en primer plano (en el móvil vibra si el sistema lo
        // permite; el sonido solo existe en escritorio). El aviso con la app
        // en segundo plano es una notificación local pendiente.
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        context.showSnack(
          finished == FocusPhase.focus
              ? l10n.plannerPomodoroFocusDone
              : l10n.plannerPomodoroBreakDone,
        );
      // Sustituye al aviso de fase terminada: el texto ya felicita.
      case PomodoroNoticeXpEarned(:final xp, :final account):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        context.showSnack(l10n.plannerPomodoroXpEarned(xp));
      case PomodoroNoticeDailyXpLimitReached():
        context.showSnack(l10n.plannerPomodoroXpLimitReached);
      case PomodoroNoticeRecordFailed():
        context.showSnack(l10n.plannerPomodoroRecordFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<PomodoroBloc, PomodoroState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice != null,
      listener: (context, state) => _onNotice(context, state.notice!),
      builder: (context, state) {
        final bloc = context.read<PomodoroBloc>();
        final config = bloc.config;
        final color = _phaseColor(context, state.phase);
        final phaseLabel = _phaseLabel(context, state.phase);
        final cycle =
            state.completedFocusCycles % config.cyclesBeforeLongBreak +
            (state.phase == FocusPhase.focus ? 1 : 0);
        return Scaffold(
          appBar: AppPageBar.reading(title: Text(l10n.plannerPomodoroTitle)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TokensLayout.readingMaxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  if (title != null && title!.isNotEmpty) ...[
                    Text(
                      l10n.plannerPomodoroStudying(title!),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleMedium,
                    ),
                    const SizedBox(height: TokensSpacing.s),
                  ],
                  Center(
                    child: Chip(
                      avatar: Icon(
                        state.phase == FocusPhase.focus
                            ? Icons.psychology_rounded
                            : Icons.free_breakfast_rounded,
                        color: color,
                        size: 18,
                      ),
                      label: Text(phaseLabel),
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  Center(
                    child: Semantics(
                      liveRegion: false,
                      label: l10n.plannerTimeRemaining(
                        phaseLabel,
                        _clock(state.remainingSeconds),
                      ),
                      excludeSemantics: true,
                      child: SizedBox.square(
                        dimension: 260,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: state.remainingFraction),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : TokensDuration.slow,
                          builder: (context, value, child) => CustomPaint(
                            painter: PomodoroRingPainter(
                              fraction: value,
                              color: color,
                              trackColor: color.withValues(alpha: 0.15),
                            ),
                            child: child,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _clock(state.remainingSeconds),
                                    style: context.textStyles.displayMedium
                                        ?.copyWith(
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ),
                                Text(
                                  l10n.plannerPomodoroCycle(
                                    cycle.clamp(
                                      1,
                                      config.cyclesBeforeLongBreak,
                                    ),
                                    config.cyclesBeforeLongBreak,
                                  ),
                                  style: context.textStyles.labelLarge
                                      ?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state.canAdjust) ...[
                    const SizedBox(height: TokensSpacing.m),
                    _DurationAdjuster(
                      minutes: config.focusMinutes,
                      min: config.minFocusMinutes,
                      max: config.maxFocusMinutes,
                      breakMinutes: config.shortBreakMinutes,
                      limitedByFatigue: state.plan?.limitedByFatigue ?? false,
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.l),
                  _Controls(state: state),
                  // Con una fase en marcha, salir no la para: se dice para que
                  // nadie se quede en esta pantalla «por si acaso».
                  if (state.status == PomodoroStatus.running) ...[
                    const SizedBox(height: TokensSpacing.s),
                    Text(
                      l10n.plannerPomodoroKeepsRunning,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.xl),
                  _StatsSection(state: state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final PomodoroState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<PomodoroBloc>();
    final (label, icon, event) = switch (state.status) {
      PomodoroStatus.idle => (
        l10n.plannerPomodoroStart,
        Icons.play_arrow_rounded,
        const PomodoroEvent.startPressed(),
      ),
      PomodoroStatus.running => (
        l10n.plannerPomodoroPause,
        Icons.pause_rounded,
        const PomodoroEvent.pausePressed(),
      ),
      PomodoroStatus.paused => (
        l10n.plannerPomodoroResume,
        Icons.play_arrow_rounded,
        const PomodoroEvent.resumePressed(),
      ),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          tooltip: l10n.plannerPomodoroReset,
          onPressed: () => bloc.add(const PomodoroEvent.resetPressed()),
          icon: const Icon(Icons.restart_alt_rounded),
        ),
        const SizedBox(width: TokensSpacing.m),
        AppPrimaryButton(
          label: label,
          icon: icon,
          onPressed: () => bloc.add(event),
        ),
        const SizedBox(width: TokensSpacing.m),
        IconButton.outlined(
          tooltip: l10n.plannerPomodoroSkip,
          onPressed: () => bloc.add(const PomodoroEvent.skipPressed()),
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.state});

  final PomodoroState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final stats = state.stats;
    if (stats == null) {
      if (state.statsLoading) {
        return const AppSkeletonGroup(child: AppSkeleton(height: 120));
      }
      return Text(
        l10n.plannerStatsUnavailable,
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.plannerStatsToday),
        _TotalsRow(totals: stats.today),
        const SizedBox(height: TokensSpacing.m),
        AppSectionHeader(title: l10n.plannerStatsWeek),
        _TotalsRow(totals: stats.week),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.totals});

  final FocusTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Row(
      children: [
        Expanded(
          child: AppMetricTile(
            icon: Icons.psychology_rounded,
            color: context.palette.study,
            value: '${totals.focusMinutes}',
            label: l10n.plannerFocusMinutesLabel,
          ),
        ),
        const SizedBox(width: TokensSpacing.s),
        Expanded(
          child: AppMetricTile(
            icon: Icons.repeat_rounded,
            color: context.palette.accent,
            value: '${totals.focusCycles}',
            label: l10n.plannerFocusCyclesLabel,
          ),
        ),
        const SizedBox(width: TokensSpacing.s),
        Expanded(
          child: AppMetricTile(
            icon: Icons.free_breakfast_rounded,
            color: context.colors.secondary,
            value: '${totals.breakMinutes}',
            label: l10n.plannerBreakMinutesLabel,
          ),
        ),
      ],
    );
  }
}

/// Duración del bloque antes de empezar: la recomendada de hoy, ajustable de 5
/// en 5, y por qué es esa.
class _DurationAdjuster extends StatelessWidget {
  const _DurationAdjuster({
    required this.minutes,
    required this.min,
    required this.max,
    required this.breakMinutes,
    required this.limitedByFatigue,
  });

  final int minutes;
  final int min;
  final int max;
  final int breakMinutes;
  final bool limitedByFatigue;

  static const _step = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<PomodoroBloc>();
    return Column(
      children: [
        AppStepperField(
          label: l10n.plannerPomodoroBlockLabel,
          value: minutes,
          min: min,
          max: max,
          step: _step,
          display: l10n.plannerPomodoroMinutes,
          onChanged: (v) => bloc.add(PomodoroEvent.focusMinutesChanged(v)),
        ),
        const SizedBox(height: TokensSpacing.xs),
        Text(
          limitedByFatigue
              ? l10n.plannerPomodoroPlanFatigue(breakMinutes)
              : l10n.plannerPomodoroPlanHint(breakMinutes),
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
