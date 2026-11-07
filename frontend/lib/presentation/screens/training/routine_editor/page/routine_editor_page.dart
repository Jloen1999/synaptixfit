import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/enums/visibility.dart' as vis;
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/routine_draft.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../exercise_alternatives/page/exercise_alternatives_sheet.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_parameters_sheet.dart';
import '../../widgets/exercise_row.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_dialogs.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../widgets/week_selector.dart';
import '../bloc/routine_editor_bloc.dart';

/// Nueva rutina: con IA en pasos o manual desde cero.
class RoutineEditorPage extends StatelessWidget {
  const RoutineEditorPage({super.key, required this.manual});

  final bool manual;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RoutineEditorBloc>()
            ..add(RoutineEditorEvent.started(manual: manual)),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView();

  Future<void> _close(BuildContext context, RoutineEditorState state) async {
    final l10n = context.localizations;
    final dirty = state.step == EditorStep.editing;
    if (dirty) {
      final ok = await showConfirmDialog(
        context,
        title: l10n.trainingDiscardRoutineTitle,
        message: l10n.trainingDiscardRoutineMessage,
        confirmLabel: l10n.trainingDiscard,
      );
      if (!ok || !context.mounted) return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RoutineEditorBloc, RoutineEditorState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        return PopScope(
          canPop: state.step != EditorStep.editing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close(context, state);
          },
          child: Scaffold(
            appBar: AppPageBar.reading(
              leading: IconButton(
                tooltip: l10n.commonClose,
                icon: const Icon(AppIcons.close),
                onPressed: () => _close(context, state),
              ),
              title: Text(
                state.aiMode
                    ? l10n.trainingNewRoutineAi
                    : l10n.trainingNewRoutineManual,
              ),
              bottom: state.aiMode
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(44),
                      child: _StepIndicator(step: state.step),
                    )
                  : null,
            ),
            body: switch (state.step) {
              EditorStep.parameters => _ParametersStep(state: state),
              EditorStep.generating => _GeneratingStep(),
              EditorStep.editing => _EditingStep(state: state),
            },
            bottomNavigationBar: state.step == EditorStep.editing
                ? _EditorBottomBar(state: state)
                : null,
          ),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final EditorStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final current = switch (step) {
      EditorStep.parameters => 0,
      EditorStep.generating => 1,
      EditorStep.editing => 2,
    };
    final labels = [
      l10n.trainingStepParameters,
      l10n.trainingStepProposal,
      l10n.trainingStepEdit,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.s,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Divider(
                  color: i <= current
                      ? context.colors.secondary
                      : context.colors.outlineVariant,
                  thickness: 2,
                ),
              ),
            Semantics(
              label: l10n.trainingStepSemantics(
                i + 1,
                labels.length,
                labels[i],
              ),
              selected: i == current,
              excludeSemantics: true,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: TokensSize.iconM / 2,
                    backgroundColor: i <= current
                        ? context.colors.secondary
                        : context.colors.surfaceContainerHigh,
                    child: i < current
                        ? Icon(
                            Icons.check_rounded,
                            size: TokensSize.iconXs,
                            color: context.colors.onSecondary,
                          )
                        : Text(
                            '${i + 1}',
                            style: context.textStyles.labelSmall?.copyWith(
                              color: i <= current
                                  ? context.colors.onSecondary
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Text(labels[i], style: context.textStyles.labelMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParametersStep extends StatelessWidget {
  const _ParametersStep({required this.state});

  final RoutineEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RoutineEditorBloc>();
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        TrainingContent(
          maxWidth: TokensLayout.readingMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                color: context.colors.tertiaryContainer,
                child: Row(
                  children: [
                    Icon(
                      AppIcons.proposal,
                      color: context.colors.onTertiaryContainer,
                    ),
                    const SizedBox(width: TokensSpacing.m),
                    Expanded(
                      child: Text(
                        l10n.trainingAiIntro,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingDurationTitle),
              AppStepperField(
                label: l10n.trainingDurationWeeks,
                value: state.weeksParam,
                min: 1,
                max: RoutineDraft.maxWeeks,
                display: l10n.trainingWeeksCount,
                onChanged: (v) =>
                    bloc.add(RoutineEditorEvent.weeksParamChanged(v)),
              ),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingGoalOptional),
              // Cada objetivo con una línea que lo explica: quien empieza no
              // sabe qué es «Potencia» o «Fuerza resistencia».
              _GoalOption(
                title: l10n.trainingGoalFromProfile,
                description: l10n.trainingGoalFromProfileHint,
                selected: state.goalParam == null,
                onTap: () =>
                    bloc.add(const RoutineEditorEvent.goalParamChanged(null)),
              ),
              for (final goal in TrainingGoal.values)
                _GoalOption(
                  title: goal.label(l10n),
                  description: goal.description(l10n),
                  selected: state.goalParam == goal,
                  onTap: () =>
                      bloc.add(RoutineEditorEvent.goalParamChanged(goal)),
                ),
              const SizedBox(height: TokensSpacing.xl),
              AppPrimaryButton(
                label: l10n.trainingGenerate,
                icon: AppIcons.proposal,
                onPressed: () =>
                    bloc.add(const RoutineEditorEvent.generateRequested()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Objetivo elegible para la rutina con IA: nombre y una línea que lo explica.
/// Se anuncia como opción de un grupo (solo una puede estar elegida).
class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppFocusOutline(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected
                ? context.colors.primary
                : context.colors.onSurfaceVariant,
          ),
          title: Text(title),
          subtitle: Text(description),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _GeneratingStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: TokensSpacing.l),
            Text(
              l10n.trainingGenerating,
              style: context.textStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.trainingGeneratingHint,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditingStep extends StatefulWidget {
  const _EditingStep({required this.state});

  final RoutineEditorState state;

  @override
  State<_EditingStep> createState() => _EditingStepState();
}

class _EditingStepState extends State<_EditingStep> {
  late final _name = TextEditingController(text: widget.state.draft.name);
  late final _description = TextEditingController(
    text: widget.state.draft.description ?? '',
  );
  int _week = 0;

  @override
  void didUpdateWidget(covariant _EditingStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La IA puede cambiar el nombre o la descripción al refinar.
    final draft = widget.state.draft;
    if (draft.name != _name.text) _name.text = draft.name;
    if ((draft.description ?? '') != _description.text) {
      _description.text = draft.description ?? '';
    }
    if (_week >= draft.weeks.length) _week = draft.weeks.length - 1;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  RoutineEditorBloc get _bloc => context.read<RoutineEditorBloc>();

  Future<void> _addExercise(int dayIndex) async {
    final exercise = await context.push<Exercise>(TrainingPaths.exercisePicker);
    if (exercise != null && mounted) {
      _bloc.add(RoutineEditorEvent.exerciseAdded(_week, dayIndex, exercise));
    }
  }

  Future<void> _addDay(DraftWeek week) async {
    final day = await showWeekdayPicker(
      context,
      taken: week.days.map((d) => d.dayNumber).toSet(),
    );
    if (day != null && mounted) {
      _bloc.add(RoutineEditorEvent.dayAdded(_week, day));
    }
  }

  Future<void> _renameWeek(DraftWeek week) async {
    final l10n = context.localizations;
    final name = await showTextPromptDialog(
      context,
      title: l10n.trainingRenameWeek,
      label: l10n.trainingName,
      initial: week.name ?? weekTitle(l10n, _week + 1, null),
    );
    if (name != null && mounted) {
      _bloc.add(RoutineEditorEvent.weekRenamed(_week, name));
    }
  }

  Future<void> _renameDay(int dayIndex, DraftDay day) async {
    final l10n = context.localizations;
    final name = await showTextPromptDialog(
      context,
      title: l10n.trainingRenameDay,
      label: l10n.trainingName,
      initial: dayTitle(l10n, day.dayNumber, day.name),
    );
    if (name != null && mounted) {
      _bloc.add(RoutineEditorEvent.dayRenamed(_week, dayIndex, name));
    }
  }

  Future<void> _removeWeek() async {
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.trainingDeleteWeekTitle,
      message: l10n.trainingDeleteWeekMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (ok && mounted) _bloc.add(RoutineEditorEvent.weekRemoved(_week));
  }

  Future<void> _editParameters(int dayIndex, int index, DraftExercise e) async {
    final params = await showExerciseParametersSheet(
      context,
      title: e.exerciseName,
      initial: e.parameters,
    );
    if (params != null && mounted) {
      _bloc.add(
        RoutineEditorEvent.exerciseParametersChanged(
          _week,
          dayIndex,
          index,
          params,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final state = widget.state;
    final draft = state.draft;
    final week = draft.weeks.isEmpty ? null : draft.weeks[_week];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.m,
        TokensSpacing.m,
        TokensSpacing.xl,
      ),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.proposal != null) _ProposalBanner(state: state),
              AppSectionHeader(title: l10n.trainingGeneralData),
              TextField(
                controller: _name,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: l10n.trainingRoutineName,
                  errorText: state.showValidation && !state.nameValid
                      ? l10n.trainingRoutineNameTooShort
                      : null,
                ),
                onChanged: (v) => _bloc.add(RoutineEditorEvent.nameChanged(v)),
              ),
              const SizedBox(height: TokensSpacing.s),
              TextField(
                controller: _description,
                maxLength: 2000,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.trainingRoutineDescription,
                ),
                onChanged: (v) =>
                    _bloc.add(RoutineEditorEvent.descriptionChanged(v)),
              ),
              const SizedBox(height: TokensSpacing.s),
              DropdownButtonFormField<TrainingGoal?>(
                key: ValueKey(draft.goal),
                initialValue: draft.goal,
                decoration: InputDecoration(
                  labelText: l10n.trainingGoal,
                  // Qué significa el objetivo elegido, sin jerga.
                  helperText: draft.goal?.description(l10n),
                  helperMaxLines: 3,
                ),
                items: [
                  DropdownMenuItem(child: Text(l10n.trainingGoalNone)),
                  for (final goal in TrainingGoal.values)
                    DropdownMenuItem(
                      value: goal,
                      child: Text(goal.label(l10n)),
                    ),
                ],
                onChanged: (v) => _bloc.add(RoutineEditorEvent.goalChanged(v)),
              ),
              const SizedBox(height: TokensSpacing.m),
              // Con el texto grande pasa a lista: ninguna opción se corta.
              AppAdaptiveChoice<vis.Visibility>(
                label: l10n.trainingVisibility,
                values: vis.Visibility.values,
                selected: draft.visibility,
                labelOf: (v) => v.label(l10n),
                iconOf: (v) => v.icon,
                onChanged: (v) =>
                    _bloc.add(RoutineEditorEvent.visibilityChanged(v)),
              ),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingStructure),
              WeekSelector(
                count: draft.weeks.length,
                selected: _week,
                onSelected: (i) => setState(() => _week = i),
                onAdd: draft.weeks.length >= RoutineDraft.maxWeeks
                    ? null
                    : () {
                        _bloc.add(const RoutineEditorEvent.weekAdded());
                        setState(() => _week = draft.weeks.length);
                      },
              ),
              const SizedBox(height: TokensSpacing.s),
              if (week != null)
                _WeekEditor(
                  weekIndex: _week,
                  week: week,
                  canRemove: draft.weeks.length > 1,
                  onRename: () => _renameWeek(week),
                  onRemove: _removeWeek,
                  onAddDay: week.days.length >= 7 ? null : () => _addDay(week),
                  onRenameDay: _renameDay,
                  onRemoveDay: (dayIndex) =>
                      _bloc.add(RoutineEditorEvent.dayRemoved(_week, dayIndex)),
                  onAddExercise: _addExercise,
                  onEditExercise: _editParameters,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProposalBanner extends StatelessWidget {
  const _ProposalBanner({required this.state});

  final RoutineEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final proposal = state.proposal!;
    // Se diga igual venga de donde venga la propuesta: a la persona le sirve
    // en qué datos se basa, no cómo se calculó (vocabulario, «Propuestas…»).
    final background = context.colors.tertiaryContainer;
    final foreground = context.colors.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: AppCard(
        color: background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.proposal, color: foreground),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    l10n.trainingRulesEngine,
                    style: context.textStyles.titleSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            if (proposal.adjustmentReasons.isNotEmpty) ...[
              const SizedBox(height: TokensSpacing.s),
              Text(
                l10n.trainingAdjustmentReasons,
                style: context.textStyles.labelLarge?.copyWith(
                  color: foreground,
                ),
              ),
              for (final reason in proposal.adjustmentReasons)
                Padding(
                  padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chevron_right_rounded,
                        size: TokensSize.iconS,
                        color: foreground,
                      ),
                      Expanded(
                        child: Text(
                          reason,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekEditor extends StatelessWidget {
  const _WeekEditor({
    required this.weekIndex,
    required this.week,
    required this.canRemove,
    required this.onRename,
    required this.onRemove,
    required this.onAddDay,
    required this.onRenameDay,
    required this.onRemoveDay,
    required this.onAddExercise,
    required this.onEditExercise,
  });

  final int weekIndex;
  final DraftWeek week;
  final bool canRemove;
  final VoidCallback onRename;
  final VoidCallback onRemove;
  final VoidCallback? onAddDay;
  final void Function(int dayIndex, DraftDay day) onRenameDay;
  final ValueChanged<int> onRemoveDay;
  final ValueChanged<int> onAddExercise;
  final void Function(int dayIndex, int index, DraftExercise e) onEditExercise;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RoutineEditorBloc>();
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
                    weekTitle(l10n, weekIndex + 1, week.name),
                    style: context.textStyles.titleMedium,
                  ),
                  if (week.type != null) ...[
                    Text(
                      week.type!.label(l10n),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      week.type!.description(l10n),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.trainingRenameWeek,
              onPressed: onRename,
              icon: const Icon(AppIcons.edit),
            ),
            IconButton(
              tooltip: l10n.trainingDeleteWeekTitle,
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(AppIcons.delete),
            ),
          ],
        ),
        if (week.days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: TokensSpacing.m),
            child: Text(
              l10n.trainingWeekNoDays,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        for (var d = 0; d < week.days.length; d++)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.s),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayTitle(
                                l10n,
                                week.days[d].dayNumber,
                                week.days[d].name,
                              ),
                              style: context.textStyles.titleSmall,
                            ),
                            Text(
                              weekdayName(l10n, week.days[d].dayNumber),
                              style: context.textStyles.labelSmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.trainingRenameDay,
                        onPressed: () => onRenameDay(d, week.days[d]),
                        icon: const Icon(AppIcons.edit),
                      ),
                      IconButton(
                        tooltip: l10n.trainingDeleteDay,
                        onPressed: () => onRemoveDay(d),
                        icon: const Icon(AppIcons.delete),
                      ),
                    ],
                  ),
                  if (week.days[d].exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: TokensSpacing.s,
                      ),
                      child: Text(
                        l10n.trainingDayNoExercises,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (var i = 0; i < week.days[d].exercises.length; i++)
                    ExerciseRow(
                      // Identidad del borrador (se conserva al moverlo).
                      key: ObjectKey(week.days[d].exercises[i]),
                      position: i + 1,
                      count: week.days[d].exercises.length,
                      name: week.days[d].exercises[i].exerciseName,
                      thumbnailUrl: week.days[d].exercises[i].thumbnailUrl,
                      parameters: week.days[d].exercises[i].parameters,
                      met: week.days[d].exercises[i].met,
                      onMoveUp: i == 0
                          ? null
                          : () => bloc.add(
                              RoutineEditorEvent.exerciseMoved(
                                weekIndex,
                                d,
                                i,
                                up: true,
                              ),
                            ),
                      onMoveDown: i == week.days[d].exercises.length - 1
                          ? null
                          : () => bloc.add(
                              RoutineEditorEvent.exerciseMoved(
                                weekIndex,
                                d,
                                i,
                                up: false,
                              ),
                            ),
                      onEdit: () =>
                          onEditExercise(d, i, week.days[d].exercises[i]),
                      onReplace: () => _replace(
                        context,
                        weekIndex,
                        d,
                        i,
                        week.days[d].exercises[i],
                      ),
                      onRemove: () => bloc.add(
                        RoutineEditorEvent.exerciseRemoved(weekIndex, d, i),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          week.days[d].exercises.length >=
                              RoutineDraft.maxExercisesPerDay
                          ? null
                          : () => onAddExercise(d),
                      icon: const Icon(AppIcons.add),
                      label: Text(l10n.trainingAddExercise),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AppSecondaryButton(
          label: l10n.trainingAddDay,
          icon: const Icon(AppIcons.add),
          onPressed: onAddDay,
        ),
      ],
    );
  }
}

/// Abre las alternativas de un ejercicio y, si se elige una, la pone en su lugar.
Future<void> _replace(
  BuildContext context,
  int weekIndex,
  int dayIndex,
  int exerciseIndex,
  DraftExercise current,
) async {
  final bloc = context.read<RoutineEditorBloc>();
  final chosen = await showExerciseAlternativesSheet(
    context,
    exerciseId: current.exerciseId,
    exerciseName: current.exerciseName,
  );
  if (chosen != null) {
    bloc.add(
      RoutineEditorEvent.exerciseReplaced(
        weekIndex,
        dayIndex,
        exerciseIndex,
        chosen,
      ),
    );
  }
}

class _EditorBottomBar extends StatelessWidget {
  const _EditorBottomBar({required this.state});

  final RoutineEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RoutineEditorBloc>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TokensSpacing.m),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.busy || state.draft.exerciseCount == 0
                    ? null
                    : () =>
                          bloc.add(const RoutineEditorEvent.refineRequested()),
                icon: state.refining
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(AppIcons.proposal),
                label: Text(l10n.trainingRefineAi),
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: AppPrimaryButton(
                label: l10n.trainingSaveRoutine,
                loading: state.saving,
                onPressed: state.busy
                    ? null
                    : () => bloc.add(const RoutineEditorEvent.saveRequested()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
