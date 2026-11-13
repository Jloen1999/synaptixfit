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
        accountId: context.read<SessionBloc>().account?.id,
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

  /// «Concentración 2 de 4 · luego 5 min de descanso» o «Descanso de 5 min ·
  /// luego concentración 3 de 4»: qué fase es y qué viene después.
  static String _phaseHeader(
    BuildContext context,
    PomodoroState state,
    PomodoroConfig config,
  ) {
    final l10n = context.localizations;
    final total = config.cyclesBeforeLongBreak;
    final done = state.completedFocusCycles % total;
    if (state.phase == FocusPhase.focus) {
      final current = done + 1;
      final breakMinutes = current >= total
          ? config.longBreakMinutes
          : config.shortBreakMinutes;
      return l10n.plannerPomodoroFocusHeader(current, total, breakMinutes);
    }
    final minutes = state.phase == FocusPhase.longBreak
        ? config.longBreakMinutes
        : config.shortBreakMinutes;
    // Tras el descanso largo se empieza otra tanda.
    final next = state.phase == FocusPhase.longBreak || done == 0
        ? 1
        : done + 1;
    return l10n.plannerPomodoroBreakHeader(minutes, next, total);
  }

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
      // La regla del servidor (`xpStatus`) se conserva, pero sin cifras: la XP
      // se ve en Progreso (ADR 0038).
      case PomodoroNoticeXpEarned(:final account):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        context.showSnack(l10n.plannerPomodoroFocusDone);
      case PomodoroNoticeDailyXpLimitReached():
        context.showSnack(l10n.plannerPomodoroXpLimitReached);
      case PomodoroNoticeRecordFailed():
        context.showSnack(l10n.plannerPomodoroRecordFailed);
      case PomodoroNoticeBlockMarked():
        context.showSnack(l10n.plannerPomodoroBlockMarked);
      case PomodoroNoticeBlockMarkFailed(:final error):
        context.showSnack(errorMessage(context, error));
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
                  if (state.blockCheck == BlockCheck.asking ||
                      state.blockCheck == BlockCheck.saving) ...[
                    _BlockDoneCard(
                      title: title,
                      saving: state.blockCheck == BlockCheck.saving,
                    ),
                    const SizedBox(height: TokensSpacing.m),
                  ],
                  // Sin bloque, se elige a qué asignatura cuentan las fases.
                  if (state.blockId == null && state.subjects.isNotEmpty) ...[
                    _SubjectPicker(state: state),
                    const SizedBox(height: TokensSpacing.m),
                  ],
                  _PhaseHeader(
                    phase: state.phase,
                    color: color,
                    text: _phaseHeader(context, state, config),
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
                        dimension: TokensSize.pomodoroRing,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: state.remainingFraction),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : TokensDuration.slow,
                          builder: (context, value, child) => CustomPaint(
                            painter: PomodoroRingPainter(
                              fraction: value,
                              color: color,
                              trackColor: color.withValues(
                                alpha: AppPill.tintAlpha,
                              ),
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

/// «¿Terminaste este bloque?» tras una concentración ligada a un bloque:
/// «Sí, está hecho» lo marca en el calendario (da su XP); «Aún no» la cierra
/// y se sigue con el Pomodoro.
class _BlockDoneCard extends StatelessWidget {
  const _BlockDoneCard({required this.title, required this.saving});

  final String? title;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<PomodoroBloc>();
    final onColor = context.colors.onPrimaryContainer;
    final name = title;
    // La tarjeta desaparece al responder: el foco pasa al siguiente control
    // (el selector o «Empezar») en lugar de perderse.
    void answer(bool done) {
      FocusScope.of(context).nextFocus();
      bloc.add(PomodoroEvent.blockDoneAnswered(done: done));
    }

    return Semantics(
      container: true,
      child: AppCard(
        color: context.colors.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                name == null || name.isEmpty
                    ? l10n.plannerPomodoroBlockQuestion
                    : l10n.plannerPomodoroBlockQuestionNamed(name),
                style: context.textStyles.titleMedium?.copyWith(color: onColor),
              ),
            ),
            const SizedBox(height: TokensSpacing.xxs),
            Text(
              l10n.plannerPomodoroBlockHint,
              style: context.textStyles.bodyMedium?.copyWith(color: onColor),
            ),
            const SizedBox(height: TokensSpacing.s),
            Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.xs,
              children: [
                AppPrimaryButton(
                  loading: saving,
                  icon: Icons.check_rounded,
                  onPressed: () => answer(true),
                  label: l10n.plannerPomodoroBlockYes,
                ),
                TextButton(
                  onPressed: saving ? null : () => answer(false),
                  child: Text(l10n.plannerPomodoroBlockNotYet),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// «¿Qué estudias?»: asignatura a la que se vinculan las fases. Se fija al
/// empezar; mientras corre se ve pero no se cambia.
class _SubjectPicker extends StatelessWidget {
  const _SubjectPicker({required this.state});

  final PomodoroState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final known = state.subjects.any((s) => s.id == state.subjectId);
    if (!state.canPickSubject) {
      final name = state.subjects
          .where((s) => s.id == state.subjectId)
          .firstOrNull
          ?.name;
      return Text(
        l10n.plannerPomodoroStudying(name ?? l10n.plannerPomodoroNoSubject),
        textAlign: TextAlign.center,
        style: context.textStyles.titleSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );
    }
    return DropdownButtonFormField<String?>(
      // La clave cambia con la asignatura: el campo se rehace si llega otra
      // (p. ej. al recuperar una fase guardada).
      key: ValueKey(state.subjectId),
      initialValue: known ? state.subjectId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.plannerPomodoroSubjectLabel,
        prefixIcon: const Icon(Icons.school_outlined),
      ),
      items: [
        DropdownMenuItem(child: Text(l10n.plannerPomodoroNoSubject)),
        for (final subject in state.subjects)
          DropdownMenuItem(
            value: subject.id,
            child: Text(subject.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) =>
          context.read<PomodoroBloc>().add(PomodoroEvent.subjectSelected(id)),
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
    final focus = state.phase == FocusPhase.focus;
    final (label, icon, event) = switch (state.status) {
      PomodoroStatus.idle => (
        focus ? l10n.plannerPomodoroStartFocus : l10n.plannerPomodoroStartBreak,
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
    // Cada botón dice lo que hace (antes, iconos sueltos de «siguiente» y
    // «reiniciar»): el principal, en grande; cambiar de fase y empezar de
    // cero, debajo y con texto (vocabulario, «Pomodoro»).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          label: label,
          icon: icon,
          onPressed: () => bloc.add(event),
        ),
        const SizedBox(height: TokensSpacing.s),
        Tooltip(
          message: focus
              ? l10n.plannerPomodoroToBreakHint
              : l10n.plannerPomodoroToFocusHint,
          child: OutlinedButton.icon(
            onPressed: () => bloc.add(const PomodoroEvent.skipPressed()),
            icon: Icon(
              focus ? Icons.free_breakfast_rounded : Icons.psychology_rounded,
            ),
            label: Text(
              focus ? l10n.plannerPomodoroToBreak : l10n.plannerPomodoroToFocus,
            ),
          ),
        ),
        TextButton.icon(
          // Con el reloj en marcha o en pausa, empezar de cero pierde lo que
          // se lleva: se pregunta antes.
          onPressed: () async {
            if (state.status != PomodoroStatus.idle) {
              final ok = await showConfirmDialog(
                context,
                title: l10n.plannerPomodoroResetTitle,
                message: l10n.plannerPomodoroResetMessage,
                confirmLabel: l10n.plannerPomodoroReset,
                cancelLabel: l10n.plannerPomodoroResetKeep,
              );
              if (!ok || bloc.isClosed) return;
            }
            bloc.add(const PomodoroEvent.resetPressed());
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(l10n.plannerPomodoroReset),
        ),
      ],
    );
  }
}

/// Fase actual y lo que viene después, con el icono en el color de la fase
/// («Concentración 2 de 4 · luego 5 min de descanso»).
class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({
    required this.phase,
    required this.color,
    required this.text,
  });

  final FocusPhase phase;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Región viva: al pasar al descanso (o volver) el lector anuncia la fase.
    return Semantics(
      header: true,
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            phase == FocusPhase.focus
                ? Icons.psychology_rounded
                : Icons.free_breakfast_rounded,
            color: color,
            size: TokensSize.iconM,
          ),
          const SizedBox(width: TokensSpacing.s),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
          ),
        ],
      ),
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
