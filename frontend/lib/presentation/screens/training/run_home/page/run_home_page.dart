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
import '../../run_workout_editor/page/run_workout_editor_page.dart';
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

  /// Tope de espera de «tirar para recargar» si el bloc no emite nada nuevo.
  static const _refreshWait = Duration(seconds: 10);

  /// Abre una pantalla y recarga al volver; devuelve lo que diga al cerrarse.
  static Future<Object?> open(
    BuildContext context,
    String location, {
    Object? extra,
  }) async {
    final bloc = context.read<RunHomeBloc>();
    final result = await context.push<Object?>(location, extra: extra);
    if (!bloc.isClosed) bloc.add(const RunHomeEvent.refreshed());
    return result;
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
          onAction: () => context.go(PlannerPaths.root),
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
              icon: const Icon(AppIcons.history),
            ),
          ],
          bottom: const TrainingSectionBar(current: TrainingSection.run),
        ),
        body: switch (state.status) {
          RunHomeStatus.loading => const AppSkeletonList(
            height: TokensSize.skeletonCard,
          ),
          RunHomeStatus.failure => AppErrorView(
            error: state.error!,
            onRetry: () =>
                context.read<RunHomeBloc>().add(const RunHomeEvent.started()),
          ),
          RunHomeStatus.ready => RefreshIndicator(
            // El indicador gira hasta que llegan los datos nuevos (con tope,
            // por si no cambia nada), no solo un instante.
            onRefresh: () async {
              final bloc = context.read<RunHomeBloc>()
                ..add(const RunHomeEvent.refreshed());
              await bloc.stream.first.timeout(
                _refreshWait,
                onTimeout: () => bloc.state,
              );
            },
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

  /// Eliminar es reversible un rato: sin confirmar, con «Deshacer» (§4). Las
  /// carreras grabadas y los eventos del calendario no se tocan.
  void _delete(BuildContext context, RunWorkout workout) {
    final bloc = context.read<RunHomeBloc>();
    final id = workout.id!;
    bloc.add(RunHomeEvent.workoutDeleted(id));
    context.showUndoSnack(
      context.localizations.runWorkoutDeleted,
      onUndo: () {
        if (!bloc.isClosed) bloc.add(RunHomeEvent.workoutDeleteUndone(id));
      },
      onCommit: () {
        if (!bloc.isClosed) bloc.add(RunHomeEvent.workoutDeleteCommitted(id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final unfinished = state.unfinished;
    // Un solo «Empezar» destacado: el de la carrera a medias, si no el del
    // entreno de hoy y, si no hay, «Empezar a correr» (vocabulario §4).
    final today = unfinished == null
        ? state.planned.dueToday(DateTime.now())
        : null;
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
              // Sin GPS (web, escritorio) no hay mapa: un mapa vacío de España
              // no dice nada. Se apunta a mano y se ve la lista (ADR 0039).
              if (state.supported) ...[
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
                // Con un entreno para hoy, su «Empezar» va arriba y es el
                // único destacado; con una carrera a medias, lo es seguirla.
                if (today != null) ...[
                  AppPrimaryButton(
                    label: l10n.runStartNamed(today.workoutName),
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _RunHomeView.open(
                      context,
                      TrainingPaths.recordRun(
                        workoutId: today.workoutId,
                        eventId: today.blockId,
                      ),
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                ],
                if (unfinished == null && today == null)
                  AppPrimaryButton(
                    label: l10n.runStart,
                    icon: Icons.directions_run_rounded,
                    onPressed: () =>
                        _RunHomeView.open(context, TrainingPaths.recordRun()),
                  )
                else
                  AppSecondaryButton(
                    label: l10n.runStart,
                    icon: const Icon(Icons.directions_run_rounded),
                    onPressed: () =>
                        _RunHomeView.open(context, TrainingPaths.recordRun()),
                  ),
                const SizedBox(height: TokensSpacing.s),
                // Un partido o una actividad sin GPS también cuenta (antes
                // estaba en Gimnasio).
                AppSecondaryButton(
                  label: l10n.trainingLogActivityButton,
                  icon: const Icon(Icons.sports_soccer_rounded),
                  onPressed: () => _RunHomeView.open(
                    context,
                    TrainingPaths.logActivity(from: TrainingSection.run),
                  ),
                ),
              ] else ...[
                // Información, no un fallo: tono neutro (antes, de aviso).
                AppInlineMessage(
                  message: l10n.runDesktopExplain,
                  tone: AppMessageTone.info,
                ),
                const SizedBox(height: TokensSpacing.s),
                AppPrimaryButton(
                  label: l10n.trainingLogActivityButton,
                  icon: Icons.edit_note_rounded,
                  onPressed: () => _RunHomeView.open(
                    context,
                    TrainingPaths.logActivity(from: TrainingSection.run),
                  ),
                ),
              ],
              const SizedBox(height: TokensSpacing.s),
              AppSecondaryButton(
                label: l10n.runCreateWorkout,
                icon: const Icon(AppIcons.add),
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
                  _PlannedTile(
                    planned: p,
                    supported: state.supported,
                    // El de hoy ya está arriba, destacado.
                    highlighted: false,
                  ),
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
                  // Sin botón propio: «Apuntar…» ya está arriba (un camino
                  // por destino).
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
                  // Sin botón propio: «Crear entreno» ya está arriba (un
                  // camino por destino).
                )
              else
                for (final w in state.workouts) ...[
                  AppSwipeToDelete(
                    itemKey: ValueKey('run-workout-${w.id}'),
                    label: l10n.runDeleteWorkout,
                    semanticLabel: l10n.runDeleteWorkoutNamed(w.name),
                    enabled: w.id != null,
                    onDelete: () => _delete(context, w),
                    child: _WorkoutTile(
                      workout: w,
                      supported: state.supported,
                      onSchedule: () => _schedule(context, w),
                      onEdit: () async {
                        final result = await _RunHomeView.open(
                          context,
                          TrainingPaths.runWorkout(w.id!),
                          extra: w,
                        );
                        if (result == RunWorkoutEditorPage.deleted &&
                            context.mounted) {
                          _delete(context, w);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                ],
              if (state.supported) ...[
                const SizedBox(height: TokensSpacing.m),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => showRunBatterySheet(
                      context,
                      onOpenSettings: () => context.read<RunHomeBloc>().add(
                        const RunHomeEvent.batterySettingsOpened(),
                      ),
                    ),
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
  const _PlannedTile({
    required this.planned,
    required this.supported,
    required this.highlighted,
  });

  final PlannedRun planned;
  final bool supported;

  /// El entreno de hoy: su «Empezar» es la acción principal de Correr.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final when = toBeginningOfSentenceCase(
      DateFormat.MMMEd(l10n.localeName).add_Hm().format(planned.start),
    );
    return AppCard(
      child: Row(
        children: [
          Icon(AppIcons.calendar, color: context.colors.secondary),
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
          if (supported) ...[
            const SizedBox(width: TokensSpacing.s),
            _StartButton(
              highlighted: highlighted,
              name: planned.workoutName,
              onPressed: () => _RunHomeView.open(
                context,
                TrainingPaths.recordRun(
                  workoutId: planned.workoutId,
                  eventId: planned.blockId,
                ),
              ),
            ),
          ],
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
  });

  final RunWorkout workout;
  final bool supported;
  final VoidCallback onSchedule;
  final VoidCallback onEdit;

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
              // Eliminar: deslizando la tarjeta, con «Deshacer» (§4).
              IconButton(
                tooltip: l10n.runEditWorkoutNamed(workout.name),
                onPressed: onEdit,
                icon: const Icon(AppIcons.edit),
              ),
              TextButton.icon(
                onPressed: onSchedule,
                icon: const Icon(AppIcons.calendar),
                label: Text(l10n.runPutInCalendar),
              ),
              if (supported)
                _StartButton(
                  highlighted: false,
                  name: workout.name,
                  onPressed: () => _RunHomeView.open(
                    context,
                    TrainingPaths.recordRun(workoutId: workout.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Empezar» de un entreno: relleno solo el que toca hoy; el resto, con borde.
/// Lleva el nombre para el lector (en la lista hay varios).
class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.highlighted,
    required this.name,
    required this.onPressed,
  });

  final bool highlighted;
  final String name;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final label = Text(
      l10n.runStartShort,
      semanticsLabel: l10n.runStartNamed(name),
    );
    const icon = Icon(Icons.play_arrow_rounded);
    return highlighted
        ? FilledButton.icon(onPressed: onPressed, icon: icon, label: label)
        : OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
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
                  icon: const Icon(AppIcons.share),
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
