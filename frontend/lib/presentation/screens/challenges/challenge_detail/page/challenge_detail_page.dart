import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/challenge_link_type.dart';
import '../../../../../domain/enums/challenge_status.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../challenges_routes.dart';
import '../../quick_challenge/page/quick_challenge_sheet.dart';
import '../../widgets/challenge_content_width.dart';
import '../../widgets/challenge_feedback.dart';
import '../../widgets/challenge_labels.dart';
import '../../widgets/challenge_progress_bar.dart';
import '../../widgets/dependency_graph.dart';
import '../../widgets/milestone_tile.dart';
import '../bloc/challenge_detail_bloc.dart';
import 'challenge_detail_dialogs.dart';

/// Detalle de un reto (`/challenges/:challengeId`).
class ChallengeDetailPage extends StatelessWidget {
  const ChallengeDetailPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ChallengeDetailBloc>()
            ..add(ChallengeDetailEvent.started(challengeId)),
      child: _DetailView(challengeId: challengeId),
    );
  }
}

enum _MenuAction { edit, editTasks, reorder, visibility, delete }

class _DetailView extends StatelessWidget with ErrorsMessageMixin {
  const _DetailView({required this.challengeId});

  final String challengeId;

  ChallengeDetailBloc _bloc(BuildContext context) =>
      context.read<ChallengeDetailBloc>();

  Future<void> _onEffect(
    BuildContext context,
    ChallengeDetailEffect effect,
  ) async {
    final l10n = context.localizations;
    switch (effect) {
      case ChallengeDetailOutcome(
        :final xpDelta,
        :final unlockedTitles,
        :final challengeCompleted,
        :final progressRecorded,
        :final account,
      ):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        final hasMilestones =
            _bloc(context).state.challenge?.hasMilestones ?? false;
        final String base;
        if (challengeCompleted) {
          base = l10n.challengesChallengeDone;
        } else if (progressRecorded) {
          base = l10n.challengesProgressSaved;
        } else if (xpDelta < 0) {
          base = hasMilestones
              ? l10n.challengesMilestoneUndone
              : l10n.challengesChallengeUndone;
        } else {
          base = l10n.challengesMilestoneDone;
        }
        context.showSnack(
          challengeFeedbackMessage(
            context,
            base: base,
            xpDelta: xpDelta,
            unlockedTitles: unlockedTitles,
          ),
        );
      case ChallengeDetailDeleted(:final xpLost, :final account):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        context.showSnack(
          challengeFeedbackMessage(
            context,
            base: l10n.challengesDeleted,
            xpDelta: -xpLost,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(ChallengesPaths.root);
        }
      case ChallengeDetailCloned(:final challengeId):
        context.showSnack(l10n.challengesCloned);
        context.pushReplacement(ChallengesPaths.detail(challengeId));
      case ChallengeDetailSaved():
        context.showSnack(l10n.commonSaved);
      case ChallengeDetailOpenUrl(:final url):
        final ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!ok && context.mounted) context.showSnack(l10n.errorUnknown);
      case ChallengeDetailActionFailed(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  Future<void> _onMenu(
    BuildContext context,
    _MenuAction action,
    Challenge challenge,
  ) async {
    final bloc = _bloc(context);
    switch (action) {
      case _MenuAction.edit:
        final result = await showQuickChallengeSheet(
          context,
          editing: challenge,
        );
        if (result is QuickChallengeSaved) {
          bloc.add(ChallengeDetailEvent.challengeReplaced(result.challenge));
        }
      case _MenuAction.editTasks:
        final saved = await context.push<String>(
          ChallengesPaths.editMilestones(challenge.id),
        );
        if (saved != null) bloc.add(const ChallengeDetailEvent.refreshed());
      case _MenuAction.reorder:
        final ids = await showReorderMilestonesSheet(
          context,
          challenge.milestones,
        );
        if (ids != null) {
          bloc.add(ChallengeDetailEvent.milestonesReordered(ids));
        }
      case _MenuAction.visibility:
        final visibility = await showVisibilityDialog(
          context,
          challenge.visibility,
        );
        if (visibility != null) {
          bloc.add(ChallengeDetailEvent.visibilityChanged(visibility));
        }
      case _MenuAction.delete:
        final confirmed = await showDeleteChallengeDialog(
          context,
          challenge.totalXpAwarded,
        );
        if (confirmed) bloc.add(const ChallengeDetailEvent.deleteRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ChallengeDetailBloc, ChallengeDetailState>(
      listenWhen: (_, s) => s.effect != null,
      listener: (context, state) => _onEffect(context, state.effect!),
      builder: (context, state) {
        final challenge = state.challenge;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(l10n.challengesDetailTitle),
            actions: [
              if (challenge != null && challenge.owned)
                PopupMenuButton<_MenuAction>(
                  tooltip: l10n.challengesDetailMore,
                  enabled: !state.busy,
                  onSelected: (a) => _onMenu(context, a, challenge),
                  itemBuilder: (context) => [
                    _menuItem(
                      _MenuAction.edit,
                      Icons.edit_outlined,
                      l10n.challengesDetailEdit,
                    ),
                    _menuItem(
                      _MenuAction.editTasks,
                      Icons.checklist_rounded,
                      challenge.hasMilestones
                          ? l10n.challengesDetailEditTasks
                          : l10n.challengesDetailAddTasks,
                    ),
                    if (challenge.milestones.length > 1)
                      _menuItem(
                        _MenuAction.reorder,
                        Icons.swap_vert_rounded,
                        l10n.challengesDetailReorder,
                      ),
                    _menuItem(
                      _MenuAction.visibility,
                      challenge.visibility.challengeIcon,
                      l10n.challengesDetailVisibility,
                    ),
                    _menuItem(
                      _MenuAction.delete,
                      Icons.delete_outline_rounded,
                      l10n.challengesDetailDelete,
                    ),
                  ],
                ),
            ],
          ),
          bottomNavigationBar: challenge == null
              ? null
              : _BottomActions(challenge: challenge, busy: state.busy),
          body: switch (state.status) {
            ChallengeDetailStatus.loading => const _DetailSkeleton(),
            ChallengeDetailStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () =>
                  _bloc(context).add(ChallengeDetailEvent.started(challengeId)),
            ),
            ChallengeDetailStatus.ready => RefreshIndicator(
              onRefresh: () async {
                _bloc(context).add(const ChallengeDetailEvent.refreshed());
                await _bloc(context).stream.first;
              },
              child: _DetailContent(state: state),
            ),
          },
        );
      },
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction action,
    IconData icon,
    String label,
  ) => PopupMenuItem(
    value: action,
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      contentPadding: EdgeInsets.zero,
    ),
  );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.state});

  final ChallengeDetailState state;

  void _openLink(BuildContext context, ChallengeLink link) => context.push(
    link.type == ChallengeLinkType.block
        ? ChallengesExternalPaths.planner
        : ChallengesExternalPaths.deadlines,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final challenge = state.challenge!;
    final bloc = context.read<ChallengeDetailBloc>();
    final titles = {for (final m in challenge.milestones) m.id: m.title};
    final link = challenge.link;
    final dependent = challenge.milestones
        .where((m) => m.dependencies.isNotEmpty)
        .length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        ChallengeContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(challenge: challenge, subjectName: state.subjectName),
              if (!challenge.owned) ...[
                const SizedBox(height: TokensSpacing.m),
                AppCard(
                  color: context.colors.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: context.colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: TokensSpacing.s),
                      Expanded(
                        child: Text(
                          l10n.challengesDetailReadOnly(
                            challenge.ownerName ?? l10n.challengesUnknownAuthor,
                          ),
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: TokensSpacing.m),
              _ProgressCard(challenge: challenge),
              if (link != null) ...[
                const SizedBox(height: TokensSpacing.m),
                AppCard(
                  onTap: challenge.owned
                      ? () => _openLink(context, link)
                      : null,
                  child: Row(
                    children: [
                      Icon(link.type.icon, color: context.colors.tertiary),
                      const SizedBox(width: TokensSpacing.m),
                      Expanded(
                        child: Text(
                          link.type.linkedLabel(context),
                          style: context.textStyles.bodyLarge,
                        ),
                      ),
                      if (challenge.owned)
                        Text(
                          l10n.challengesLinkOpen,
                          style: context.textStyles.labelLarge?.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.challengesDetailTasks),
              if (challenge.milestones.isEmpty)
                Text(
                  l10n.challengesDetailNoTasks,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                )
              else
                for (final m in challenge.milestones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                    child: MilestoneTile(
                      milestone: m,
                      dependencyTitles: [
                        for (final d in m.dependencies) ?titles[d],
                      ],
                      busy: state.busyMilestoneId == m.id,
                      onToggle: challenge.owned && !state.busy
                          ? () => bloc.add(
                              ChallengeDetailEvent.milestoneToggled(m.id),
                            )
                          : null,
                      onOpenNote: m.noteId == null
                          ? null
                          : () => context.push(
                              ChallengesExternalPaths.note(m.noteId!),
                            ),
                      onOpenFile: m.fileId == null
                          ? null
                          : () => bloc.add(
                              ChallengeDetailEvent.fileRequested(m.fileId!),
                            ),
                      onOpenLink: m.link == null
                          ? null
                          : () => _openLink(context, m.link!),
                    ),
                  ),
              if (challenge.hasDependencies) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.challengesDetailGraph),
                Text(
                  l10n.challengesDetailGraphSummary(dependent),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                AppCard(
                  child: DependencyGraph(milestones: challenge.milestones),
                ),
              ],
              if (challenge.owned) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.challengesDetailHistory),
                if (state.history.isEmpty)
                  Text(
                    l10n.challengesDetailHistoryEmpty,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final e in state.history)
                          ListTile(
                            leading: Icon(
                              Icons.trending_up_rounded,
                              color: context.palette.success,
                            ),
                            title: Text(
                              e.milestoneId == null
                                  ? l10n.challengesDetailHistoryGeneral
                                  : titles[e.milestoneId] ??
                                        l10n.challengesProgressTask,
                            ),
                            subtitle: Text(
                              ChallengeFormats.dateTime(e.recordedAt),
                            ),
                            trailing: Text(
                              l10n.challengesDetailHistoryEntry(
                                ChallengeFormats.number(e.amount),
                              ),
                              style: context.textStyles.labelLarge,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: TokensSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.challenge, this.subjectName});

  final Challenge challenge;
  final String? subjectName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final accent = challenge.type.color(context);
    final goal = challenge.goal;
    final origin = challenge.originOwnerName;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: challenge.type.icon,
                label: challenge.type.label(context),
                color: accent,
              ),
              AppPill(
                icon: challenge.status.icon,
                label: challenge.status.label(context),
                color: challenge.status.color(context),
              ),
              AppPill(
                icon: challenge.difficulty.icon,
                label: challenge.difficulty.effortLabel(context),
                color: context.colors.onSurfaceVariant,
              ),
              if (challenge.owned)
                AppPill(
                  icon: challenge.visibility.challengeIcon,
                  label: challenge.visibility.challengeLabel(context),
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          Text(challenge.title, style: context.textStyles.headlineSmall),
          if (goal != null && goal.isNotEmpty && goal != challenge.title) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(goal, style: context.textStyles.bodyMedium),
          ],
          const SizedBox(height: TokensSpacing.m),
          _InfoRow(
            icon: Icons.date_range_outlined,
            text: l10n.challengesDetailDates(
              ChallengeFormats.longDate(challenge.startAt),
              ChallengeFormats.longDate(challenge.endAt),
            ),
          ),
          if (subjectName != null)
            _InfoRow(icon: Icons.menu_book_outlined, text: subjectName!),
          if (!challenge.owned)
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: l10n.challengesByAuthor(
                challenge.ownerName ?? l10n.challengesUnknownAuthor,
              ),
            ),
          if (origin != null)
            _InfoRow(
              icon: Icons.copy_all_rounded,
              text: l10n.challengesClonedFrom(origin),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final completed = challenge.status == ChallengeStatus.completed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.challengesDetailProgress,
                  style: context.textStyles.titleMedium,
                ),
              ),
              if (challenge.hasMilestones)
                Text(
                  l10n.challengesMilestonesProgress(
                    challenge.completedMilestoneCount,
                    challenge.milestoneCount,
                  ),
                  style: context.textStyles.labelLarge,
                ),
              if (challenge.tracksTrainingSessions) ...[
                Icon(
                  Icons.fitness_center_rounded,
                  size: 18,
                  color: challenge.type.color(context),
                ),
                const SizedBox(width: TokensSpacing.xs),
                Text(
                  l10n.challengesSessionsProgress(
                    challenge.sessionsCompleted,
                    challenge.sessionTarget ?? 0,
                  ),
                  style: context.textStyles.labelLarge,
                ),
              ],
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          ChallengeProgressBar(
            value: challenge.progressFraction,
            color: completed
                ? context.palette.success
                : challenge.type.color(context),
          ),
          if (challenge.tracksTrainingSessions) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.challengesDetailSessionsInfo,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.m),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.local_fire_department_rounded,
                  color: context.palette.streak,
                  label: l10n.challengesDetailStreak,
                  value: l10n.challengesDetailDaysValue(
                    challenge.currentStreak,
                  ),
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.military_tech_outlined,
                  color: context.palette.streak,
                  label: l10n.challengesDetailBestStreak,
                  value: l10n.challengesDetailDaysValue(challenge.bestStreak),
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.bolt_rounded,
                  color: context.palette.accent,
                  label: l10n.challengesDetailReward,
                  value: l10n.challengesXpGain(
                    challenge.hasMilestones
                        ? challenge.milestones.fold(
                            0,
                            (sum, m) => sum + m.xpReward,
                          )
                        : challenge.xpReward,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: TokensSpacing.xs),
        Text(value, style: context.textStyles.titleSmall),
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.challenge, required this.busy});

  final Challenge challenge;
  final bool busy;

  Future<void> _recordProgress(BuildContext context) async {
    final bloc = context.read<ChallengeDetailBloc>();
    final result = await showRecordProgressDialog(context, challenge);
    if (result != null) {
      bloc.add(
        ChallengeDetailEvent.progressRecorded(
          milestoneId: result.milestoneId,
          amount: result.amount,
        ),
      );
    }
  }

  Future<void> _toggleCompletion(BuildContext context) async {
    final bloc = context.read<ChallengeDetailBloc>();
    if (challenge.completed) {
      final confirmed = await showUncompleteDialog(context);
      if (!confirmed) return;
    }
    bloc.add(const ChallengeDetailEvent.completionToggled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final children = <Widget>[];
    if (!challenge.owned) {
      children.add(
        Expanded(
          child: AppPrimaryButton(
            label: l10n.challengesClone,
            icon: Icons.copy_all_rounded,
            loading: busy,
            onPressed: () => context.read<ChallengeDetailBloc>().add(
              const ChallengeDetailEvent.cloneRequested(),
            ),
          ),
        ),
      );
    } else {
      if (!challenge.completed) {
        children.add(
          Expanded(
            child: AppSecondaryButton(
              label: l10n.challengesDetailRecordProgress,
              icon: const Icon(Icons.add_chart_rounded),
              onPressed: busy ? null : () => _recordProgress(context),
            ),
          ),
        );
      }
      if (!challenge.hasMilestones) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(width: TokensSpacing.s));
        }
        children.add(
          Expanded(
            child: AppPrimaryButton(
              label: challenge.completed
                  ? l10n.challengesDetailUncomplete
                  : l10n.challengesDetailComplete,
              loading: busy,
              onPressed: () => _toggleCompletion(context),
            ),
          ),
        );
      }
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        padding: const EdgeInsets.all(TokensSpacing.m),
        child: ChallengeContentWidth(child: Row(children: children)),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(TokensSpacing.m),
    children: const [
      AppSkeletonGroup(
        child: ChallengeContentWidth(
          child: Column(
            children: [
              AppSkeleton(height: 160),
              SizedBox(height: TokensSpacing.m),
              AppSkeleton(height: 140),
              SizedBox(height: TokensSpacing.l),
              AppSkeleton(height: 96),
              SizedBox(height: TokensSpacing.s),
              AppSkeleton(height: 96),
            ],
          ),
        ),
      ),
    ],
  );
}
