import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../app/di/app_di.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../extensions/context_extensions.dart';
import '../../../../../mixins/errors_message_mixin.dart';
import '../../../../../theme/tokens.g.dart';
import '../../../../../widgets/widgets.dart';
import '../../../social_routes.dart';
import '../../widgets/together_labels.dart';
import '../../widgets/together_widgets.dart';
import '../bloc/together_bloc.dart';

/// «Con amigos» (ADR 0044): invitaciones arriba, luego retos, rachas y entrenos
/// de hoy. Solo amigos mutuos; nunca se comparte cómo está cada uno.
class TogetherPage extends StatelessWidget {
  const TogetherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<TogetherBloc>()..add(const TogetherEvent.started()),
        ),
        BlocProvider(create: (_) => createSafetyBloc()),
      ],
      child: const _TogetherView(),
    );
  }
}

class _TogetherView extends StatelessWidget with ErrorsMessageMixin {
  const _TogetherView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<TogetherBloc>();
    return TogetherSafetyListener(
      onBlocked: (_) => bloc.add(const TogetherEvent.refreshed()),
      child: BlocConsumer<TogetherBloc, TogetherState>(
        listenWhen: (p, c) =>
            (c.message != null && c.message != p.message) ||
            (c.actionError != null && c.actionError != p.actionError),
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
            return;
          }
          context.showSnack(switch (state.message!) {
            TogetherMessage.streakProposed => l10n.togetherStreakProposed,
            TogetherMessage.streakAccepted => l10n.togetherStreakAccepted,
            TogetherMessage.streakEnded => l10n.togetherStreakEnded,
            TogetherMessage.streakWithdrawn => l10n.togetherStreakWithdrawn,
            TogetherMessage.declined => l10n.togetherDeclined,
            TogetherMessage.streakNudged => l10n.togetherStreakNudged,
          });
        },
        builder: (context, state) => Scaffold(
          appBar: AppPageBar.reading(title: Text(l10n.togetherTitle)),
          body: switch (state.status) {
            TogetherStatus.loading => const AppSkeletonList(),
            TogetherStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(const TogetherEvent.started()),
            ),
            TogetherStatus.ready => RefreshIndicator(
              onRefresh: () async => bloc.add(const TogetherEvent.refreshed()),
              child: _Body(state: state),
            ),
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final TogetherState state;

  Future<void> _newChallenge(BuildContext context) async {
    final bloc = context.read<TogetherBloc>();
    await context.push(SocialPaths.togetherNewChallenge);
    bloc.add(const TogetherEvent.refreshed());
  }

  Future<void> _proposeStreak(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<TogetherBloc>();
    final friendId = await showFriendPickerSheet(
      context,
      title: l10n.togetherStreakPickTitle,
      confirmLabel: l10n.togetherStreakPropose,
    );
    if (friendId != null) bloc.add(TogetherEvent.streakProposed(friendId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final o = state.overview;
    final invitedChallenges = o.challenges.where((c) => c.invitation).toList();
    final invitedStreaks = o.streaks.where((s) => s.invitation).toList();
    final invitedWorkouts = o.workouts.where((w) => w.invitation).toList();
    final hasInvitations =
        invitedChallenges.isNotEmpty ||
        invitedStreaks.isNotEmpty ||
        invitedWorkouts.isNotEmpty;
    final challenges = o.challenges.where((c) => !c.invitation).toList();
    final streaks = o.streaks.where((s) => !s.invitation).toList();
    final workouts = o.workouts.where((w) => !w.invitation).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xxl,
      ),
      children: [
        AppContentWidth.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHelpToggle(
                help: l10n.togetherHelp,
                tooltip: l10n.commonHelpAbout(l10n.togetherTitle),
                child: Text(
                  l10n.togetherIntro,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (o.isEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                AppEmptyState(
                  icon: AppIcons.friends,
                  title: l10n.togetherEmptyTitle,
                  message: l10n.togetherEmptyMessage,
                  action: AppPrimaryButton(
                    label: l10n.togetherNewChallenge,
                    icon: AppIcons.add,
                    onPressed: () => _newChallenge(context),
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
                AppSecondaryButton(
                  label: l10n.togetherStreakPropose,
                  icon: const Icon(AppIcons.streak),
                  onPressed: () => _proposeStreak(context),
                ),
              ] else ...[
                if (hasInvitations) ...[
                  const SizedBox(height: TokensSpacing.m),
                  AppSectionHeader(title: l10n.togetherInvitations),
                  for (final c in invitedChallenges)
                    _InvitationCard(
                      text: l10n.togetherInvitedChallenge(
                        togetherName(context, c.creator.name),
                        c.title,
                      ),
                      busy: state.busyId == c.id,
                      onOpen: () =>
                          context.push(SocialPaths.togetherChallenge(c.id)),
                      onJoin: () => context.read<TogetherBloc>().add(
                        TogetherEvent.challengeJoined(c.id),
                      ),
                      onDecline: () => context.read<TogetherBloc>().add(
                        TogetherEvent.challengeDeclined(c.id),
                      ),
                    ),
                  for (final s in invitedStreaks)
                    _InvitationCard(
                      text: l10n.togetherInvitedStreak(
                        togetherName(context, s.friend.name),
                      ),
                      busy: state.busyId == s.id,
                      onJoin: () => context.read<TogetherBloc>().add(
                        TogetherEvent.streakAccepted(s.id),
                      ),
                      onDecline: () => context.read<TogetherBloc>().add(
                        TogetherEvent.streakDeclined(s.id),
                      ),
                    ),
                  for (final w in invitedWorkouts)
                    _InvitationCard(
                      text: l10n.togetherInvitedWorkout(
                        togetherName(context, w.host.name),
                        w.routineName ?? l10n.togetherWorkoutTitle,
                      ),
                      busy: state.busyId == w.id,
                      onOpen: () =>
                          context.push(SocialPaths.togetherWorkout(w.id)),
                      onJoin: () => context.read<TogetherBloc>().add(
                        TogetherEvent.workoutJoined(w.id),
                      ),
                      onDecline: () => context.read<TogetherBloc>().add(
                        TogetherEvent.workoutDeclined(w.id),
                      ),
                    ),
                ],
                const SizedBox(height: TokensSpacing.m),
                AppSectionHeader(
                  title: l10n.togetherChallengesSection,
                  actionLabel: l10n.togetherNewChallenge,
                  onAction: () => _newChallenge(context),
                ),
                if (challenges.isEmpty)
                  _EmptyLine(text: l10n.togetherChallengesEmpty)
                else
                  for (final c in challenges) _ChallengeCard(challenge: c),
                const SizedBox(height: TokensSpacing.m),
                AppSectionHeader(
                  title: l10n.togetherStreaksSection,
                  actionLabel: l10n.togetherStreakPropose,
                  onAction: () => _proposeStreak(context),
                ),
                if (streaks.isEmpty)
                  _EmptyLine(text: l10n.togetherStreaksEmpty)
                else
                  for (final s in streaks)
                    _StreakTile(streak: s, busy: state.busyId == s.id),
                const SizedBox(height: TokensSpacing.m),
                AppSectionHeader(title: l10n.togetherWorkoutsSection),
                if (workouts.isEmpty)
                  _EmptyLine(text: l10n.togetherWorkoutsEmpty)
                else
                  for (final w in workouts) _WorkoutTile(workout: w),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
    child: Text(
      text,
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

/// Invitación: lo que es y «Unirme» / «No, gracias».
class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.text,
    required this.busy,
    required this.onJoin,
    required this.onDecline,
    this.onOpen,
  });

  final String text;
  final bool busy;
  final VoidCallback onJoin;
  final VoidCallback onDecline;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: AppCard(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: context.textStyles.bodyLarge),
            const SizedBox(height: TokensSpacing.s),
            Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.xs,
              children: [
                AppSecondaryButton(
                  label: l10n.togetherJoin,
                  loading: busy,
                  onPressed: busy ? null : onJoin,
                ),
                TextButton(
                  onPressed: busy ? null : onDecline,
                  child: Text(l10n.togetherDecline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final FriendChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final c = challenge;
    final bloc = context.read<TogetherBloc>();
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: AppCard(
        onTap: () async {
          await context.push(SocialPaths.togetherChallenge(c.id));
          bloc.add(const TogetherEvent.refreshed());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.title, style: context.textStyles.titleMedium),
                ),
                AppPill(label: c.mode.label(context)),
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            if (c.mode == FriendChallengeMode.cooperative)
              TogetherProgressBar(
                value: c.groupTotal,
                target: c.groupTarget,
                label: l10n.togetherGroupProgress(c.groupTotal, c.groupTarget),
              )
            else
              Text(
                l10n.togetherMyPoints(c.myPoints),
                style: context.textStyles.bodyMedium,
              ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              c.over
                  ? l10n.togetherChallengeOver
                  : l10n.togetherChallengeUntil(
                      DateFormat.MMMEd(
                        context.localizations.localeName,
                      ).format(c.endAt),
                    ),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Racha con un amigo: días, cómo va hoy y «Recordárselo» si toca.
class _StreakTile extends StatelessWidget {
  const _StreakTile({required this.streak, required this.busy});

  final FriendStreak streak;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = streak;
    final name = togetherName(context, s.friend.name);
    final bloc = context.read<TogetherBloc>();
    final String status;
    if (s.status == FriendStreakStatus.pending) {
      status = l10n.togetherStreakWaiting(name);
    } else if (s.paused) {
      status = l10n.togetherStreakPaused;
    } else if (s.meDone && s.friendDone) {
      status = l10n.togetherStreakBothDone;
    } else if (!s.meDone) {
      status = l10n.togetherStreakMyPart;
    } else {
      status = l10n.togetherStreakFriendPart(name);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: AppAvatar(name: name, imageUrl: s.friend.avatarUrl),
          title: Text(
            s.status == FriendStreakStatus.active
                ? l10n.togetherStreakWith(name, s.days)
                : l10n.togetherStreakProposedTo(name),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status),
              if (s.canNudge)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => bloc.add(TogetherEvent.streakNudged(s.id)),
                  child: Text(l10n.togetherNudge),
                ),
            ],
          ),
          trailing: TogetherMemberMenu(
            person: s.friend,
            reportContext: UserReportContext.friendStreak,
            endLabel: s.status == FriendStreakStatus.active
                ? l10n.togetherStreakEnd
                : l10n.togetherStreakWithdraw,
            onEnd: () => _end(context),
          ),
        ),
      ),
    );
  }

  /// Terminar una racha la pierde para siempre: se confirma con el verbo exacto.
  Future<void> _end(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<TogetherBloc>();
    if (streak.status == FriendStreakStatus.active) {
      final ok = await showConfirmDialog(
        context,
        title: l10n.togetherStreakEndTitle,
        message: l10n.togetherStreakEndMessage(
          togetherName(context, streak.friend.name),
        ),
        confirmLabel: l10n.togetherStreakEnd,
      );
      if (!ok) return;
    }
    bloc.add(
      streak.status == FriendStreakStatus.active
          ? TogetherEvent.streakEnded(streak.id)
          : TogetherEvent.streakWithdrawn(streak.id),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.workout});

  final WorkoutTogether workout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final w = workout;
    final bloc = context.read<TogetherBloc>();
    final people = [
      for (final m in w.members)
        if (m.status == TogetherMemberStatus.joined) m.person,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: AppCard(
        onTap: () async {
          await context.push(SocialPaths.togetherWorkout(w.id));
          bloc.add(const TogetherEvent.refreshed());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              w.routineName ?? l10n.togetherWorkoutTitle,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: TokensSpacing.xs),
            TogetherAvatars(people: people),
          ],
        ),
      ),
    );
  }
}
