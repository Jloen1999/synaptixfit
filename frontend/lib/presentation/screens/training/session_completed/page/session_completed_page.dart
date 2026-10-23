import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../bloc/session_completed_bloc.dart';

/// Pantalla de sesión completada.
class SessionCompletedPage extends StatelessWidget {
  const SessionCompletedPage({super.key, required this.sessionId, this.result});

  final String sessionId;
  final FinishSessionResult? result;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SessionCompletedBloc>()
        ..add(
          SessionCompletedEvent.started(sessionId: sessionId, result: result),
        ),
      child: const _CompletedView(),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView();

  void _done(BuildContext context) => context.go(TrainingPaths.root);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SessionCompletedBloc, SessionCompletedState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        final bloc = context.read<SessionCompletedBloc>();
        return Scaffold(
          appBar: AppPageBar(
            automaticallyImplyLeading: false,
            title: Text(l10n.trainingCompletedTitle),
            actions: [
              IconButton(
                tooltip: l10n.commonClose,
                onPressed: () => _done(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          body: switch (state.status) {
            CompletedStatus.loading => const AppSkeletonList(
              count: 3,
              height: 96,
            ),
            CompletedStatus.failure => AppErrorView(error: state.error!),
            CompletedStatus.ready => ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                TrainingContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: TokensSpacing.m),
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: context.palette.accentContainer,
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 44,
                            color: context.palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      Text(
                        l10n.trainingCompletedHeadline,
                        style: context.textStyles.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: TokensSpacing.l),
                      _Metrics(state: state),
                      if (state.experience != null) ...[
                        const SizedBox(height: TokensSpacing.m),
                        _ExperienceCard(experience: state.experience!),
                      ],
                      if (state.recommendations.isNotEmpty) ...[
                        const SizedBox(height: TokensSpacing.l),
                        AppSectionHeader(
                          title: l10n.trainingRecommendationsTitle,
                        ),
                        for (final r in state.recommendations)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensSpacing.s,
                            ),
                            child: RecommendationCard(
                              initiallyExpanded: true,
                              recommendation: r,
                              busy: state.busyIds.contains(r.id),
                              onApply: () => bloc.add(
                                SessionCompletedEvent.recommendationApplied(
                                  r.id,
                                ),
                              ),
                              onDiscard: () => bloc.add(
                                SessionCompletedEvent.recommendationDiscarded(
                                  r.id,
                                ),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: TokensSpacing.l),
                      AppPrimaryButton(
                        label: l10n.trainingBackToRoutines,
                        onPressed: () => _done(context),
                      ),
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

class _Metrics extends StatelessWidget {
  const _Metrics({required this.state});

  final SessionCompletedState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = state.session!;
    final tiles = [
      AppMetricTile(
        icon: Icons.timer_outlined,
        color: context.palette.sessions,
        value: l10n.trainingMinutes(s.durationMinutes),
        label: l10n.trainingDuration,
      ),
      AppMetricTile(
        icon: Icons.local_fire_department_rounded,
        color: context.palette.calories,
        value: s.calories == null
            ? '—'
            : l10n.trainingKcal(s.calories!.round()),
        label: l10n.trainingCalories,
      ),
      AppMetricTile(
        icon: Icons.check_circle_outline_rounded,
        color: context.colors.secondary,
        value: '${s.sets.where((x) => x.completed).length}',
        label: l10n.trainingSetsLabel,
      ),
      if (s.rpe != null)
        AppMetricTile(
          icon: Icons.speed_rounded,
          color: context.palette.warning,
          value: '${s.rpe}/10',
          label: l10n.trainingRpeLabel,
        ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth > 560 ? 4 : 2;
        final width = (c.maxWidth - TokensSpacing.s * (columns - 1)) / columns;
        return Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience});

  final ExperienceChange experience;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = experience;
    return AppCard(
      color: context.palette.accentContainer,
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: context.palette.accent, size: 32),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trainingXpGained(e.xpDelta),
                  style: context.textStyles.titleMedium?.copyWith(
                    color: context.palette.onAccentContainer,
                  ),
                ),
                Text(
                  e.levelUps > 0
                      ? l10n.trainingLevelUp(e.level)
                      : l10n.commonLevel(e.level),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.palette.onAccentContainer,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.trainingLevelXp(e.levelXp),
            style: context.textStyles.labelLarge?.copyWith(
              color: context.palette.onAccentContainer,
            ),
          ),
        ],
      ),
    );
  }
}
