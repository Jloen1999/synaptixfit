import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../planner/planner_routes.dart';
import '../../../progress/widgets/achievement_share.dart';
import '../../activity_history/page/activity_history_view.dart';
import '../../training_routes.dart';
import '../../widgets/run_labels.dart';
import '../../widgets/run_map.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_section_bar.dart';
import '../bloc/run_home_bloc.dart';
import 'run_battery_sheet.dart';

/// Apartado «Correr» de la pestaña Entreno (ADR 0037): mapa con «Estás
/// aquí», «Empezar a correr» y «Crear entreno», «Esta semana» con su mini
/// gráfica y «Compartir», «Tus actividades» con su origen y «Tus entrenos de
/// carrera». En web o escritorio explica que se graba desde el móvil y deja
/// apuntar la actividad a mano.
class RunHomePage extends StatelessWidget {
  const RunHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<RunHomeBloc>()..add(const RunHomeEvent.started()),
    child: const _RunHomeView(),
  );
}

class _RunHomeView extends StatelessWidget with ErrorsMessageMixin {
  const _RunHomeView();

  /// Abre una pantalla y recarga al volver.
  static Future<void> open(
    BuildContext context,
    String location, {
    Object? extra,
  }) async {
    final bloc = context.read<RunHomeBloc>();
    await context.push(location, extra: extra);
    if (!bloc.isClosed) bloc.add(const RunHomeEvent.refreshed());
  }

  void _listen(BuildContext context, RunHomeState state) {
    final l10n = context.localizations;
    if (state.actionError case final error?) {
      context.showSnack(errorMessage(context, error));
    }
    switch (state.notice) {
      case RunHomeNotice.scheduled:
        context.showActionSnack(
          l10n.runScheduledWhere,
          actionLabel: l10n.runSeeCalendar,
          onAction: () => context.push(PlannerPaths.root),
        );
      case RunHomeNotice.uploaded:
        context.showSnack(l10n.runPendingUploaded);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RunHomeBloc, RunHomeState>(
      listenWhen: (p, c) =>
          (c.notice != null && p.notice != c.notice) ||
          (c.actionError != null && p.actionError != c.actionError),
      listener: _listen,
      builder: (context, state) => Scaffold(
        appBar: AppPageBar(
          title: Text(l10n.tabTraining),
          actions: [
            IconButton(
              tooltip: l10n.trainingHistoryTitle,
              onPressed: () => open(context, TrainingPaths.activities),
              icon: const Icon(Icons.history_rounded),
            ),
          ],
          bottom: const TrainingSectionBar(current: TrainingSection.run),
        ),
        body: switch (state.status) {
          RunHomeStatus.loading => const AppSkeletonList(height: 120),
          RunHomeStatus.failure => AppErrorView(
            error: state.error!,
            onRetry: () =>
                context.read<RunHomeBloc>().add(const RunHomeEvent.started()),
          ),
          RunHomeStatus.ready => RefreshIndicator(
            onRefresh: () async =>
                context.read<RunHomeBloc>().add(const RunHomeEvent.refreshed()),
            child: _Content(state: state),
          ),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final RunHomeState state;

  Future<void> _createWorkout(BuildContext context) async {
    final l10n = context.localizations;
    final code = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: TokensSpacing.m),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.runCreateWorkoutTitle,
                  style: sheet.textStyles.titleLarge,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.l,
                TokensSpacing.xs,
                TokensSpacing.l,
                TokensSpacing.s,
              ),
              child: Text(l10n.runCreateWorkoutIntro),
            ),
            for (final t in state.templates)
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(
                    Icons.directions_run_rounded,
                    color: sheet.colors.secondary,
                  ),
                  title: Text(RunLabels.templateName(l10n, t.templateCode)),
                  subtitle: Text(
                    [
                      RunLabels.templateWhy(l10n, t.templateCode),
                      t.groups.map((g) => RunLabels.group(l10n, g)).join(' · '),
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.of(sheet).pop(t.templateCode),
                ),
              ),
            AppFocusOutline(
              child: ListTile(
                leading: Icon(
                  Icons.edit_note_rounded,
                  color: sheet.colors.secondary,
                ),
                title: Text(l10n.runCreateFromScratch),
                subtitle: Text(l10n.runCreateFromScratchHint),
                onTap: () => Navigator.of(sheet).pop(''),
              ),
            ),
          ],
        ),
      ),
    );
    if (code == null || !context.mounted) return;
    await _RunHomeView.open(
      context,
      TrainingPaths.newRunWorkout(template: code.isEmpty ? null : code),
    );
  }

  Future<void> _schedule(BuildContext context, RunWorkout workout) async {
    final bloc = context.read<RunHomeBloc>();
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: context.localizations.runScheduleDay,
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: context.localizations.runScheduleTime,
    );
    if (time == null) return;
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    bloc.add(RunHomeEvent.workoutScheduled(workout.id!, start));
  }

  Future<void> _delete(BuildContext context, RunWorkout workout) async {
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.runDeleteWorkoutTitle,
      message: l10n.runDeleteWorkoutMessage,
      confirmLabel: l10n.runDeleteWorkout,
    );
    if (ok && context.mounted) {
      context.read<RunHomeBloc>().add(RunHomeEvent.workoutDeleted(workout.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final unfinished = state.unfinished;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xxl,
      ),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (unfinished != null) ...[
                AppCard(
                  color: context.colors.secondaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.runUnfinishedTitle,
                          style: context.textStyles.titleMedium?.copyWith(
                            color: context.colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.xs),
                      Text(
                        l10n.runUnfinishedMessage,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.s),
                      AppPrimaryButton(
                        label: l10n.runUnfinishedContinue,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => _RunHomeView.open(
                          context,
                          TrainingPaths.recordRun(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              RunMap(
                here: state.here,
                semanticLabel: state.here == null
                    ? l10n.runMapNoHereSpoken
                    : l10n.runMapHereSpoken,
              ),
              if (state.here != null)
                Padding(
                  padding: const EdgeInsets.only(top: TokensSpacing.xs),
                  child: Text(
                    l10n.runYouAreHere,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: TokensSpacing.m),
              if (state.supported) ...[
                AppPrimaryButton(
                  label: l10n.runStart,
                  icon: Icons.directions_run_rounded,
                  onPressed: () =>
                      _RunHomeView.open(context, TrainingPaths.recordRun()),
                ),
              ] else ...[
                AppInlineMessage(
                  message: l10n.runDesktopExplain,
                  tone: AppMessageTone.warning,
                ),
                const SizedBox(height: TokensSpacing.s),
                AppPrimaryButton(
                  label: l10n.runLogByHand,
                  icon: Icons.edit_note_rounded,
                  onPressed: () =>
                      _RunHomeView.open(context, TrainingPaths.pastActivity),
                ),
              ],
              const SizedBox(height: TokensSpacing.s),
              AppSecondaryButton(
                label: l10n.runCreateWorkout,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _createWorkout(context),
              ),
              if (state.pendingUploads > 0) ...[
                const SizedBox(height: TokensSpacing.m),
                AppInlineMessage(
                  message: l10n.runPendingUploads(state.pendingUploads),
                  tone: AppMessageTone.warning,
                ),
              ],
              if (state.planned.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.runPlannedTitle),
                const SizedBox(height: TokensSpacing.s),
                for (final p in state.planned) ...[
                  _PlannedTile(planned: p, supported: state.supported),
                  const SizedBox(height: TokensSpacing.s),
                ],
              ],
              if (state.week case final week?) ...[
                const SizedBox(height: TokensSpacing.l),
                _WeekCard(week: week),
              ],
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(
                title: l10n.runActivitiesTitle(state.totalActivities),
                actionLabel: state.totalActivities > 0 ? l10n.runSeeAll : null,
                onAction: state.totalActivities > 0
                    ? () => _RunHomeView.open(context, TrainingPaths.activities)
                    : null,
              ),
              const SizedBox(height: TokensSpacing.s),
              if (state.activities.isEmpty)
                AppEmptyState.compact(
                  icon: Icons.directions_run_rounded,
                  title: l10n.runActivitiesEmptyTitle,
                  message: l10n.runActivitiesEmptyMessage,
                  action: TextButton.icon(
                    onPressed: () =>
                        _RunHomeView.open(context, TrainingPaths.pastActivity),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(l10n.runLogByHand),
                  ),
                )
              else
                for (final a in state.activities) ...[
                  SportActivityTile(activity: a),
                  const SizedBox(height: TokensSpacing.s),
                ],
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.runWorkoutsTitle),
              const SizedBox(height: TokensSpacing.s),
              if (state.workouts.isEmpty)
                AppEmptyState.compact(
                  icon: Icons.format_list_numbered_rounded,
                  title: l10n.runWorkoutsEmptyTitle,
                  message: l10n.runWorkoutsEmptyMessage,
                  action: TextButton.icon(
                    onPressed: () => _createWorkout(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.runCreateWorkout),
                  ),
                )
              else
                for (final w in state.workouts) ...[
                  _WorkoutTile(
                    workout: w,
                    supported: state.supported,
                    onSchedule: () => _schedule(context, w),
                    onEdit: () => _RunHomeView.open(
                      context,
                      TrainingPaths.runWorkout(w.id!),
                      extra: w,
                    ),
                    onDelete: () => _delete(context, w),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                ],
              if (state.supported) ...[
                const SizedBox(height: TokensSpacing.m),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => showRunBatterySheet(context),
                    icon: const Icon(Icons.battery_saver_rounded),
                    label: Text(l10n.runBatteryHelp),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlannedTile extends StatelessWidget {
  const _PlannedTile({required this.planned, required this.supported});

  final PlannedRun planned;
  final bool supported;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final when = toBeginningOfSentenceCase(
      DateFormat.MMMEd(l10n.localeName).add_Hm().format(planned.start),
    );
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.event_rounded, color: context.colors.secondary),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planned.workoutName, style: context.textStyles.titleSmall),
                Text(
                  l10n.runPlannedWhen(when),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (supported)
            FilledButton.tonal(
              onPressed: () => _RunHomeView.open(
                context,
                TrainingPaths.recordRun(
                  workoutId: planned.workoutId,
                  eventId: planned.blockId,
                ),
              ),
              child: Text(l10n.runStartShort),
            ),
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({
    required this.workout,
    required this.supported,
    required this.onSchedule,
    required this.onEdit,
    required this.onDelete,
  });

  final RunWorkout workout;
  final bool supported;
  final VoidCallback onSchedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(workout.name, style: context.textStyles.titleSmall),
          const SizedBox(height: TokensSpacing.xs),
          for (final g in workout.groups)
            Text(
              RunLabels.group(l10n, g),
              style: context.textStyles.bodyMedium,
            ),
          if (workout.estimatedSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(top: TokensSpacing.xs),
              child: AppPill(
                icon: Icons.schedule_rounded,
                label: RunLabels.estimate(l10n, workout.estimatedSeconds),
              ),
            ),
          const SizedBox(height: TokensSpacing.s),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: TokensSpacing.xs,
            children: [
              IconButton(
                tooltip: l10n.runDeleteWorkout,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              IconButton(
                tooltip: l10n.runEditWorkout,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              TextButton.icon(
                onPressed: onSchedule,
                icon: const Icon(Icons.event_rounded),
                label: Text(l10n.runPutInCalendar),
              ),
              if (supported)
                FilledButton.icon(
                  onPressed: () => _RunHomeView.open(
                    context,
                    TrainingPaths.recordRun(workoutId: workout.id),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.runStartShort),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Esta semana»: distancia, tiempo, desnivel y salidas, con la distancia de
/// cada día en una mini gráfica y «Compartir» (imagen solo con las cifras).
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final RunWeek week;

  void _share(BuildContext context) {
    final l10n = context.localizations;
    final title = l10n.runShareWeekTitle(
      RunLabels.km(l10n, week.distanceMeters),
    );
    final detail = l10n.runShareWeekDetail(
      week.outings,
      RunLabels.clock(week.movingSeconds),
      week.elevationGainMeters,
    );
    final bloc = context.read<RunHomeBloc>();
    showAchievementShareDialog(
      context,
      card: AchievementShareCard(
        emblem: Icon(
          Icons.directions_run_rounded,
          color: context.colors.primary,
          size: TokensSize.medallion,
        ),
        title: title,
        detail: detail,
        accent: context.colors.primary,
      ),
      onShare: (png) => bloc.add(RunHomeEvent.shared(png, '$title · $detail')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final daily = week.dailyDistanceMeters;
    final maxDay = daily.isEmpty ? 0 : daily.reduce(math.max);
    final days = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(
          l10n.localeName,
        ).format(week.weekStart.add(Duration(days: i))),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.runWeekTitle,
                    style: context.textStyles.titleMedium,
                  ),
                ),
              ),
              if (week.outings > 0)
                TextButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l10n.runShare),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.l,
            runSpacing: TokensSpacing.s,
            children: [
              _Figure(
                value: RunLabels.km(l10n, week.distanceMeters),
                label: l10n.runWeekDistance,
              ),
              _Figure(
                value: RunLabels.clock(week.movingSeconds),
                label: l10n.runWeekTime,
              ),
              _Figure(
                value: l10n.runMeters(week.elevationGainMeters),
                label: l10n.runWeekElevation,
              ),
              _Figure(value: '${week.outings}', label: l10n.runWeekOutings),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          Semantics(
            label: l10n.runWeekChartSpoken(
              [
                for (var i = 0; i < daily.length && i < 7; i++)
                  '${days[i]}: ${RunLabels.km(l10n, daily[i])}',
              ].join(', '),
            ),
            child: ExcludeSemantics(
              child: Column(
                children: [
                  // Solo la zona de las barras tiene alto fijo: los días van
                  // debajo y crecen con la letra (texto al 200 %).
                  SizedBox(
                    height: TokensSize.miniChart,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: TokensSpacing.xs,
                              ),
                              height: maxDay == 0 || i >= daily.length
                                  ? TokensSpacing.xxs
                                  : math.max(
                                      TokensSpacing.xxs,
                                      TokensSize.miniChart * daily[i] / maxDay,
                                    ),
                              decoration: BoxDecoration(
                                color: i < daily.length && daily[i] > 0
                                    ? context.colors.primary
                                    : context.colors.outline,
                                borderRadius: BorderRadius.circular(
                                  TokensRadius.s,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xxs),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Text(
                            days[i],
                            textAlign: TextAlign.center,
                            style: context.textStyles.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (week.outings == 0) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.runWeekEmpty,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: context.textStyles.titleLarge),
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
