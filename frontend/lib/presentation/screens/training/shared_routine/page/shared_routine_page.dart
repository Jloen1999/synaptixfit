import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/routine_share.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_labels.dart';
import '../bloc/shared_routine_bloc.dart';

/// Rutina abierta desde un enlace (ADR 0043): su resumen (solo la rutina,
/// nada de quien la comparte) y una acción principal, «Copiar a mis rutinas».
class SharedRoutinePage extends StatelessWidget {
  const SharedRoutinePage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SharedRoutineBloc>()..add(SharedRoutineEvent.started(token)),
      child: const _SharedView(),
    );
  }
}

class _SharedView extends StatelessWidget with ErrorsMessageMixin {
  const _SharedView();

  /// Enlace caducado, revocado o desconocido: no es un fallo para reintentar.
  static bool _linkGone(AppError? error) =>
      error is BusinessError && error.code == 'ROUTINE_SHARE_LINK_NOT_FOUND';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SharedRoutineBloc, SharedRoutineState>(
      listenWhen: (p, c) =>
          (c.copied != null && p.copied != c.copied) ||
          (c.copyError != null && p.copyError != c.copyError),
      listener: (context, state) {
        if (state.copyError case final error?) {
          context.showSnack(errorMessage(context, error));
          return;
        }
        context.showSnack(l10n.trainingSharedCopied(state.copied!.name));
        // La rutina vive dentro de la pestaña Entreno: se cambia con `go`.
        context.go(TrainingPaths.routine(state.copied!.id));
      },
      builder: (context, state) {
        final bloc = context.read<SharedRoutineBloc>();
        final preview = state.preview;
        return Scaffold(
          appBar: AppPageBar(title: Text(l10n.trainingSharedTitle)),
          body: switch (state.status) {
            SharedRoutineStatus.loading => const AppSkeletonList(),
            SharedRoutineStatus.failure when _linkGone(state.error) => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(TokensSpacing.l),
                child: AppEmptyState(
                  icon: Icons.link_off_rounded,
                  title: l10n.trainingSharedGone,
                  message: l10n.trainingSharedGoneHint,
                  action: AppSecondaryButton(
                    label: l10n.trainingSharedGoToTraining,
                    onPressed: () => context.go(TrainingPaths.root),
                  ),
                ),
              ),
            ),
            SharedRoutineStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(SharedRoutineEvent.started(state.token)),
            ),
            SharedRoutineStatus.ready => ListView(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                TokensSpacing.s,
                TokensSpacing.m,
                TokensSpacing.xxl,
              ),
              children: [TrainingContent(child: _Summary(preview: preview!))],
            ),
          },
          bottomNavigationBar: state.status == SharedRoutineStatus.ready
              ? SafeArea(
                  minimum: const EdgeInsets.all(TokensSpacing.m),
                  child: TrainingContent(
                    child: AppPrimaryButton(
                      label: l10n.trainingClone,
                      icon: AppIcons.copyToMine,
                      loading: state.copying,
                      onPressed: () =>
                          bloc.add(const SharedRoutineEvent.copyRequested()),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.preview});

  final SharedRoutinePreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final p = preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(p.name, style: context.textStyles.headlineSmall),
        ),
        if (p.description != null && p.description!.isNotEmpty) ...[
          const SizedBox(height: TokensSpacing.xs),
          Text(p.description!, style: context.textStyles.bodyMedium),
        ],
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.xs,
          runSpacing: TokensSpacing.xs,
          children: [
            AppPill(
              icon: Icons.event_repeat_rounded,
              label: l10n.trainingTemplatesPerWeek(p.daysPerWeek),
              color: context.colors.secondary,
            ),
            AppPill(
              icon: Icons.calendar_view_week_rounded,
              label: l10n.trainingWeeksCount(p.durationWeeks),
            ),
            if (p.goal != null)
              AppPill(icon: Icons.flag_outlined, label: p.goal!.label(l10n)),
          ],
        ),
        if (p.firstWeek.isNotEmpty) ...[
          const SizedBox(height: TokensSpacing.l),
          Text(
            l10n.trainingSharedFirstWeek,
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        for (final day in p.firstWeek)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.s),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    day.name == null || day.name!.isEmpty
                        ? weekdayName(l10n, day.dayNumber)
                        : '${weekdayName(l10n, day.dayNumber)} · ${day.name}',
                    style: context.textStyles.titleSmall,
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  for (final e in day.exercises)
                    Padding(
                      padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                      child: Text(
                        l10n.trainingSharedExerciseLine(e.name, e.sets),
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
