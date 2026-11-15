import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../../app/di/app_di.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../extensions/context_extensions.dart';
import '../../../../../mixins/errors_message_mixin.dart';
import '../../../../../theme/tokens.g.dart';
import '../../../../../widgets/widgets.dart';
import '../../widgets/together_labels.dart';
import '../../widgets/together_widgets.dart';
import '../bloc/friend_challenge_detail_bloc.dart';

/// Reto con amigos (ADR 0044): cómo va el grupo (o la clasificación en
/// competición), quién está y el tablón con reacciones fijas. Salir es un
/// toque con «Deshacer».
class FriendChallengeDetailPage extends StatelessWidget {
  const FriendChallengeDetailPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<FriendChallengeDetailBloc>()
                ..add(FriendChallengeDetailEvent.started(challengeId)),
        ),
        BlocProvider(create: (_) => createSafetyBloc()),
      ],
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget with ErrorsMessageMixin {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<FriendChallengeDetailBloc>();
    return TogetherSafetyListener(
      onBlocked: (blockedId) {
        // Si era quien lo creó, ya no se está en el reto: se cierra.
        if (bloc.state.challenge?.creator.id == blockedId) {
          Navigator.of(context).maybePop();
        } else {
          bloc.add(FriendChallengeDetailEvent.started(bloc.state.id!));
        }
      },
      child:
          BlocConsumer<FriendChallengeDetailBloc, FriendChallengeDetailState>(
            listenWhen: (p, c) =>
                (c.effect != null && c.effect != p.effect) ||
                (c.actionError != null && c.actionError != p.actionError),
            listener: (context, state) {
              if (state.actionError case final error?) {
                context.showSnack(errorMessage(context, error));
                return;
              }
              final navigator = Navigator.of(context);
              switch (state.effect!) {
                case FriendChallengeDetailEffect.declined:
                  context.showSnack(l10n.togetherDeclined);
                  navigator.pop();
                case FriendChallengeDetailEffect.left:
                  context.showUndoSnack(
                    l10n.togetherLeftChallenge,
                    onUndo: () =>
                        bloc.add(const FriendChallengeDetailEvent.joined()),
                    onCommit: () {
                      if (navigator.mounted && navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                  );
              }
            },
            builder: (context, state) {
              final c = state.challenge;
              return Scaffold(
                appBar: AppPageBar.reading(
                  title: Text(c?.title ?? l10n.togetherChallengeTitle),
                ),
                body: switch (state.status) {
                  FriendChallengeDetailStatus.loading =>
                    const AppSkeletonList(),
                  FriendChallengeDetailStatus.failure => AppErrorView(
                    error: state.error!,
                    onRetry: () =>
                        bloc.add(FriendChallengeDetailEvent.started(state.id!)),
                  ),
                  FriendChallengeDetailStatus.ready => RefreshIndicator(
                    onRefresh: () async =>
                        bloc.add(const FriendChallengeDetailEvent.refreshed()),
                    child: _Body(challenge: c!, busy: state.busy),
                  ),
                },
              );
            },
          ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.challenge, required this.busy});

  final FriendChallenge challenge;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final c = challenge;
    final bloc = context.read<FriendChallengeDetailBloc>();
    final joined = c.myStatus == TogetherMemberStatus.joined;
    final reached = c.groupTotal >= c.groupTarget;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
              if (c.goal.isNotEmpty)
                Text(c.goal, style: context.textStyles.bodyLarge),
              const SizedBox(height: TokensSpacing.s),
              Wrap(
                spacing: TokensSpacing.xs,
                runSpacing: TokensSpacing.xs,
                children: [
                  AppPill(label: c.mode.label(context)),
                  AppPill(
                    icon: AppIcons.calendar,
                    label: c.over
                        ? l10n.togetherChallengeOver
                        : l10n.togetherChallengeUntil(
                            DateFormat.MMMEd(
                              context.localizations.localeName,
                            ).format(c.endAt),
                          ),
                  ),
                  if (c.over &&
                      reached &&
                      c.mode == FriendChallengeMode.cooperative)
                    AppPill(
                      icon: AppIcons.done,
                      label: l10n.togetherGoalReached,
                      color: context.palette.success,
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              if (c.invitation)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.togetherInvitedBy(
                          togetherName(context, c.creator.name),
                        ),
                        style: context.textStyles.bodyLarge,
                      ),
                      const SizedBox(height: TokensSpacing.s),
                      AppPrimaryButton(
                        label: l10n.togetherJoin,
                        loading: busy,
                        onPressed: () =>
                            bloc.add(const FriendChallengeDetailEvent.joined()),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => bloc.add(
                                const FriendChallengeDetailEvent.declined(),
                              ),
                        child: Text(l10n.togetherDecline),
                      ),
                    ],
                  ),
                )
              else if (c.mode == FriendChallengeMode.cooperative) ...[
                TogetherProgressBar(
                  value: c.groupTotal,
                  target: c.groupTarget,
                  label: l10n.togetherGroupProgress(
                    c.groupTotal,
                    c.groupTarget,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  l10n.togetherMyProgress(c.myPoints, c.myTarget),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(
                title: c.mode == FriendChallengeMode.competition
                    ? l10n.togetherRanking
                    : l10n.togetherPeople,
              ),
              for (final m in c.members) _MemberRow(member: m),
              if (joined) ...[
                const SizedBox(height: TokensSpacing.m),
                AppSectionHeader(title: l10n.togetherBoard),
                if (c.board.isEmpty)
                  Text(
                    l10n.togetherBoardEmpty,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else
                  for (final e in c.board) _BoardEntry(entry: e, busy: busy),
                // Terminado ya no se sale (y «Deshacer» no podría volver).
                if (!c.over) ...[
                  const SizedBox(height: TokensSpacing.l),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => bloc.add(
                              const FriendChallengeDetailEvent.left(),
                            ),
                      icon: const Icon(AppIcons.leave),
                      label: Text(l10n.togetherLeaveChallenge),
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

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final FriendChallengeMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final m = member;
    final name = togetherName(context, m.person.name);
    final mine = m.me;
    final String status;
    if (m.status == TogetherMemberStatus.invited) {
      status = l10n.togetherMemberInvited;
    } else if (m.points != null) {
      status = l10n.togetherPoints(m.points!);
    } else {
      status = m.contributed
          ? l10n.togetherContributed
          : l10n.togetherNotYetContributed;
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppAvatar(name: name, imageUrl: m.person.avatarUrl),
      title: Text(mine ? l10n.togetherYou : name),
      subtitle: Text(status),
      trailing: mine
          ? null
          : TogetherMemberMenu(
              person: m.person,
              reportContext: UserReportContext.friendChallenge,
            ),
    );
  }
}

/// Entrada del tablón: «Ana sumó el lun 16». En las de otros, las cuatro
/// reacciones fijas (la elegida, marcada); en las mías, cuántas tengo.
class _BoardEntry extends StatelessWidget {
  const _BoardEntry({required this.entry, required this.busy});

  final FriendChallengeBoardEntry entry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = entry;
    final name = togetherName(context, e.person.name);
    final day = DateFormat.MMMEd(
      context.localizations.localeName,
    ).format(e.day);
    final bloc = context.read<FriendChallengeDetailBloc>();
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppAvatar(name: name, imageUrl: e.person.avatarUrl),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    e.mine
                        ? l10n.togetherBoardMine(day)
                        : l10n.togetherBoardEntry(name, day),
                    style: context.textStyles.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.xs),
            if (e.mine)
              e.counts.isEmpty
                  ? Text(
                      l10n.togetherNoReactionsYet,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  : Wrap(
                      spacing: TokensSpacing.xs,
                      children: [
                        for (final MapEntry(:key, :value) in e.counts.entries)
                          AppPill(
                            label: '${key.emoji} $value',
                            semanticLabel: l10n.togetherReactionCount(
                              key.label(context),
                              value,
                            ),
                          ),
                      ],
                    )
            else
              Wrap(
                spacing: TokensSpacing.xs,
                children: [
                  for (final r in TogetherReaction.values)
                    ChoiceChip(
                      label: Text(
                        r.emoji,
                        semanticsLabel: l10n.togetherReactTo(
                          r.label(context),
                          name,
                        ),
                      ),
                      selected: e.myReaction == r,
                      onSelected: busy
                          ? null
                          : (_) => bloc.add(
                              FriendChallengeDetailEvent.reactionTapped(e, r),
                            ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
