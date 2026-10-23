import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/metric_chips.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_dialogs.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../bloc/live_session_bloc.dart';
import 'set_record_sheet.dart';

/// Sesión de entrenamiento en vivo.
class LiveSessionPage extends StatelessWidget {
  const LiveSessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<LiveSessionBloc>()..add(LiveSessionEvent.started(sessionId)),
      child: const _LiveView(),
    );
  }
}

class _LiveView extends StatefulWidget {
  const _LiveView();

  @override
  State<_LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<_LiveView> {
  Timer? _ticker;

  LiveSessionBloc get _bloc => context.read<LiveSessionBloc>();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _bloc.add(const LiveSessionEvent.ticked());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _finish(LiveSessionState state) async {
    final rpe = await showRpeDialog(context);
    if (rpe != null && mounted) {
      _bloc.add(LiveSessionEvent.finishRequested(rpe));
    }
  }

  Future<void> _abandon() async {
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.trainingAbandonTitle,
      message: l10n.trainingAbandonMessage,
      confirmLabel: l10n.trainingAbandon,
    );
    if (ok && mounted) _bloc.add(const LiveSessionEvent.abandonRequested());
  }

  Future<void> _editSet({
    required String title,
    required String? plannedExerciseId,
    required int setNumber,
    required ExerciseParameters? parameters,
    SessionSet? existing,
    SessionSet? previous,
    PersonalRecord? lastTime,
  }) async {
    final result = await showSetRecordSheet(
      context,
      title: title,
      existingSetId: existing?.id,
      initial: SetRecord(
        plannedExerciseId: plannedExerciseId,
        setNumber: setNumber,
        repsDone: existing?.repsDone ?? previous?.repsDone ?? parameters?.reps,
        // Sin serie anterior hoy, se propone el peso de la última sesión.
        weightKg:
            existing?.weightKg ??
            previous?.weightKg ??
            lastTime?.weightKg ??
            _plannedWeight(parameters, setNumber),
        completed: existing?.completed ?? true,
        failedReps: existing?.failedReps ?? 0,
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case SetSheetSave(:final record):
        _bloc.add(LiveSessionEvent.setRecorded(record));
      case SetSheetDelete(:final setId):
        _bloc.add(LiveSessionEvent.setDeleted(setId));
    }
  }

  double? _plannedWeight(ExerciseParameters? p, int setNumber) {
    final weights = p?.weightsKg;
    if (weights != null && weights.length >= setNumber) {
      return weights[setNumber - 1];
    }
    return p?.weightKg;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<LiveSessionBloc, LiveSessionState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        final title = state.dayNumber != null
            ? dayTitle(l10n, state.dayNumber!, state.dayName)
            : l10n.trainingFreeSession;
        return Scaffold(
          appBar: AppPageBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (state.routineName != null)
                  Text(
                    state.routineName!,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            actions: [
              if (state.status == LiveStatus.ready)
                Semantics(
                  label: l10n.trainingTotalTime(
                    formatClock(state.elapsedSeconds),
                  ),
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensSpacing.s,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: context.colors.secondary,
                        ),
                        const SizedBox(width: TokensSpacing.xs),
                        Text(
                          formatClock(state.elapsedSeconds),
                          style: context.textStyles.titleMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.status == LiveStatus.ready && !state.completed)
                IconButton(
                  tooltip: l10n.trainingAbandon,
                  onPressed: state.finishing ? null : _abandon,
                  icon: const Icon(Icons.exit_to_app_rounded),
                ),
            ],
          ),
          body: switch (state.status) {
            LiveStatus.loading => const AppSkeletonList(height: 140),
            LiveStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () =>
                  _bloc.add(LiveSessionEvent.started(state.sessionId ?? '')),
            ),
            LiveStatus.ready => Column(
              children: [
                if (state.saving) const LinearProgressIndicator(),
                if (state.restRemaining != null) _RestBanner(state: state),
                Expanded(
                  child: _ExerciseList(state: state, onEdit: _editSet),
                ),
              ],
            ),
          },
          bottomNavigationBar:
              state.status == LiveStatus.ready && !state.completed
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: Row(
                      children: [
                        if (!state.isFree)
                          Expanded(
                            child: Text(
                              l10n.trainingSetsProgress(
                                state.completedSets,
                                state.plannedSets,
                              ),
                              style: context.textStyles.labelLarge,
                            ),
                          ),
                        if (state.isFree) const Spacer(),
                        AppPrimaryButton(
                          label: l10n.trainingFinishAction,
                          icon: Icons.flag_rounded,
                          loading: state.finishing,
                          onPressed: state.finishing
                              ? null
                              : () => _finish(state),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _RestBanner extends StatelessWidget {
  const _RestBanner({required this.state});

  final LiveSessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final remaining = state.restRemaining ?? 0;
    final progress = state.restTotal == 0 ? 0.0 : remaining / state.restTotal;
    return Container(
      width: double.infinity,
      color: context.colors.secondaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.m,
        vertical: TokensSpacing.s,
      ),
      child: TrainingContent(
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: CircularProgressIndicator(
                value: progress,
                color: context.colors.secondary,
                backgroundColor: context.colors.surface,
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: l10n.trainingRestSemantics(remaining),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainingRest,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      formatClock(remaining),
                      style: context.textStyles.headlineSmall?.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.trainingRestLess,
              onPressed: () =>
                  bloc.add(const LiveSessionEvent.restAdjusted(-15)),
              icon: const Icon(Icons.remove_rounded),
            ),
            IconButton(
              tooltip: l10n.trainingRestMore,
              onPressed: () =>
                  bloc.add(const LiveSessionEvent.restAdjusted(15)),
              icon: const Icon(Icons.add_rounded),
            ),
            TextButton(
              onPressed: () => bloc.add(const LiveSessionEvent.restSkipped()),
              child: Text(l10n.trainingSkip),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _EditSet =
    Future<void> Function({
      required String title,
      required String? plannedExerciseId,
      required int setNumber,
      required ExerciseParameters? parameters,
      SessionSet? existing,
      SessionSet? previous,
      PersonalRecord? lastTime,
    });

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.state, required this.onEdit});

  final LiveSessionState state;
  final _EditSet onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final session = state.session!;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.completed)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.m),
                  child: AppCard(
                    color: context.colors.secondaryContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: context.colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: Text(
                            l10n.trainingSessionAlreadyCompleted,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.isFree)
                _FreeSetsCard(
                  sets: session.setsFor(null),
                  readOnly: state.completed,
                  onEdit: onEdit,
                ),
              if (!state.completed &&
                  (state.bookends?.warmUp.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                  child: _BookendsCard(
                    title: l10n.trainingWarmUpTitle,
                    hint: l10n.trainingWarmUpSummary(
                      state.bookends!.warmUp.length,
                    ),
                    icon: Icons.whatshot_rounded,
                    exercises: state.bookends!.warmUp,
                  ),
                ),
              for (final e in state.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                  child: _ExerciseCard(
                    exercise: e,
                    lastTime: state.lastPerformance[e.exerciseId],
                    sets: session.setsFor(e.id),
                    active: state.activeExerciseId == e.id,
                    seconds: state.exerciseSeconds[e.id] ?? 0,
                    readOnly: state.completed,
                    onEdit: onEdit,
                  ),
                ),
              if (!state.completed &&
                  (state.bookends?.coolDown.isNotEmpty ?? false))
                _BookendsCard(
                  title: l10n.trainingCoolDownTitle,
                  hint: l10n.trainingCoolDownSummary(
                    state.bookends!.coolDown.length,
                  ),
                  icon: Icons.self_improvement_rounded,
                  exercises: state.bookends!.coolDown,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Calentamiento o vuelta a la calma: plegado por defecto para no distraer;
/// cada ejercicio abre su ficha con las instrucciones. Cabecera propia en vez de
/// `ExpansionTile` para que cada fila tenga su contorno de foco y se respete
/// «reducir movimiento».
class _BookendsCard extends StatefulWidget {
  const _BookendsCard({
    required this.title,
    required this.hint,
    required this.icon,
    required this.exercises,
  });

  final String title;
  final String hint;
  final IconData icon;
  final List<Exercise> exercises;

  @override
  State<_BookendsCard> createState() => _BookendsCardState();
}

class _BookendsCardState extends State<_BookendsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: AnimatedSize(
        duration: context.motion(TokensDuration.normal),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFocusOutline(
              child: Semantics(
                expanded: _expanded,
                child: ListTile(
                  leading: Icon(widget.icon, color: context.colors.secondary),
                  title: Text(
                    widget.title,
                    style: context.textStyles.titleSmall,
                  ),
                  subtitle: Text(widget.hint),
                  trailing: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: context.motion(TokensDuration.normal),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
              ),
            ),
            if (_expanded)
              for (final e in widget.exercises)
                AppFocusOutline(
                  child: ListTile(
                    leading: ExerciseThumbnail(
                      url: e.thumbnailUrl,
                      size: TokensSize.thumbnailS,
                      icon: e.category.icon,
                    ),
                    title: Text(e.name),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(TrainingPaths.exercise(e.id)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    this.lastTime,
    required this.sets,
    required this.active,
    required this.seconds,
    required this.readOnly,
    required this.onEdit,
  });

  final PlannedExercise exercise;

  /// Mejor serie de la última vez que hizo este ejercicio.
  final PersonalRecord? lastTime;
  final List<SessionSet> sets;
  final bool active;
  final int seconds;
  final bool readOnly;
  final _EditSet onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final p = exercise.parameters;
    final maxRecorded = sets.fold(0, (m, s) => math.max(m, s.setNumber));
    final rows = math.max(p.sets, maxRecorded);
    final done = sets.where((s) => s.completed).length;
    return AppCard(
      color: active ? context.colors.surfaceContainerLow : null,
      onTap: readOnly
          ? null
          : () => bloc.add(
              LiveSessionEvent.exerciseSelected(active ? null : exercise.id),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExerciseThumbnail(
                url: exercise.thumbnailUrl,
                size: TokensSize.thumbnailS,
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: context.textStyles.titleSmall,
                    ),
                    if (lastTime != null)
                      // El lector leería «×» como «multiplicado por».
                      Semantics(
                        label: lastTime!.weightKg == null
                            ? null
                            : l10n.trainingLastTimeWeightSpoken(
                                formatNumber(lastTime!.weightKg!),
                                lastTime!.reps,
                              ),
                        excludeSemantics: lastTime!.weightKg != null,
                        child: Text(
                          lastTime!.weightKg == null
                              ? l10n.trainingLastTimeReps(lastTime!.reps)
                              : l10n.trainingLastTimeWeight(
                                  formatNumber(lastTime!.weightKg!),
                                  lastTime!.reps,
                                ),
                          style: context.textStyles.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Text(
                      l10n.trainingSetsDone(done, p.sets),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: done >= p.sets
                            ? context.palette.success
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!readOnly)
                Semantics(
                  label: active
                      ? l10n.trainingExerciseTimerActive(formatClock(seconds))
                      : l10n.trainingExerciseTimerPaused(formatClock(seconds)),
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Icon(
                        active
                            ? Icons.play_circle_fill_rounded
                            : Icons.pause_circle_outline_rounded,
                        size: 18,
                        color: active
                            ? context.colors.secondary
                            : context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: TokensSpacing.xxs),
                      Text(
                        formatClock(seconds),
                        style: context.textStyles.labelLarge,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          ExerciseParameterChips(parameters: p),
          const SizedBox(height: TokensSpacing.s),
          for (var n = 1; n <= rows; n++)
            _SetRow(
              setNumber: n,
              set: sets.where((s) => s.setNumber == n).firstOrNull,
              readOnly: readOnly,
              onTap: () => onEdit(
                title: exercise.exerciseName,
                plannedExerciseId: exercise.id,
                setNumber: n,
                parameters: p,
                existing: sets.where((s) => s.setNumber == n).firstOrNull,
                previous: sets.where((s) => s.setNumber == n - 1).firstOrNull,
                lastTime: lastTime,
              ),
            ),
          if (!readOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: rows >= 50
                    ? null
                    : () => onEdit(
                        title: exercise.exerciseName,
                        plannedExerciseId: exercise.id,
                        setNumber: rows + 1,
                        parameters: p,
                        previous: sets
                            .where((s) => s.setNumber == rows)
                            .firstOrNull,
                      ),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.trainingExtraSet),
              ),
            ),
        ],
      ),
    );
  }
}

class _FreeSetsCard extends StatelessWidget {
  const _FreeSetsCard({
    required this.sets,
    required this.readOnly,
    required this.onEdit,
  });

  final List<SessionSet> sets;
  final bool readOnly;
  final _EditSet onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final next = sets.fold(0, (m, s) => math.max(m, s.setNumber)) + 1;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.trainingFreeSets, style: context.textStyles.titleSmall),
          Text(
            l10n.trainingFreeSetsHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          for (final s in sets)
            _SetRow(
              setNumber: s.setNumber,
              set: s,
              readOnly: readOnly,
              onTap: () => onEdit(
                title: l10n.trainingFreeSets,
                plannedExerciseId: null,
                setNumber: s.setNumber,
                parameters: null,
                existing: s,
              ),
            ),
          if (!readOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: next > 50
                    ? null
                    : () => onEdit(
                        title: l10n.trainingFreeSets,
                        plannedExerciseId: null,
                        setNumber: next,
                        parameters: null,
                        previous: sets.lastOrNull,
                      ),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.trainingAddSet),
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.readOnly,
    required this.onTap,
  });

  final int setNumber;
  final SessionSet? set;
  final bool readOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = set;
    final (icon, color) = switch (s) {
      null => (Icons.radio_button_unchecked_rounded, context.colors.outline),
      SessionSet(completed: true) => (
        Icons.check_circle_rounded,
        context.palette.success,
      ),
      _ => (Icons.cancel_rounded, context.palette.warning),
    };
    final summary = s == null
        ? l10n.trainingSetPending
        : [
            l10n.trainingSetReps(s.repsDone ?? 0),
            if (s.weightKg != null)
              l10n.trainingChipWeight(formatNumber(s.weightKg!)),
            if (s.failedReps > 0) l10n.trainingSetFailed(s.failedReps),
            if (!s.completed) l10n.trainingSetNotCompleted,
          ].join(' · ');
    return AppFocusOutline(
      borderRadius: BorderRadius.circular(TokensRadius.s),
      child: InkWell(
        onTap: readOnly ? null : onTap,
        borderRadius: BorderRadius.circular(TokensRadius.s),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: TokensLayout.minTouchTarget,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: TokensSpacing.s),
              SizedBox(
                width: 64,
                child: Text(
                  l10n.trainingSetNumber(setNumber),
                  style: context.textStyles.labelLarge,
                ),
              ),
              Expanded(
                child: Text(summary, style: context.textStyles.bodyMedium),
              ),
              if (!readOnly)
                Icon(
                  s == null ? Icons.add_rounded : Icons.edit_outlined,
                  size: 18,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
