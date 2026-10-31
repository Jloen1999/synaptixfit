import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_parameters_sheet.dart';
import '../../widgets/exercise_row.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_dialogs.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../widgets/week_selector.dart';
import '../bloc/routine_detail_bloc.dart';
import 'routine_details_sheet.dart';

/// Detalle de una rutina (propia: editable; ajena: solo clonar).
class RoutineDetailPage extends StatelessWidget {
  const RoutineDetailPage({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RoutineDetailBloc>()
            ..add(RoutineDetailEvent.started(routineId)),
      child: const _DetailView(),
    );
  }
}

enum _MenuAction { edit, duplicate, delete, status }

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  int _week = 0;

  RoutineDetailBloc get _bloc => context.read<RoutineDetailBloc>();

  Future<void> _onMenu(Routine routine, _MenuAction action) async {
    final l10n = context.localizations;
    switch (action) {
      case _MenuAction.edit:
        final change = await showRoutineDetailsSheet(context, routine);
        if (change == null || !mounted) return;
        _bloc.add(
          RoutineDetailEvent.detailsUpdated(
            name: change.name,
            description: change.description,
            visibility: change.visibility,
            goal: change.goal,
          ),
        );
      case _MenuAction.duplicate:
        final name = await showTextPromptDialog(
          context,
          title: l10n.trainingDuplicate,
          label: l10n.trainingRoutineName,
          initial: l10n.trainingCopyOf(routine.name),
        );
        if (name != null && mounted) {
          _bloc.add(RoutineDetailEvent.duplicated(name: name));
        }
      case _MenuAction.delete:
        final ok = await showConfirmDialog(
          context,
          title: l10n.trainingDeleteRoutineTitle,
          message: l10n.trainingDeleteRoutineMessage(routine.name),
          confirmLabel: l10n.commonDelete,
        );
        if (ok && mounted) _bloc.add(const RoutineDetailEvent.deleted());
      case _MenuAction.status:
        final status = await showModalBottomSheet<RoutineStatus>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in RoutineStatus.values)
                  AppFocusOutline(
                    child: ListTile(
                      leading: Icon(s.icon),
                      title: Text(s.label(l10n)),
                      trailing: s == routine.status
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.of(context).pop(s),
                    ),
                  ),
              ],
            ),
          ),
        );
        if (status != null && status != routine.status && mounted) {
          _bloc.add(RoutineDetailEvent.statusChanged(status));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RoutineDetailBloc, RoutineDetailState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        final routine = state.routine;
        if (routine != null && _week >= routine.weeks.length) {
          _week = routine.weeks.isEmpty ? 0 : routine.weeks.length - 1;
        }
        return Scaffold(
          appBar: AppPageBar(
            title: Text(routine?.name ?? l10n.trainingRoutineTitle),
            actions: [
              if (routine != null && routine.owned)
                PopupMenuButton<_MenuAction>(
                  tooltip: l10n.trainingMoreActions,
                  enabled: !state.busy,
                  onSelected: (a) => _onMenu(routine, a),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _MenuAction.edit,
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(l10n.trainingEditDetails),
                      ),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.status,
                      child: ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(l10n.trainingChangeStatus),
                      ),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.duplicate,
                      child: ListTile(
                        leading: const Icon(Icons.copy_rounded),
                        title: Text(l10n.trainingDuplicate),
                      ),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.delete,
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: context.colors.error,
                        ),
                        title: Text(l10n.commonDelete),
                      ),
                    ),
                  ],
                ),
            ],
            bottom: state.busy
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          floatingActionButton: routine != null && !routine.owned
              ? FloatingActionButton.extended(
                  onPressed: state.busy
                      ? null
                      : () => _bloc.add(const RoutineDetailEvent.cloned()),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(l10n.trainingClone),
                )
              : null,
          body: switch (state.status) {
            RoutineDetailStatus.loading => const AppSkeletonList(height: 140),
            RoutineDetailStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () =>
                  _bloc.add(RoutineDetailEvent.started(state.routineId ?? '')),
            ),
            RoutineDetailStatus.ready => RefreshIndicator(
              onRefresh: () async =>
                  _bloc.add(const RoutineDetailEvent.refreshed()),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.s,
                  TokensSpacing.m,
                  TokensSpacing.xxl * 2,
                ),
                children: [
                  TrainingContent(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(routine: routine!),
                        const SizedBox(height: TokensSpacing.l),
                        if (routine.weeks.isNotEmpty) ...[
                          WeekSelector(
                            count: routine.weeks.length,
                            selected: _week,
                            completed: {
                              for (var i = 0; i < routine.weeks.length; i++)
                                if (routine.weeks[i].status ==
                                    ProgressStatus.completed)
                                  i,
                            },
                            onSelected: (i) => setState(() => _week = i),
                            onAdd: routine.owned && !state.busy
                                ? () {
                                    _bloc.add(
                                      const RoutineDetailEvent.weekAdded(),
                                    );
                                    setState(
                                      () => _week = routine.weeks.length,
                                    );
                                  }
                                : null,
                          ),
                          const SizedBox(height: TokensSpacing.s),
                          _WeekSection(
                            week: routine.weeks[_week],
                            routine: routine,
                            bodyWeightKg: state.bodyWeightKg,
                            busy: state.busy,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final r = routine;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!r.owned && r.authorName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: Row(
                children: [
                  AppAvatar(name: r.authorName!, radius: 14),
                  const SizedBox(width: TokensSpacing.s),
                  Text(
                    l10n.trainingByAuthor(r.authorName!),
                    style: context.textStyles.labelLarge,
                  ),
                ],
              ),
            ),
          if (r.description != null && r.description!.trim().isNotEmpty) ...[
            Text(r.description!, style: context.textStyles.bodyMedium),
            const SizedBox(height: TokensSpacing.s),
          ],
          if (r.origin?.ownerName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: Text(
                l10n.trainingClonedFrom(r.origin!.ownerName!),
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: r.status.icon,
                label: r.status.label(l10n),
                color: context.colors.secondary,
              ),
              AppPill(icon: r.visibility.icon, label: r.visibility.label(l10n)),
              if (r.goal != null)
                AppPill(icon: Icons.flag_outlined, label: r.goal!.label(l10n)),
              AppPill(
                icon: Icons.calendar_view_week_rounded,
                label: l10n.trainingWeeksCount(r.weeks.length),
              ),
              AppPill(
                icon: Icons.fitness_center_rounded,
                label: l10n.trainingExercisesCount(r.exerciseCount),
              ),
              if (r.startDate != null)
                AppPill(
                  icon: Icons.event_rounded,
                  label: l10n.trainingStartsOn(
                    DateFormat.yMMMd().format(r.startDate!),
                  ),
                ),
            ],
          ),
          if (r.owned && r.totalDays > 0) ...[
            const SizedBox(height: TokensSpacing.m),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TokensRadius.pill),
                    child: LinearProgressIndicator(
                      value: r.progress,
                      color: context.colors.secondary,
                      backgroundColor: context.colors.secondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: TokensSpacing.s),
                Text(
                  l10n.trainingDaysProgress(r.completedDays, r.totalDays),
                  style: context.textStyles.labelLarge,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection({
    required this.week,
    required this.routine,
    required this.bodyWeightKg,
    required this.busy,
  });

  final RoutineWeek week;
  final Routine routine;
  final double? bodyWeightKg;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RoutineDetailBloc>();
    final owned = routine.owned;

    Future<void> renameWeek() async {
      final name = await showTextPromptDialog(
        context,
        title: l10n.trainingRenameWeek,
        label: l10n.trainingName,
        initial: weekTitle(l10n, week.number, week.name),
      );
      if (name != null) bloc.add(RoutineDetailEvent.weekRenamed(week.id, name));
    }

    Future<void> deleteWeek() async {
      final ok = await showConfirmDialog(
        context,
        title: l10n.trainingDeleteWeekTitle,
        message: l10n.trainingDeleteWeekMessage,
        confirmLabel: l10n.commonDelete,
      );
      if (ok) bloc.add(RoutineDetailEvent.weekDeleted(week.id));
    }

    Future<void> addDay() async {
      final day = await showWeekdayPicker(
        context,
        taken: week.days.map((d) => d.dayNumber).toSet(),
      );
      if (day != null) bloc.add(RoutineDetailEvent.dayAdded(week.id, day));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekTitle(l10n, week.number, week.name),
                    style: context.textStyles.titleMedium,
                  ),
                  Text(
                    [
                      if (week.type != null) week.type!.label(l10n),
                      week.status.label(l10n),
                    ].join(' · '),
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (owned) ...[
              IconButton(
                tooltip: l10n.trainingRenameWeek,
                onPressed: busy ? null : renameWeek,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: l10n.trainingDeleteWeekTitle,
                onPressed: busy || routine.weeks.length <= 1
                    ? null
                    : deleteWeek,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        if (week.days.isEmpty)
          AppEmptyState(
            icon: Icons.event_busy_rounded,
            title: l10n.trainingWeekNoDays,
          ),
        for (final day in week.days)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.s),
            child: _DayCard(
              key: ValueKey(day.id),
              day: day,
              isNext: day.id == _nextDayId(routine),
              routine: routine,
              bodyWeightKg: bodyWeightKg,
              busy: busy,
            ),
          ),
        if (owned && week.days.length < 7)
          AppSecondaryButton(
            label: l10n.trainingAddDay,
            icon: const Icon(Icons.add_rounded),
            onPressed: busy ? null : addDay,
          ),
      ],
    );
  }
}

/// Primer día sin terminar de la rutina, en orden: el que toca entrenar.
String? _nextDayId(Routine routine) {
  for (final week in routine.weeks) {
    for (final day in week.days) {
      if (day.status != ProgressStatus.completed && day.exercises.isNotEmpty) {
        return day.id;
      }
    }
  }
  return null;
}

/// Día de la rutina. Los ya hechos aparecen plegados (cabecera y resumen)
/// para que se vea a la primera lo que queda; se despliegan con un toque.
class _DayCard extends StatefulWidget {
  const _DayCard({
    super.key,
    required this.day,
    required this.isNext,
    required this.routine,
    required this.bodyWeightKg,
    required this.busy,
  });

  final RoutineDay day;

  /// Es el siguiente día que toca entrenar.
  final bool isNext;
  final Routine routine;
  final double? bodyWeightKg;
  final bool busy;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  late bool _expanded = widget.day.status != ProgressStatus.completed;

  @override
  void didUpdateWidget(_DayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al terminarse el día se pliega solo; si se reabre, se despliega.
    if (oldWidget.day.status != widget.day.status) {
      _expanded = widget.day.status != ProgressStatus.completed;
    }
  }

  RoutineDay get day => widget.day;
  Routine get routine => widget.routine;
  double? get bodyWeightKg => widget.bodyWeightKg;
  bool get busy => widget.busy;

  /// Repetir un día hecho cuenta como una sesión nueva: se confirma antes.
  Future<void> _train(BuildContext context) async {
    final bloc = context.read<RoutineDetailBloc>();
    if (day.status == ProgressStatus.completed) {
      final l10n = context.localizations;
      final ok = await showConfirmDialog(
        context,
        title: l10n.trainingRepeatDayTitle,
        message: l10n.trainingRepeatDayMessage,
        confirmLabel: l10n.trainingRepeatDay,
      );
      if (!ok) return;
    }
    bloc.add(RoutineDetailEvent.sessionStarted(day.id));
  }

  Widget _trainButton(BuildContext context) {
    final l10n = context.localizations;
    final onPressed = busy ? null : () => _train(context);
    return switch (day.status) {
      ProgressStatus.completed => OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.replay_rounded),
        label: Text(l10n.trainingRepeatDay),
      ),
      ProgressStatus.inProgress => FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.trainingContinueDay),
      ),
      ProgressStatus.pending => FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.trainingTrain),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RoutineDetailBloc>();
    final owned = routine.owned;
    final kcal = day.exercises.fold<double>(
      0,
      (sum, e) =>
          sum +
          e.parameters.estimatedCalories(
            met: e.met,
            bodyWeightKg: bodyWeightKg,
          ),
    );

    Future<void> rename() async {
      final name = await showTextPromptDialog(
        context,
        title: l10n.trainingRenameDay,
        label: l10n.trainingName,
        initial: dayTitle(l10n, day.dayNumber, day.name),
      );
      if (name != null) bloc.add(RoutineDetailEvent.dayRenamed(day.id, name));
    }

    Future<void> delete() async {
      final ok = await showConfirmDialog(
        context,
        title: l10n.trainingDeleteDay,
        message: l10n.trainingDeleteDayMessage,
        confirmLabel: l10n.commonDelete,
      );
      if (ok) bloc.add(RoutineDetailEvent.dayDeleted(day.id));
    }

    Future<void> addExercise() async {
      final exercise = await context.push<Exercise>(
        TrainingPaths.exercisePicker,
      );
      if (exercise != null) {
        bloc.add(RoutineDetailEvent.exerciseAdded(day.id, exercise));
      }
    }

    Future<void> edit(PlannedExercise e) async {
      final params = await showExerciseParametersSheet(
        context,
        title: e.exerciseName,
        initial: e.parameters,
      );
      if (params != null) {
        bloc.add(RoutineDetailEvent.exerciseUpdated(e.id, params));
      }
    }

    Future<void> remove(PlannedExercise e) async {
      final ok = await showConfirmDialog(
        context,
        title: l10n.trainingRemoveExercise,
        message: l10n.trainingRemoveExerciseMessage(e.exerciseName),
        confirmLabel: l10n.commonDelete,
      );
      if (ok) bloc.add(RoutineDetailEvent.exerciseRemoved(e.id));
    }

    // Solo la zona del título pliega/despliega; renombrar y borrar van al
    // lado, fuera de ella (sin controles anidados).
    final toggle = AppFocusOutline(
      child: Semantics(
        button: true,
        expanded: _expanded,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          onTap: () => setState(() => _expanded = !_expanded),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: Row(
              children: [
                Icon(
                  day.status.icon,
                  size: TokensSize.iconS,
                  color: day.status == ProgressStatus.completed
                      ? context.palette.success
                      : context.colors.onSurfaceVariant,
                  semanticLabel: day.status.label(l10n),
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayTitle(l10n, day.dayNumber, day.name),
                        style: context.textStyles.titleSmall,
                      ),
                      Text(
                        [
                          weekdayName(l10n, day.dayNumber),
                          if (day.status != ProgressStatus.pending)
                            day.status.label(l10n),
                        ].join(' · '),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      // Debajo del título: con texto grande no le quita sitio.
                      if (widget.isNext)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: TokensSpacing.xxs,
                          ),
                          child: AppPill(
                            icon: Icons.flag_rounded,
                            label: l10n.trainingNextDay,
                            color: context.colors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: context.motion(TokensDuration.normal),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final header = Row(
      children: [
        Expanded(child: toggle),
        if (owned && _expanded) ...[
          IconButton(
            tooltip: l10n.trainingRenameDay,
            onPressed: busy ? null : rename,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: l10n.trainingDeleteDay,
            onPressed: busy ? null : delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ],
    );
    return AppCard(
      child: AnimatedSize(
        duration: context.motion(TokensDuration.normal),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (day.exercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xs),
                child: Wrap(
                  spacing: TokensSpacing.xs,
                  children: [
                    AppPill(
                      icon: Icons.fitness_center_rounded,
                      label: l10n.trainingExercisesCount(day.exercises.length),
                    ),
                    AppPill(
                      icon: Icons.local_fire_department_rounded,
                      color: context.palette.calories,
                      label: l10n.trainingChipKcal(kcal.round()),
                    ),
                  ],
                ),
              ),
            if (_expanded && day.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
                child: Text(
                  l10n.trainingDayNoExercises,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            if (_expanded)
              for (var i = 0; i < day.exercises.length; i++)
                ExerciseRow(
                  key: ValueKey(day.exercises[i].id),
                  position: i + 1,
                  count: day.exercises.length,
                  name: day.exercises[i].exerciseName,
                  thumbnailUrl: day.exercises[i].thumbnailUrl,
                  parameters: day.exercises[i].parameters,
                  met: day.exercises[i].met,
                  bodyWeightKg: bodyWeightKg,
                  realDurationSeconds: day.exercises[i].realDurationSeconds,
                  inactive: !day.exercises[i].exerciseActive,
                  onTap: () => context.push(
                    TrainingPaths.exercise(day.exercises[i].exerciseId),
                  ),
                  onMoveUp: !owned || busy || i == 0
                      ? null
                      : () => bloc.add(
                          RoutineDetailEvent.exerciseMoved(
                            day.id,
                            day.exercises[i].id,
                            up: true,
                          ),
                        ),
                  onMoveDown: !owned || busy || i == day.exercises.length - 1
                      ? null
                      : () => bloc.add(
                          RoutineDetailEvent.exerciseMoved(
                            day.id,
                            day.exercises[i].id,
                            up: false,
                          ),
                        ),
                  onEdit: !owned || busy ? null : () => edit(day.exercises[i]),
                  onRemove: !owned || busy
                      ? null
                      : () => remove(day.exercises[i]),
                ),
            if (owned && _expanded) ...[
              const SizedBox(height: TokensSpacing.xs),
              // Con texto grande, la acción principal baja a otra fila.
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: TokensSpacing.xs,
                children: [
                  TextButton.icon(
                    onPressed: busy ? null : addExercise,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.trainingAddExercise),
                  ),
                  if (day.exercises.isNotEmpty) _trainButton(context),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
