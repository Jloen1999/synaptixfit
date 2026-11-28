import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/routine_template.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../exercise_detail/page/exercise_how_to_sheet.dart';
import '../../training_effect.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../routine_templates/page/template_used_notice.dart';
import '../bloc/routine_template_detail_bloc.dart';

/// Detalle de una plantilla de rutina para decidir antes de usarla: portada,
/// los datos clave en una línea y cada día con sus ejercicios (que abren
/// «Cómo se hace»). Una sola acción principal, «Usar esta plantilla», con el
/// mismo alta y el mismo aviso que la lista.
class RoutineTemplateDetailPage extends StatelessWidget {
  const RoutineTemplateDetailPage({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RoutineTemplateDetailBloc>()
            ..add(RoutineTemplateDetailEvent.started(templateId)),
      child: const RoutineTemplateDetailView(),
    );
  }
}

/// Vista del detalle (separada para probarla con un bloc simulado).
class RoutineTemplateDetailView extends StatelessWidget {
  const RoutineTemplateDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RoutineTemplateDetailBloc, RoutineTemplateDetailState>(
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
        announceTemplateUsed(
          context,
          state.created!,
          withRuns: state.detail?.summary.hasRuns ?? false,
        );
      },
      builder: (context, state) {
        final bloc = context.read<RoutineTemplateDetailBloc>();
        final detail = state.detail;
        final ready =
            state.status == TemplateDetailStatus.ready && detail != null;
        return Scaffold(
          appBar: AppPageBar(
            leading: const AppBackButton(fallback: TrainingPaths.templates),
            title: Text(
              ready ? detail.summary.name : l10n.trainingTemplatesTitle,
            ),
          ),
          body: switch (state.status) {
            TemplateDetailStatus.loading => const AppSkeletonList(),
            TemplateDetailStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(
                RoutineTemplateDetailEvent.started(state.templateId),
              ),
            ),
            TemplateDetailStatus.ready => _Content(detail: detail!),
          },
          // La acción principal, siempre a la vista bajo la lista.
          bottomNavigationBar: ready && !detail.isEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensSpacing.m,
                      TokensSpacing.s,
                      TokensSpacing.m,
                      TokensSpacing.m,
                    ),
                    child: TrainingContent(
                      child: AppPrimaryButton(
                        label: l10n.trainingTemplatesUse,
                        icon: Icons.add_task_rounded,
                        loading: state.using,
                        onPressed: state.using
                            ? null
                            : () => bloc.add(
                                const RoutineTemplateDetailEvent.used(),
                              ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.detail});

  final RoutineTemplateDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final t = detail.summary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xl,
      ),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cover(template: t),
              const SizedBox(height: TokensSpacing.l),
              if (detail.isEmpty)
                AppCard(
                  child: AppEmptyState.compact(
                    icon: Icons.view_list_rounded,
                    title: l10n.trainingTemplateDetailEmpty,
                    message: l10n.trainingTemplateDetailEmptyHint,
                  ),
                )
              else ...[
                for (final day in detail.days)
                  if (day.exercises.isNotEmpty) ...[
                    AppSectionHeader(
                      title: dayTitle(l10n, day.dayNumber, day.name),
                    ),
                    if (day.name != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: TokensSpacing.xs,
                        ),
                        child: Text(
                          weekdayName(l10n, day.dayNumber),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final e in day.exercises) _ExerciseRow(e: e),
                        ],
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                  ],
                if (detail.runDays.isNotEmpty) ...[
                  AppSectionHeader(title: l10n.trainingTemplateDetailRuns),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final r in detail.runDays)
                          ListTile(
                            minTileHeight: TokensSize.listTileMin,
                            leading: const Icon(Icons.directions_run_rounded),
                            title: Text(
                              l10n.trainingTemplatesRunDay(
                                weekdayName(l10n, r.dayNumber),
                              ),
                            ),
                            subtitle: r.workoutName == null
                                ? null
                                : Text(r.workoutName!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  Text(
                    l10n.trainingTemplateRunHint,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Portada: foto, lugar y nivel, nombre, la línea de datos y la descripción.
class _Cover extends StatelessWidget {
  const _Cover({required this.template});

  final RoutineTemplate template;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final t = template;
    final facts = [
      l10n.trainingTemplatesPerWeek(t.daysPerWeek),
      l10n.trainingTemplatesMinutes(t.minutes),
      l10n.trainingWeeksCount(t.weeks),
    ];
    return AppCoverCard(
      imageUrl: t.coverImageUrl,
      layout: AppCoverLayout.bottom,
      padding: const EdgeInsets.all(TokensSpacing.m),
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
              if (t.forExams)
                AppCoverPill(
                  icon: Icons.school_rounded,
                  label: l10n.trainingTemplatesForExams,
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
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
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un ejercicio: miniatura, nombre y «3 series · 8–12 reps · Descanso 90 s».
/// Toda la fila abre «Cómo se hace» (si el ejercicio sigue en el catálogo).
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.e});

  final TemplateExercise e;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final name = e.name;
    return AppFocusOutline(
      child: ListTile(
        minTileHeight: TokensSize.listTileMin,
        leading: ExerciseThumbnail(url: e.imageUrl),
        title: Text(name ?? l10n.trainingTemplateExerciseUnknown),
        subtitle: Text(templateExerciseSummary(l10n, e)),
        trailing: name == null ? null : const Icon(AppIcons.next),
        onTap: name == null
            ? null
            : () => showExerciseHowToSheet(
                context,
                exerciseId: e.exerciseId,
                name: name,
                previewUrl: e.imageUrl,
              ),
      ),
    );
  }
}

/// «3 series · 8–12 reps · Descanso 90 s» (o «· 30 s» si se aguanta).
String templateExerciseSummary(AppLocalizations l10n, TemplateExercise e) => [
  l10n.trainingSummarySets(e.sets),
  if (e.holdSeconds case final hold?)
    l10n.trainingSecondsUnit('$hold')
  else if (e.hasRange)
    l10n.trainingRepsUnit(l10n.trainingValueRange('${e.repMin}', '${e.repMax}'))
  else
    l10n.trainingRepsUnit('${e.reps}'),
  if (e.restSeconds > 0) l10n.trainingChipRestLabel(e.restSeconds),
].join(' · ');
