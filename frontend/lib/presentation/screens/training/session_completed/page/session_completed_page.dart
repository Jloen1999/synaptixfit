import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/personal_record_row.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../bloc/session_completed_bloc.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/progress/streak.dart';
import '../../../challenges/challenges_routes.dart';

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
      child: _CompletedView(sessionId: sessionId),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.sessionId});

  final String sessionId;

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
            CompletedStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () =>
                  bloc.add(SessionCompletedEvent.started(sessionId: sessionId)),
            ),
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
                          radius: TokensSize.emptyBadge / 2,
                          backgroundColor: context.palette.accentContainer,
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: TokensSize.iconXl,
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
                      const SizedBox(height: TokensSpacing.xs),
                      // La duración no es la prevista: es la real, y con ella
                      // se calcula la carga (lo explica para que no extrañe).
                      Text(
                        l10n.trainingDurationIsReal,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      if (state.highlights != null) ...[
                        const SizedBox(height: TokensSpacing.m),
                        _HighlightsCard(
                          highlights: state.highlights!,
                          shared: state.shared,
                          sharing: state.sharing,
                          preview: _shareText(context, state),
                          onShare: () => bloc.add(
                            SessionCompletedEvent.shareRequested(
                              _shareText(context, state),
                            ),
                          ),
                        ),
                      ],
                      if (state.experience != null) ...[
                        const SizedBox(height: TokensSpacing.m),
                        _ExperienceCard(
                          experience: state.experience!,
                          withheld: state.xpWithheld,
                        ),
                      ],
                      if (state.streak != null ||
                          state.trainingChallenges.isNotEmpty) ...[
                        const SizedBox(height: TokensSpacing.m),
                        _AdvanceCard(
                          streak: state.streak,
                          challenges: state.trainingChallenges,
                        ),
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
        final columns = c.maxWidth > TokensLayout.statsFourColumns ? 4 : 2;
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

/// XP de la sesión, el nivel y, si no sumó, el motivo que da el servidor; con
/// el acceso a «Cómo se gana XP».
class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience, this.withheld});

  final ExperienceChange experience;
  final SessionXpWithheld? withheld;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = experience;
    final onCard = context.palette.onAccentContainer;
    final reason = e.xpDelta > 0
        ? null
        : switch (withheld) {
            SessionXpWithheld.shortSession => l10n.trainingXpWithheldShort,
            SessionXpWithheld.dailyLimit => l10n.trainingXpWithheldDaily,
            null => null,
          };
    return AppCard(
      color: context.palette.accentContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _experienceRow(context, e),
          if (reason != null) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              reason,
              style: context.textStyles.bodyMedium?.copyWith(color: onCard),
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: onCard),
              onPressed: () => showXpGuideSheet(context),
              icon: const Icon(Icons.help_outline_rounded),
              label: Text(l10n.xpGuideOpen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceRow(BuildContext context, ExperienceChange e) {
    final l10n = context.localizations;
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          color: context.palette.accent,
          size: TokensSize.iconL,
        ),
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
    );
  }
}

/// Texto que se publica en el muro: duración, volumen (si lo hay) y récords.
String _shareText(BuildContext context, SessionCompletedState state) {
  final l10n = context.localizations;
  final h = state.highlights!;
  final minutes = state.session!.durationMinutes;
  final number = NumberFormat.decimalPattern(l10n.localeName);
  final lines = [
    h.volumeKg > 0
        ? l10n.trainingShareText(minutes, number.format(h.volumeKg.round()))
        : l10n.trainingShareTextNoVolume(minutes),
    for (final r in h.records)
      (r.exerciseName == null || r.exerciseName!.trim().isEmpty)
          ? l10n.trainingShareRecordUnnamed(recordValueLabel(context, r))
          : l10n.trainingShareRecord(
              r.exerciseName!,
              recordValueLabel(context, r),
            ),
  ];
  return lines.join('\n');
}

/// Lo destacado de la sesión: volumen (y su diferencia con la anterior
/// comparable), récords batidos y compartir en el muro (con vista previa).
class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({
    required this.highlights,
    required this.shared,
    required this.sharing,
    required this.preview,
    required this.onShare,
  });

  final SessionHighlights highlights;
  final bool shared;
  final bool sharing;

  /// Texto que se publicará (se enseña antes de confirmar).
  final String preview;
  final VoidCallback onShare;

  Future<void> _confirm(BuildContext context) async {
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.trainingShareConfirmTitle,
      message: preview,
      confirmLabel: l10n.trainingSharePublish,
      destructive: false,
    );
    if (ok) onShare();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final delta = highlights.volumeDeltaKg?.round();
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlights.volumeKg > 0) ...[
            Text(
              l10n.trainingVolumeMoved(
                number.format(highlights.volumeKg.round()),
              ),
              style: context.textStyles.titleMedium,
            ),
            if (delta != null && delta != 0)
              Text(
                delta > 0
                    ? l10n.trainingVolumeMore(number.format(delta))
                    : l10n.trainingVolumeLess(number.format(-delta)),
                style: muted,
              ),
            const SizedBox(height: TokensSpacing.s),
          ],
          if (highlights.records.isNotEmpty) ...[
            Text(
              l10n.trainingNewRecords(highlights.records.length),
              style: context.textStyles.titleSmall,
            ),
            const SizedBox(height: TokensSpacing.xs),
            for (final r in highlights.records)
              Padding(
                padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                child: PersonalRecordRow(record: r),
              ),
            const SizedBox(height: TokensSpacing.s),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: shared
                ? AppPill(
                    icon: Icons.check_rounded,
                    color: context.palette.success,
                    label: l10n.trainingShared,
                  )
                : AppSecondaryButton(
                    label: l10n.trainingShareWall,
                    icon: const Icon(Icons.dynamic_feed_rounded),
                    loading: sharing,
                    onPressed: () => _confirm(context),
                  ),
          ),
        ],
      ),
    );
  }
}

/// «Tu avance»: la racha y los retos que suman entrenos, para ver qué ha
/// aportado la sesión y lo que queda.
class _AdvanceCard extends StatelessWidget {
  const _AdvanceCard({required this.streak, required this.challenges});

  final Streak? streak;
  final List<Challenge> challenges;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = streak;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.trainingDoneProgressTitle,
            style: context.textStyles.titleMedium,
          ),
          if (s != null && s.currentDays > 0) ...[
            const SizedBox(height: TokensSpacing.s),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: context.palette.calories,
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.trainingDoneStreak(s.currentDays),
                        style: context.textStyles.titleSmall,
                      ),
                      if (s.activeToday)
                        Text(
                          l10n.trainingDoneStreakToday,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          for (final c in challenges) ...[
            const SizedBox(height: TokensSpacing.m),
            _ChallengeProgress(challenge: c),
          ],
        ],
      ),
    );
  }
}

class _ChallengeProgress extends StatelessWidget {
  const _ChallengeProgress({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final c = challenge;
    final target = c.sessionTarget ?? 0;
    final left = c.sessionsRemaining;
    return AppCardTapArea(
      semanticLabel: l10n.trainingDoneSeeChallenge(c.title),
      onTap: () => context.go(ChallengesPaths.detail(c.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: context.colors.tertiary),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(c.title, style: context.textStyles.titleSmall),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          if (target > 0) ...[
            const SizedBox(height: TokensSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: LinearProgressIndicator(
                value: (c.sessionsCompleted / target).clamp(0, 1).toDouble(),
                color: context.colors.tertiary,
                backgroundColor: context.colors.tertiaryContainer,
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              [
                l10n.trainingDoneChallengeSessions(c.sessionsCompleted, target),
                left == 0
                    ? l10n.trainingDoneChallengeDone
                    : l10n.trainingDoneChallengeLeft(left),
              ].join(' · '),
              style: context.textStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
