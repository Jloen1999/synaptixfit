import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/run_labels.dart';
import '../bloc/run_workout_editor_bloc.dart';

/// Crear o cambiar un entreno de carrera por pasos (ADR 0037): pasos
/// «Calentar», «Correr», «Recuperar» y «Enfriar», por tiempo o por distancia,
/// y grupos que se repiten («6 × 800 m · 2 min recuperando»).
class RunWorkoutEditorPage extends StatelessWidget {
  const RunWorkoutEditorPage({
    super.key,
    this.workoutId,
    this.workout,
    this.templateCode,
  });

  final String? workoutId;
  final RunWorkout? workout;
  final String? templateCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocProvider(
      create: (_) => getIt<RunWorkoutEditorBloc>()
        ..add(
          RunWorkoutEditorEvent.started(
            workoutId: workoutId,
            workout: workout,
            templateCode: templateCode,
            defaultName: templateCode == null
                ? l10n.runWorkoutUntitled
                : RunLabels.templateName(l10n, templateCode),
          ),
        ),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> with ErrorsMessageMixin {
  final _name = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RunWorkoutEditorBloc, RunWorkoutEditorState>(
      listenWhen: (p, c) =>
          (c.saved && !p.saved) ||
          (c.actionError != null && p.actionError != c.actionError) ||
          (!c.loading && p.loading),
      listener: (context, state) {
        if (!state.loading && !_filled) {
          _filled = true;
          _name.text = state.name;
        }
        if (state.actionError case final error?) {
          context.showSnack(errorMessage(context, error));
        }
        if (state.saved) {
          context.showSnack(l10n.runWorkoutSavedWhere);
          context.pop();
        }
      },
      builder: (context, state) {
        final bloc = context.read<RunWorkoutEditorBloc>();
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(
              state.workoutId == null
                  ? l10n.runCreateWorkoutTitle
                  : l10n.runEditWorkout,
            ),
          ),
          body: switch (state) {
            RunWorkoutEditorState(loading: true) => const AppLoadingView(),
            RunWorkoutEditorState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.read<RunWorkoutEditorBloc>().add(
                RunWorkoutEditorEvent.started(
                  workoutId: state.workoutId,
                  defaultName: l10n.runWorkoutUntitled,
                ),
              ),
            ),
            _ => AppContentWidth.reading(
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  TextField(
                    controller: _name,
                    maxLength: 80,
                    decoration: InputDecoration(labelText: l10n.runWorkoutName),
                    onChanged: (v) =>
                        bloc.add(RunWorkoutEditorEvent.nameChanged(v)),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  Text(l10n.runEditorIntro),
                  const SizedBox(height: TokensSpacing.m),
                  for (var i = 0; i < state.groups.length; i++) ...[
                    _GroupCard(
                      index: i,
                      group: state.groups[i],
                      removable: state.groups.length > 1,
                    ),
                    const SizedBox(height: TokensSpacing.m),
                  ],
                  AppSecondaryButton(
                    label: l10n.runEditorAddGroup,
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () =>
                        bloc.add(const RunWorkoutEditorEvent.groupAdded()),
                  ),
                  const SizedBox(height: TokensSpacing.l),
                  AppPrimaryButton(
                    label: l10n.runEditorSave,
                    icon: Icons.check_rounded,
                    loading: state.saving,
                    onPressed: state.name.trim().isEmpty
                        ? null
                        : () => bloc.add(
                            const RunWorkoutEditorEvent.saveRequested(),
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.index,
    required this.group,
    required this.removable,
  });

  final int index;
  final RunStepGroup group;
  final bool removable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RunWorkoutEditorBloc>();
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
                    RunLabels.group(l10n, group),
                    style: context.textStyles.titleSmall,
                  ),
                ),
              ),
              if (removable)
                IconButton(
                  tooltip: l10n.runEditorRemoveGroup,
                  onPressed: () =>
                      bloc.add(RunWorkoutEditorEvent.groupRemoved(index)),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          AppStepperField(
            label: l10n.runEditorRepeat,
            value: group.repeat,
            min: 1,
            max: 30,
            display: (v) => l10n.runEditorTimes(v),
            onChanged: (v) =>
                bloc.add(RunWorkoutEditorEvent.repeatChanged(index, v)),
          ),
          const Divider(),
          for (var j = 0; j < group.steps.length; j++)
            _StepRow(
              index: index,
              step: j,
              value: group.steps[j],
              removable: group.steps.length > 1,
            ),
          if (group.steps.length < RunWorkoutEditorBloc.maxSteps)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () =>
                    bloc.add(RunWorkoutEditorEvent.stepAdded(index)),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.runEditorAddStep),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.value,
    required this.removable,
  });

  final int index;
  final int step;
  final RunStep value;
  final bool removable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RunWorkoutEditorBloc>();
    void change(RunStep s) =>
        bloc.add(RunWorkoutEditorEvent.stepChanged(index, step, s));
    final time = value.measure == RunMeasure.time;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RunStepType>(
                  initialValue: value.type,
                  decoration: InputDecoration(labelText: l10n.runEditorStep),
                  items: [
                    for (final t in RunStepType.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(RunLabels.stepType(l10n, t)),
                      ),
                  ],
                  onChanged: (t) {
                    if (t != null) change(value.copyWith(type: t));
                  },
                ),
              ),
              if (removable)
                IconButton(
                  tooltip: l10n.runEditorRemoveStep,
                  onPressed: () =>
                      bloc.add(RunWorkoutEditorEvent.stepRemoved(index, step)),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          AppAdaptiveChoice<RunMeasure>(
            label: l10n.runEditorMeasure,
            values: RunMeasure.values,
            selected: value.measure,
            labelOf: (m) => m == RunMeasure.time
                ? l10n.runEditorByTime
                : l10n.runEditorByDistance,
            iconOf: (m) => m == RunMeasure.time
                ? Icons.timer_outlined
                : Icons.straighten_rounded,
            onChanged: (m) => change(
              RunStep(
                type: value.type,
                measure: m,
                value: m == RunMeasure.time ? 300 : 1000,
              ),
            ),
          ),
          AppStepperField(
            label: time ? l10n.runEditorDuration : l10n.runEditorDistance,
            value: value.value,
            min: time ? 30 : 100,
            max: time ? 10800 : 50000,
            step: time ? 30 : 100,
            display: (v) => RunLabels.amount(l10n, value.copyWith(value: v)),
            onChanged: (v) => change(value.copyWith(value: v)),
          ),
        ],
      ),
    );
  }
}
