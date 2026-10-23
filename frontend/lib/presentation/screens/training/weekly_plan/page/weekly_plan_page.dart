import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/wellbeing.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_dialogs.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../bloc/weekly_plan_bloc.dart';

/// Plan semanal de entrenamiento.
class WeeklyPlanPage extends StatelessWidget {
  const WeeklyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<WeeklyPlanBloc>()..add(const WeeklyPlanEvent.started()),
      child: const _PlanView(),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<WeeklyPlanBloc, WeeklyPlanState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        final bloc = context.read<WeeklyPlanBloc>();
        final week = state.weekStart;
        return Scaffold(
          appBar: AppPageBar.reading(title: Text(l10n.trainingWeeklyPlanTitle)),
          body: week == null
              ? const AppSkeletonList(height: 96)
              : ListView(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  children: [
                    TrainingContent(
                      maxWidth: TokensLayout.readingMaxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _WeekNavigator(
                            weekStart: week,
                            isCurrent: week == state.currentWeek,
                            onChange: (d) =>
                                bloc.add(WeeklyPlanEvent.weekChanged(d)),
                          ),
                          const SizedBox(height: TokensSpacing.m),
                          switch (state.status) {
                            PlanLoadStatus.loading => const AppSkeletonGroup(
                              child: AppSkeleton(height: 320),
                            ),
                            PlanLoadStatus.failure => AppErrorView(
                              error: state.error!,
                              onRetry: () => bloc.add(
                                const WeeklyPlanEvent.weekChanged(0),
                              ),
                            ),
                            PlanLoadStatus.ready => _PlanEditor(state: state),
                          },
                          if (state.history.isNotEmpty) ...[
                            const SizedBox(height: TokensSpacing.xl),
                            AppSectionHeader(title: l10n.trainingPlanHistory),
                            for (final p in state.history) _PlanTile(plan: p),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.isCurrent,
    required this.onChange,
  });

  final DateTime weekStart;
  final bool isCurrent;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final end = weekStart.add(const Duration(days: 6));
    final format = DateFormat.MMMd('es');
    return Row(
      children: [
        IconButton(
          tooltip: l10n.trainingPreviousWeek,
          onPressed: () => onChange(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                l10n.trainingWeekRange(
                  format.format(weekStart),
                  format.format(end),
                ),
                style: context.textStyles.titleMedium,
              ),
              if (isCurrent)
                Text(
                  l10n.trainingThisWeek,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.trainingNextWeek,
          onPressed: () => onChange(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _PlanEditor extends StatelessWidget {
  const _PlanEditor({required this.state});

  final WeeklyPlanState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<WeeklyPlanBloc>();
    final input = state.input;
    final plan = state.plan;
    void update(WeeklyPlanInput i) => bloc.add(WeeklyPlanEvent.inputChanged(i));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plan != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.trainingCompliance,
                        style: context.textStyles.titleSmall,
                      ),
                    ),
                    Text(
                      l10n.trainingPercent((plan.compliance * 100).round()),
                      style: context.textStyles.titleMedium?.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensSpacing.s),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TokensRadius.pill),
                  child: LinearProgressIndicator(
                    value: plan.compliance,
                    color: context.colors.secondary,
                    backgroundColor: context.colors.secondaryContainer,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  l10n.trainingSessionsDone(
                    plan.completedSessions,
                    plan.plannedSessions,
                  ),
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          )
        else
          AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: context.colors.secondary,
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(child: Text(l10n.trainingNoPlan)),
              ],
            ),
          ),
        const SizedBox(height: TokensSpacing.m),
        AppStepperField(
          label: l10n.trainingPlannedSessions,
          value: input.plannedSessions,
          min: WeeklyPlanInput.minSessions,
          max: WeeklyPlanInput.maxSessions,
          onChanged: (v) => update(input.copyWith(plannedSessions: v)),
        ),
        AppStepperField(
          label: l10n.trainingMinutesPerSession,
          value: input.minutesPerSession,
          min: WeeklyPlanInput.minMinutes,
          max: WeeklyPlanInput.maxMinutes,
          step: 5,
          display: l10n.trainingMinutes,
          onChanged: (v) => update(input.copyWith(minutesPerSession: v)),
        ),
        const SizedBox(height: TokensSpacing.m),
        Text(l10n.trainingIntensity, style: context.textStyles.labelLarge),
        const SizedBox(height: TokensSpacing.xs),
        SegmentedButton<PlanIntensity>(
          segments: [
            for (final i in PlanIntensity.values)
              ButtonSegment(value: i, label: Text(i.label(l10n))),
          ],
          selected: {input.intensity},
          onSelectionChanged: (s) => update(input.copyWith(intensity: s.first)),
        ),
        const SizedBox(height: TokensSpacing.m),
        DropdownButtonFormField<PlanStatus>(
          key: ValueKey(input.status),
          initialValue: input.status,
          decoration: InputDecoration(labelText: l10n.trainingPlanStatus),
          items: [
            for (final s in PlanStatus.values)
              DropdownMenuItem(value: s, child: Text(s.label(l10n))),
          ],
          onChanged: (s) {
            if (s != null) update(input.copyWith(status: s));
          },
        ),
        const SizedBox(height: TokensSpacing.m),
        TextFormField(
          key: ValueKey(state.weekStart),
          initialValue: input.notes ?? '',
          maxLength: 1000,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.trainingNotes),
          onChanged: (v) => update(input.copyWith(notes: v)),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppPrimaryButton(
          label: l10n.trainingSavePlan,
          loading: state.saving,
          onPressed: () => bloc.add(const WeeklyPlanEvent.saved()),
        ),
        if (plan != null) ...[
          const SizedBox(height: TokensSpacing.s),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            onPressed: state.saving
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: l10n.trainingDeletePlanTitle,
                      message: l10n.trainingDeletePlanMessage,
                      confirmLabel: l10n.commonDelete,
                    );
                    if (ok) bloc.add(const WeeklyPlanEvent.deleted());
                  },
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.trainingDeletePlanTitle),
          ),
        ],
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox.square(
        dimension: 40,
        child: CircularProgressIndicator(
          value: plan.compliance,
          color: context.colors.secondary,
          backgroundColor: context.colors.secondaryContainer,
        ),
      ),
      title: Text(
        l10n.trainingWeekOf(DateFormat.yMMMd('es').format(plan.weekStart)),
      ),
      subtitle: Text(
        '${l10n.trainingSessionsDone(plan.completedSessions, plan.plannedSessions)}'
        ' · ${plan.intensity.label(l10n)}',
      ),
      trailing: Text(l10n.trainingPercent((plan.compliance * 100).round())),
    );
  }
}
