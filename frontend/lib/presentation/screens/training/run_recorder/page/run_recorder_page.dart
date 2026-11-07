import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/device_permission.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../profile/permissions/page/permission_request_sheet.dart';
import '../../run_home/page/run_battery_sheet.dart';
import '../../training_routes.dart';
import '../../widgets/run_labels.dart';
import '../../widgets/training_section_bar.dart';
import '../bloc/run_recorder_bloc.dart';

/// Grabar una carrera con el GPS (pantalla completa, ADR 0037). Antes de la
/// primera se pide la ubicación explicando para qué sirve; si se deniega,
/// «Abrir ajustes» o apuntarla a mano. Con la pantalla apagada sigue grabando
/// (aviso fijo «Grabando tu carrera · 3,2 km · 18:40»). Salir a mitad la pausa
/// y se sigue desde Entreno › Correr.
class RunRecorderPage extends StatelessWidget {
  const RunRecorderPage({super.key, this.workoutId, this.eventId});

  final String? workoutId;
  final String? eventId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final texts = RunNotificationTexts(
      title: l10n.runNotificationTitle,
      channelName: l10n.runNotificationChannel,
      body: (meters, seconds, step) => [
        RunLabels.km(l10n, meters),
        RunLabels.clock(seconds),
        if (step != null) RunLabels.step(l10n, step),
      ].join(' · '),
    );
    return BlocProvider(
      create: (_) => getIt<RunRecorderBloc>()
        ..add(
          RunRecorderEvent.started(
            workoutId: workoutId,
            eventId: eventId,
            texts: texts,
          ),
        ),
      child: const _RecorderView(),
    );
  }
}

class _RecorderView extends StatefulWidget {
  const _RecorderView();

  @override
  State<_RecorderView> createState() => _RecorderViewState();
}

class _RecorderViewState extends State<_RecorderView> with ErrorsMessageMixin {
  late final AppLifecycleListener _lifecycle;

  RunRecorderBloc get _bloc => context.read<RunRecorderBloc>();

  @override
  void initState() {
    super.initState();
    // Al irse a segundo plano se guarda ya: si el sistema cierra la app, no
    // se pierde nada.
    _lifecycle = AppLifecycleListener(
      onPause: () {
        if (mounted) _bloc.add(const RunRecorderEvent.persistRequested());
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  bool _active(RunRecorderState s) =>
      s.phase == RunPhase.recording || s.phase == RunPhase.paused;

  /// Vuelve al apartado Correr de Entreno (cambia de pestaña con `go`).
  void _toRunHome() => context.go(TrainingPaths.section(TrainingSection.run));

  Future<void> _start() async {
    final l10n = context.localizations;
    final result = await ensureDevicePermission(
      context,
      DevicePermission.location,
      alternativeLabel: l10n.runLogByHand,
    );
    if (!mounted) return;
    switch (result) {
      case PermissionRequestResult.granted:
        _bloc.add(const RunRecorderEvent.recordingStarted());
      case PermissionRequestResult.alternative:
        context.pushReplacement(TrainingPaths.pastActivity);
      case PermissionRequestResult.notNow:
        break;
    }
  }

  Future<void> _finish(RunRecorderState state) async {
    final l10n = context.localizations;
    if (state.tooShort) {
      final discard = await showConfirmDialog(
        context,
        title: l10n.runTooShortTitle,
        message: l10n.runTooShortMessage(RunRecorderBloc.minMinutes),
        confirmLabel: l10n.runDiscard,
        cancelLabel: l10n.runKeepGoing,
      );
      if (discard && mounted) {
        _bloc.add(const RunRecorderEvent.discardRequested());
      }
      return;
    }
    final effort = await showEffortDialog(
      context,
      confirmLabel: l10n.runSave,
      subtitle: l10n.runEffortQuestion,
    );
    if (effort != null && mounted) {
      _bloc.add(RunRecorderEvent.finishRequested(effort));
    }
  }

  /// Salir a mitad: se pausa y se dice dónde seguir.
  Future<void> _leave(RunRecorderState state) async {
    final l10n = context.localizations;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.runLeaveTitle,
                  style: sheet.textStyles.titleLarge,
                ),
              ),
            ),
            AppFocusOutline(
              child: ListTile(
                leading: const Icon(Icons.pause_rounded),
                title: Text(l10n.runLeavePause),
                subtitle: Text(l10n.runLeavePauseWhere),
                onTap: () => Navigator.of(sheet).pop('pause'),
              ),
            ),
            AppFocusOutline(
              child: ListTile(
                leading: const Icon(Icons.directions_run_rounded),
                title: Text(l10n.runKeepGoing),
                onTap: () => Navigator.of(sheet).pop('stay'),
              ),
            ),
            AppFocusOutline(
              child: ListTile(
                leading: Icon(AppIcons.delete, color: sheet.colors.error),
                title: Text(l10n.runDiscard),
                subtitle: Text(l10n.runDiscardHint),
                onTap: () => Navigator.of(sheet).pop('discard'),
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'pause':
        _bloc.add(const RunRecorderEvent.pauseRequested());
        context.showSnack(l10n.runPausedWhere);
        _toRunHome();
      case 'discard':
        await _confirmDiscard();
    }
  }

  /// Descartar borra la carrera del móvil: se confirma antes (WCAG 3.3.4).
  Future<void> _confirmDiscard() async {
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.runDiscardTitle,
      message: l10n.runDiscardHint,
      confirmLabel: l10n.runDiscard,
      cancelLabel: l10n.runKeepGoing,
    );
    if (ok && mounted) _bloc.add(const RunRecorderEvent.discardRequested());
  }

  void _listen(BuildContext context, RunRecorderState state) {
    final l10n = context.localizations;
    switch (state.phase) {
      case RunPhase.saved:
        final saved = state.saved!;
        context.showSnack(
          saved.xpDelta > 0
              ? l10n.runSavedXp(saved.xpDelta)
              : l10n.runSavedWhere,
        );
        context.go(TrainingPaths.run(saved.run.blockId));
      case RunPhase.queued:
        context.showSnack(l10n.runQueuedWhere);
        _toRunHome();
      case RunPhase.discarded:
        context.showSnack(l10n.runDiscarded);
        _toRunHome();
      case RunPhase.rejected:
        unawaited(_explainRejected(state));
      default:
        break;
    }
  }

  Future<void> _explainRejected(RunRecorderState state) async {
    final l10n = context.localizations;
    final byHand = await showConfirmDialog(
      context,
      title: l10n.runRejectedTitle,
      message: errorMessage(context, state.finishError!),
      confirmLabel: l10n.runLogByHand,
      cancelLabel: l10n.runBackToRun,
      destructive: false,
    );
    if (!mounted) return;
    if (byHand) {
      context.pushReplacement(TrainingPaths.pastActivity);
    } else {
      _toRunHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return MultiBlocListener(
      listeners: [
        BlocListener<RunRecorderBloc, RunRecorderState>(
          listenWhen: (p, c) => p.phase != c.phase,
          listener: _listen,
        ),
        BlocListener<RunRecorderBloc, RunRecorderState>(
          listenWhen: (p, c) => c.stepChanges != p.stepChanges,
          listener: (context, state) {
            final step = state.guide?.current;
            final text = step == null
                ? l10n.runGuideDone
                : l10n.runGuideNowSpoken(RunLabels.step(l10n, step));
            unawaited(
              SemanticsService.sendAnnouncement(
                View.of(context),
                text,
                Directionality.of(context),
              ),
            );
          },
        ),
        BlocListener<RunRecorderBloc, RunRecorderState>(
          listenWhen: (p, c) => c.locationOff && !p.locationOff,
          listener: (context, _) => context.showSnack(l10n.runLocationOff),
        ),
      ],
      child: BlocBuilder<RunRecorderBloc, RunRecorderState>(
        builder: (context, state) => PopScope(
          canPop: !_active(state),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _active(state)) unawaited(_leave(state));
          },
          child: Scaffold(
            appBar: AppPageBar(
              title: Text(
                state.workout?.name ?? RunLabels.kindName(l10n, state.kind),
              ),
            ),
            body: SafeArea(
              child: switch (state.phase) {
                RunPhase.loading ||
                RunPhase.saving ||
                RunPhase.saved ||
                RunPhase.queued ||
                RunPhase.discarded ||
                RunPhase.rejected => const AppLoadingView(),
                RunPhase.unsupported => _Unsupported(),
                RunPhase.ready => _Ready(state: state, onStart: _start),
                RunPhase.recording || RunPhase.paused => _Recording(
                  state: state,
                  onFinish: () => _finish(state),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Unsupported extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppEmptyState(
      icon: Icons.smartphone_rounded,
      title: l10n.runUnsupportedTitle,
      message: l10n.runDesktopExplain,
      action: AppPrimaryButton(
        label: l10n.runLogByHand,
        icon: Icons.edit_note_rounded,
        onPressed: () => context.pushReplacement(TrainingPaths.pastActivity),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state, required this.onStart});

  final RunRecorderState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RunRecorderBloc>();
    final workout = state.workout;
    return AppContentWidth.reading(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          // Con letra grande pasa a lista: no se corta (WCAG 1.4.4 y 1.4.10).
          AppAdaptiveChoice<ActivityKind>(
            label: l10n.runKindQuestion,
            values: const [
              ActivityKind.run,
              ActivityKind.walk,
              ActivityKind.bike,
            ],
            selected: state.kind,
            labelOf: (k) => RunLabels.kindName(l10n, k),
            iconOf: RunLabels.kindIcon,
            onChanged: (k) => bloc.add(RunRecorderEvent.kindChanged(k)),
          ),
          if (workout != null) ...[
            const SizedBox(height: TokensSpacing.l),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(workout.name, style: context.textStyles.titleMedium),
                  const SizedBox(height: TokensSpacing.xs),
                  for (final g in workout.groups)
                    Text(RunLabels.group(l10n, g)),
                  const SizedBox(height: TokensSpacing.s),
                  Text(
                    l10n.runGuideIntro,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.l),
          Text(l10n.runLocationWhy, style: context.textStyles.bodyMedium),
          const SizedBox(height: TokensSpacing.m),
          AppPrimaryButton(
            label: l10n.runStartNow,
            icon: Icons.play_arrow_rounded,
            onPressed: onStart,
          ),
          const SizedBox(height: TokensSpacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => showRunBatterySheet(context),
              icon: const Icon(Icons.battery_saver_rounded),
              label: Text(l10n.runBatteryHelp),
            ),
          ),
        ],
      ),
    );
  }
}

class _Recording extends StatelessWidget {
  const _Recording({required this.state, required this.onFinish});

  final RunRecorderState state;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RunRecorderBloc>();
    final paused = state.phase == RunPhase.paused;
    final guide = state.guide;
    final step = guide?.current;
    final big = context.textStyles.displayMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return AppContentWidth.reading(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          if (paused)
            AppInlineMessage(
              message: l10n.runPausedBanner,
              tone: AppMessageTone.warning,
            )
          else if (state.signalLost || state.gpsError != null)
            AppInlineMessage(
              message: l10n.runSearchingSignal,
              tone: AppMessageTone.warning,
            ),
          if (step != null) ...[
            const SizedBox(height: TokensSpacing.s),
            // Sin liveRegion: «Quedan…» cambia cada segundo; el cambio de paso
            // ya se anuncia una vez.
            Semantics(
              container: true,
              child: AppCard(
                color: context.colors.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.runGuideStepOf(guide!.index + 1, guide.steps.length),
                      style: context.textStyles.labelLarge?.copyWith(
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      RunLabels.step(l10n, step),
                      style: context.textStyles.headlineMedium?.copyWith(
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      l10n.runGuideRemaining(
                        RunLabels.amount(
                          l10n,
                          step.copyWith(
                            value: guide.remaining(
                              state.activeSeconds,
                              state.meters,
                            ),
                          ),
                        ),
                      ),
                      style: context.textStyles.titleMedium?.copyWith(
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                    if (guide.next case final next?)
                      Text(
                        l10n.runGuideNext(RunLabels.step(l10n, next)),
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ] else if (guide != null && guide.finished) ...[
            const SizedBox(height: TokensSpacing.s),
            AppInlineMessage(
              message: l10n.runGuideDone,
              tone: AppMessageTone.success,
            ),
          ],
          const SizedBox(height: TokensSpacing.l),
          MergeSemantics(
            child: Column(
              children: [
                Text(RunLabels.km(l10n, state.meters), style: big),
                Text(l10n.runDistance, style: context.textStyles.labelLarge),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    children: [
                      Text(
                        RunLabels.clock(state.activeSeconds),
                        style: context.textStyles.headlineMedium,
                      ),
                      Text(l10n.runTime, style: context.textStyles.labelLarge),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: l10n.runPaceLabelSpoken(
                    RunLabels.paceSpoken(l10n, state.paceSecondsPerKm),
                  ),
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text(
                          RunLabels.pace(state.paceSecondsPerKm),
                          style: context.textStyles.headlineMedium,
                        ),
                        Text(
                          l10n.runPaceUnit,
                          style: context.textStyles.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.runPaceExplain,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.l),
          if (paused)
            AppPrimaryButton(
              label: l10n.runResume,
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  bloc.add(const RunRecorderEvent.resumeRequested()),
            )
          else
            AppPrimaryButton(
              label: l10n.runPause,
              icon: Icons.pause_rounded,
              onPressed: () =>
                  bloc.add(const RunRecorderEvent.pauseRequested()),
            ),
          const SizedBox(height: TokensSpacing.s),
          AppSecondaryButton(
            label: l10n.runFinish,
            icon: const Icon(Icons.stop_rounded),
            onPressed: onFinish,
          ),
          const SizedBox(height: TokensSpacing.m),
          Text(
            l10n.runScreenOffHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
