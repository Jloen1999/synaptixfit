import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../planner/planner_routes.dart';
import '../../../progress/widgets/achievement_share.dart';
import '../../activity_history/page/activity_history_view.dart';
import '../../training_routes.dart';
import '../../widgets/run_labels.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_section_bar.dart';
import '../../run_workout_editor/page/run_workout_editor_page.dart';
import '../bloc/run_home_bloc.dart';
import 'create_run_workout_sheet.dart';
import 'sport_grid.dart';

/// Apartado «Deportes» de la pestaña Entreno (ADR 0037, 0055 y 0068): arriba,
/// la carrera a medias o el entreno de hoy si lo hay; la rejilla de deportes
/// ([SportGrid]: elegir uno es la acción, y cada uno lleva su «apuntar uno ya
/// hecho»); dos cifras de la semana; «Próximo», los entrenos guiados y
/// «Últimas actividades». En web o escritorio explica que se graba desde el
/// móvil.
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
    final code = await showCreateRunWorkoutSheet(context, state.templates);
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
    // Un solo botón destacado, y solo si hay algo empezado o planeado: seguir
    // la carrera a medias o el entreno de hoy. Sin nada, manda la rejilla.
    final today = unfinished == null
        ? state.planned.dueToday(DateTime.now())
        : null;
    final upcoming = [
      for (final p in state.planned)
        if (p.blockId != today?.blockId) p,
    ];
    void record({String? workoutId, String? eventId}) => _RunHomeView.open(
      context,
      TrainingPaths.recordRun(workoutId: workoutId, eventId: eventId),
    );
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
              if (unfinished != null)
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
                        onPressed: record,
                      ),
                    ],
                  ),
                )
              else if (today != null)
                _TodayRunCard(
                  planned: today,
                  supported: state.supported,
                  onStart: () => record(
                    workoutId: today.workoutId,
                    eventId: today.blockId,
                  ),
                ),
              // Sin GPS (web, escritorio) se apunta a mano (ADR 0039).
              if (!state.supported) ...[
                if (unfinished != null || today != null)
                  const SizedBox(height: TokensSpacing.s),
                AppInlineMessage(
                  message: l10n.runDesktopExplain,
                  tone: AppMessageTone.info,
                ),
              ],
              if (unfinished != null || today != null || !state.supported)
                const SizedBox(height: TokensSpacing.l),
              // Elegir el deporte es la acción (ADR 0068): cada tarjeta abre
              // su pantalla, con su «apuntar uno ya hecho».
              AppSectionHeader(title: l10n.sportsGridTitle),
              const SizedBox(height: TokensSpacing.s),
              SportGrid(
                onEndurance: () => _RunHomeView.open(
                  context,
                  TrainingPaths.sportRun(gps: state.supported),
                  extra: state.templates,
                ),
                onSport: (sport) => _RunHomeView.open(
                  context,
                  sport == Sport.other
                      ? TrainingPaths.otherSport
                      : TrainingPaths.logActivity(
                          from: TrainingSection.run,
                          sport: sport,
                        ),
                ),
              ),
              if (state.pendingUploads > 0) ...[
                const SizedBox(height: TokensSpacing.s),
                AppInlineMessage(
                  message: l10n.runPendingUploads(state.pendingUploads),
                  tone: AppMessageTone.warning,
                ),
              ],
              if (state.week case final week?) ...[
                const SizedBox(height: TokensSpacing.l),
                _WeekCard(week: week),
              ],
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                _Upcoming(planned: upcoming, supported: state.supported),
              ],
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(
                title: l10n.runWorkoutsTitle,
                actionLabel: l10n.runCreateWorkout,
                onAction: () => _createWorkout(context),
              ),
              const SizedBox(height: TokensSpacing.s),
              if (state.workouts.isEmpty)
                AppEmptyState.compact(
                  icon: Icons.format_list_numbered_rounded,
                  title: l10n.runWorkoutsEmptyTitle,
                  message: l10n.runWorkoutsEmptyMessage,
                  // Sin botón propio: «Crear entreno guiado» va en la cabecera.
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
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(
                title: l10n.runLastTitle,
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
                  // Sin botón propio: se apunta desde cada deporte, arriba.
                )
              else
                for (final a in state.activities.take(_lastCount)) ...[
                  SportActivityTile(activity: a),
                  const SizedBox(height: TokensSpacing.s),
                ],
            ],
          ),
        ),
      ],
    );
  }

  /// Actividades que se ven en «Últimas» (el resto, en el historial).
  static const _lastCount = 2;
}

/// «Hoy toca» de Correr (ADR 0055): el entreno de hoy, cuánto dura y «Salir a
/// correr». Sin GPS no hay botón: se apunta a mano.
class _TodayRunCard extends StatelessWidget {
  const _TodayRunCard({
    required this.planned,
    required this.supported,
    required this.onStart,
  });

  final PlannedRun planned;
  final bool supported;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final minutes = planned.end.difference(planned.start).inMinutes;
    final time = DateFormat.Hm(l10n.localeName).format(planned.start);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppPill(
              icon: AppIcons.upNext,
              color: context.colors.primary,
              label: l10n.commonDateToday,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Semantics(
            header: true,
            child: Text(
              planned.workoutName,
              style: context.textStyles.headlineSmall,
            ),
          ),
          // «≈» no se lee bien: el lector oye «unos 30 minutos».
          Semantics(
            label: [
              time,
              if (minutes > 0) l10n.trainingEstimatedMinutesSpoken(minutes),
            ].join(', '),
            excludeSemantics: true,
            child: Text(
              [
                time,
                if (minutes > 0) l10n.trainingEstimatedMinutes(minutes),
              ].join(' · '),
              style: context.textStyles.bodyMedium,
            ),
          ),
          if (supported) ...[
            const SizedBox(height: TokensSpacing.m),
            AppPrimaryButton(
              label: l10n.runGoRun,
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }
}

/// «Próximo»: el siguiente entreno de carrera del calendario en una línea;
/// «Ver todos» despliega el resto.
class _Upcoming extends StatefulWidget {
  const _Upcoming({required this.planned, required this.supported});

  final List<PlannedRun> planned;
  final bool supported;

  @override
  State<_Upcoming> createState() => _UpcomingState();
}

class _UpcomingState extends State<_Upcoming> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final list = widget.planned;
    final shown = _all ? list : list.take(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.runNextTitle,
          actionLabel: list.length > 1
              ? (_all
                    ? l10n.trainingRecommendationsLess
                    : l10n.runSeeAllCount(list.length))
              : null,
          onAction: list.length > 1 ? () => setState(() => _all = !_all) : null,
          actionExpanded: list.length > 1 ? _all : null,
        ),
        const SizedBox(height: TokensSpacing.s),
        for (final p in shown) ...[
          _PlannedTile(planned: p, supported: widget.supported),
          const SizedBox(height: TokensSpacing.s),
        ],
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
    // «Hoy · 18:00», «Mañana · 7:30», «jue 26 · 18:00» (formato común).
    final when = AppRelativeDate.dayTime(l10n, planned.start);
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

/// «Empezar» de un entreno de la lista, con borde: el destacado es el de
/// arriba. Lleva el nombre para el lector (en la lista hay varios).
class _StartButton extends StatelessWidget {
  const _StartButton({required this.name, required this.onPressed});

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
    return OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}

/// «Esta semana»: distancia y tiempo en movimiento, con «Compartir» (imagen
/// solo con las cifras: también lleva salidas y desnivel).
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
          // Dos cifras: lo que se mira a diario. El detalle, en Progreso.
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
            ],
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
