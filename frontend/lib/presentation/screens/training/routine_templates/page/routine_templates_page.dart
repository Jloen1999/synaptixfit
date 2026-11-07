import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/routine_template.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_effect.dart';
import '../../training_routes.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../bloc/routine_templates_bloc.dart';

/// Plantillas de rutina listas para usar: se filtran por días, casa o
/// exámenes y una se convierte en rutina propia con un toque.
class RoutineTemplatesPage extends StatelessWidget {
  const RoutineTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RoutineTemplatesBloc>()
            ..add(const RoutineTemplatesEvent.started()),
      child: const _TemplatesView(),
    );
  }
}

class _TemplatesView extends StatelessWidget {
  const _TemplatesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RoutineTemplatesBloc, RoutineTemplatesState>(
      listenWhen: (p, c) =>
          (c.created != null && p.created != c.created) ||
          (c.useError != null && p.useError != c.useError),
      listener: (context, state) {
        if (state.useError case final error?) {
          const TrainingEffectHandler().handle(
            context,
            TrainingEffect.error(error),
          );
          return;
        }
        final routine = state.created!;
        context.showSnack(l10n.trainingTemplatesCreated(routine.name));
        // Las dos rutas viven en la pestaña de entreno: se cambia dentro de ella.
        context.go(TrainingPaths.routine(routine.id));
      },
      builder: (context, state) {
        final bloc = context.read<RoutineTemplatesBloc>();
        return Scaffold(
          appBar: AppPageBar(title: Text(l10n.trainingTemplatesTitle)),
          body: switch (state.status) {
            TemplatesStatus.loading => const AppSkeletonList(),
            TemplatesStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(const RoutineTemplatesEvent.started()),
            ),
            TemplatesStatus.ready => ListView(
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
                      Text(
                        l10n.trainingTemplatesIntro,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      // Sin ninguna plantilla (p. ej. un idioma sin semilla)
                      // no hay filtros que quitar: se ofrece crear la rutina.
                      if (state.templates.isEmpty)
                        AppCard(
                          child: AppEmptyState.compact(
                            icon: Icons.view_list_rounded,
                            title: l10n.trainingTemplatesNone,
                            message: l10n.trainingTemplatesNoneHint,
                            action: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: TokensSpacing.s,
                              runSpacing: TokensSpacing.s,
                              children: [
                                AppPrimaryButton(
                                  label: l10n.trainingNewRoutineAi,
                                  icon: Icons.lightbulb_outline_rounded,
                                  onPressed: () =>
                                      context.push(TrainingPaths.newRoutine()),
                                ),
                                AppSecondaryButton(
                                  label: l10n.trainingNewRoutineManual,
                                  icon: const Icon(Icons.edit_note_rounded),
                                  onPressed: () => context.push(
                                    TrainingPaths.newRoutine(
                                      mode: TrainingPaths.modeManual,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                      _Filters(state: state),
                      const SizedBox(height: TokensSpacing.m),
                      if (state.visible.isEmpty)
                        AppCard(
                          child: AppEmptyState.compact(
                            icon: Icons.filter_alt_off_rounded,
                            title: l10n.trainingTemplatesEmpty,
                            message: l10n.trainingTemplatesEmptyHint,
                            action: AppSecondaryButton(
                              label: l10n.trainingTemplatesClearFilters,
                              icon: const Icon(Icons.clear_all_rounded),
                              onPressed: () => bloc.add(
                                const RoutineTemplatesEvent.filterChanged(
                                  TemplateFilter(),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        for (final t in state.visible)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensSpacing.s,
                            ),
                            child: _TemplateCard(
                              template: t,
                              busy: state.usingId == t.id,
                              disabled: state.usingId != null,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          },
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final RoutineTemplatesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RoutineTemplatesBloc>();
    final f = state.filter;
    void set(TemplateFilter next) =>
        bloc.add(RoutineTemplatesEvent.filterChanged(next));
    return Wrap(
      spacing: TokensSpacing.xs,
      runSpacing: TokensSpacing.xs,
      children: [
        ChoiceChip(
          label: Text(l10n.trainingTemplatesAll),
          selected: f.isEmpty,
          onSelected: (_) => set(const TemplateFilter()),
        ),
        for (final days in state.dayOptions)
          ChoiceChip(
            label: Text(l10n.trainingTemplatesDays(days)),
            selected: f.days == days,
            onSelected: (on) => set(f.copyWith(days: on ? days : null)),
          ),
        FilterChip(
          avatar: const Icon(Icons.home_rounded, size: TokensSize.iconS),
          label: Text(l10n.trainingTemplatesAtHome),
          selected: f.atHome,
          onSelected: (on) => set(f.copyWith(atHome: on)),
        ),
        FilterChip(
          avatar: const Icon(Icons.school_rounded, size: TokensSize.iconS),
          label: Text(l10n.trainingTemplatesExams),
          selected: f.forExams,
          onSelected: (on) => set(f.copyWith(forExams: on)),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.busy,
    required this.disabled,
  });

  final RoutineTemplate template;
  final bool busy;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final t = template;
    final days = t.dayNumbers.map((d) => weekdayName(l10n, d)).join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.name, style: context.textStyles.titleMedium),
          if (t.description.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(t.description, style: context.textStyles.bodyMedium),
          ],
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: Icons.event_repeat_rounded,
                label: l10n.trainingTemplatesPerWeek(t.daysPerWeek),
                color: context.colors.secondary,
              ),
              AppPill(
                icon: Icons.schedule_rounded,
                label: l10n.trainingTemplatesMinutes(t.minutes),
                // «≈» no se lee bien en voz alta.
                semanticLabel: l10n.trainingEstimatedMinutesSpoken(t.minutes),
              ),
              AppPill(
                icon: Icons.calendar_view_week_rounded,
                label: l10n.trainingWeeksCount(t.weeks),
              ),
              AppPill(
                icon: t.atHome
                    ? Icons.home_rounded
                    : Icons.fitness_center_rounded,
                label: t.atHome
                    ? l10n.trainingTemplatesAtHome
                    : l10n.trainingTemplatesGym,
              ),
              if (t.forExams)
                AppPill(
                  icon: Icons.school_rounded,
                  label: l10n.trainingTemplatesForExams,
                  color: context.colors.tertiary,
                ),
              if (t.goal != null)
                AppPill(icon: Icons.flag_outlined, label: t.goal!.label(l10n)),
            ],
          ),
          if (days.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              days,
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.m),
          Semantics(
            label: l10n.trainingTemplatesUseNamed(t.name),
            excludeSemantics: true,
            button: true,
            child: AppSecondaryButton(
              label: l10n.trainingTemplatesUse,
              icon: const Icon(Icons.add_task_rounded),
              loading: busy,
              onPressed: disabled
                  ? null
                  : () => context.read<RoutineTemplatesBloc>().add(
                      RoutineTemplatesEvent.used(t.id),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
