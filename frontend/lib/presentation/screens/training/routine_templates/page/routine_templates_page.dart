import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/routine_template.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_effect.dart';
import '../../training_routes.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../widgets/training_section_bar.dart';
import '../bloc/routine_templates_bloc.dart';

/// Plantillas de rutina listas para usar: se filtran por lugar, días, tiempo,
/// nivel y exámenes (en una hoja, para que la lista se vea al entrar) y una se
/// convierte en rutina propia con un toque (ADR 0043). Si trae carreras, el
/// aviso dice que están en Correr.
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
        // El aviso sobrevive a esta pantalla: «Ver» usa el router, no este
        // contexto, que ya no existirá al pulsarlo.
        final router = GoRouter.of(context);
        if (state.createdWithRuns) {
          // Los entrenos de carrera los creó el servidor en Correr: el aviso
          // dice dónde quedan y lleva hasta allí.
          context.showActionSnack(
            l10n.trainingTemplatesCreatedWithRuns(routine.name),
            actionLabel: l10n.commonView,
            onAction: () =>
                router.go(TrainingPaths.section(TrainingSection.run)),
          );
        } else {
          context.showSnack(l10n.trainingTemplatesCreated(routine.name));
        }
        // Las dos rutas viven en la pestaña de entreno: se cambia dentro de ella.
        router.go(TrainingPaths.routine(routine.id));
      },
      builder: (context, state) {
        final bloc = context.read<RoutineTemplatesBloc>();
        return Scaffold(
          appBar: AppPageBar(
            leading: const AppBackButton(fallback: TrainingPaths.root),
            title: Text(l10n.trainingTemplatesTitle),
          ),
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
                                  icon: AppIcons.proposal,
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
                        _FilterBar(state: state),
                        const SizedBox(height: TokensSpacing.m),
                        if (state.visible.isEmpty)
                          AppCard(
                            child: AppEmptyState.compact(
                              icon: AppIcons.clearFilters,
                              title: l10n.trainingTemplatesEmpty,
                              message: l10n.trainingTemplatesEmptyHint,
                              action: AppSecondaryButton(
                                label: l10n.trainingTemplatesClearFilters,
                                icon: const Icon(AppIcons.clearFilters),
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

/// «Filtrar» (con cuántos hay puestos) y, si hay alguno, «Quitar filtros».
/// Los filtros van en una hoja: la lista cambia detrás mientras se eligen.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state});

  final RoutineTemplatesState state;

  Future<void> _open(BuildContext context) {
    final bloc = context.read<RoutineTemplatesBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<RoutineTemplatesBloc, RoutineTemplatesState>(
          builder: (sheetContext, current) {
            final l10n = sheetContext.localizations;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.l,
                0,
                TokensSpacing.l,
                TokensSpacing.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.trainingTemplatesFilter,
                      style: sheetContext.textStyles.titleLarge,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  _Filters(state: current),
                  const SizedBox(height: TokensSpacing.m),
                  // Al cambiar un filtro la lista queda tapada por la hoja: el
                  // recuento se anuncia (WCAG 4.1.3).
                  Semantics(
                    liveRegion: true,
                    child: current.visible.isEmpty
                        ? AppSecondaryButton(
                            label: l10n.trainingTemplatesClearFilters,
                            icon: const Icon(AppIcons.clearFilters),
                            onPressed: () =>
                                sheetContext.read<RoutineTemplatesBloc>().add(
                                  const RoutineTemplatesEvent.filterChanged(
                                    TemplateFilter(),
                                  ),
                                ),
                          )
                        : AppPrimaryButton(
                            label: l10n.trainingTemplatesShowResults(
                              current.visible.length,
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final active = state.filter.activeCount;
    return Wrap(
      spacing: TokensSpacing.s,
      runSpacing: TokensSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppSecondaryButton(
          label: active == 0
              ? l10n.trainingTemplatesFilter
              : l10n.trainingTemplatesFilterActive(active),
          icon: const Icon(AppIcons.filters),
          onPressed: () => _open(context),
        ),
        // Sin resultados, «Quitar filtros» ya está en la tarjeta vacía: no se
        // repite aquí (un camino por destino).
        if (active > 0 && state.visible.isNotEmpty)
          TextButton.icon(
            icon: const Icon(AppIcons.clearFilters),
            label: Text(l10n.trainingTemplatesClearFilters),
            onPressed: () => context.read<RoutineTemplatesBloc>().add(
              const RoutineTemplatesEvent.filterChanged(TemplateFilter()),
            ),
          ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Con icono: chips que bajan de fila (nunca se esconden a un lado).
        Semantics(
          container: true,
          label: l10n.trainingTemplatesWhere,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  l10n.trainingTemplatesWhere,
                  style: context.textStyles.labelLarge,
                ),
              ),
              const SizedBox(height: TokensSpacing.xs),
              Wrap(
                spacing: TokensSpacing.xs,
                runSpacing: TokensSpacing.xs,
                children: [
                  for (final place in state.placeOptions)
                    ChoiceChip(
                      avatar: Icon(
                        templatePlaceIcon(place),
                        size: TokensSize.iconS,
                      ),
                      label: Text(templatePlaceLabel(l10n, place)),
                      selected: f.place == place,
                      onSelected: (on) =>
                          set(f.copyWith(place: on ? place : null)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        if (state.dayOptions.length > 1) ...[
          AppSegmentedChoice<int>(
            label: l10n.trainingTemplatesDaysLabel,
            values: state.dayOptions,
            selected: f.days,
            labelOf: (d) => '$d',
            allowEmpty: true,
            onChanged: (d) => set(f.copyWith(days: d)),
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        if (state.timeOptions.length > 1) ...[
          AppSegmentedChoice<TemplateTime>(
            label: l10n.trainingTemplatesTimeLabel,
            values: state.timeOptions,
            selected: f.time,
            labelOf: (t) => _timeLabel(l10n, t),
            allowEmpty: true,
            onChanged: (t) => set(f.copyWith(time: t)),
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        AppSegmentedChoice<TemplateLevel>(
          label: l10n.trainingTemplatesLevelLabel,
          values: TemplateLevel.values,
          selected: f.level,
          labelOf: (l) => templateLevelLabel(l10n, l),
          allowEmpty: true,
          onChanged: (l) => set(f.copyWith(level: l)),
        ),
        const SizedBox(height: TokensSpacing.s),
        // Semanas de exámenes no es un nivel: interruptor propio.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilterChip(
            avatar: const Icon(Icons.school_rounded, size: TokensSize.iconS),
            label: Text(l10n.trainingTemplatesExams),
            selected: f.forExams,
            onSelected: (on) => set(f.copyWith(forExams: on)),
          ),
        ),
      ],
    );
  }

  static String _timeLabel(AppLocalizations l10n, TemplateTime time) =>
      switch (time) {
        TemplateTime.upTo20 => l10n.trainingTemplatesUpToMinutes(20),
        TemplateTime.upTo30 => l10n.trainingTemplatesUpToMinutes(30),
        TemplateTime.upTo45 => l10n.trainingTemplatesUpToMinutes(45),
        TemplateTime.more => l10n.trainingTemplatesMoreThanMinutes(45),
      };
}

/// Tarjeta de plantilla, para elegir de un vistazo: foto de uno de sus
/// ejercicios de fondo ([AppCoverCard]), dónde se hace y el nivel arriba, el
/// nombre, una línea con días, minutos y semanas, y «Usar». La descripción se
/// corta en dos líneas: el detalle se ve en la rutina ya creada.
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
    final use = disabled
        ? null
        : () => context.read<RoutineTemplatesBloc>().add(
            RoutineTemplatesEvent.used(t.id),
          );
    final facts = [
      l10n.trainingTemplatesPerWeek(t.daysPerWeek),
      l10n.trainingTemplatesMinutes(t.minutes),
      l10n.trainingWeeksCount(t.weeks),
    ];
    return AppCoverCard(
      imageUrl: t.coverImageUrl,
      padding: const EdgeInsets.all(TokensSpacing.m),
      footer: Semantics(
        container: true,
        label: l10n.trainingTemplatesUseNamed(t.name),
        excludeSemantics: true,
        button: true,
        enabled: !disabled,
        onTap: use,
        child: AppSecondaryButton(
          label: l10n.trainingTemplatesUse,
          icon: const Icon(Icons.add_task_rounded),
          loading: busy,
          onPressed: use,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              AppCoverPill(
                icon: templatePlaceIcon(t.place),
                label: templatePlaceLabel(l10n, t.place),
                color: context.colors.primary,
              ),
              AppCoverPill(label: templateLevelLabel(l10n, t.level)),
              if (t.hasRuns)
                AppCoverPill(
                  icon: Icons.directions_run_rounded,
                  label: l10n.trainingTemplatesRuns(t.runDays.length),
                ),
              if (t.forExams)
                AppCoverPill(
                  icon: Icons.school_rounded,
                  label: l10n.trainingTemplatesForExams,
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          Text(
            t.name,
            style: context.textStyles.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TokensSpacing.xxs),
          // «≈» no se lee bien en voz alta.
          Text(
            facts.join(' · '),
            semanticsLabel: [
              facts.first,
              l10n.trainingEstimatedMinutesSpoken(t.minutes),
              facts.last,
            ].join(', '),
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (t.description.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              t.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
