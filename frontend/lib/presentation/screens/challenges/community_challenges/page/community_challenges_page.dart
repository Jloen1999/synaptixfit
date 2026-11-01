import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/challenge_type.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../challenges_routes.dart';
import '../../widgets/challenge_focus.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/challenge_content_width.dart';
import '../../widgets/challenge_labels.dart';
import '../bloc/community_challenges_bloc.dart';

/// Pantalla completa de retos de la comunidad (`/challenges/community`).
class CommunityChallengesPage extends StatelessWidget {
  const CommunityChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CommunityChallengesBloc>()
            ..add(const CommunityChallengesEvent.started()),
      child: Scaffold(
        appBar: AppPageBar(
          title: Text(context.localizations.challengesTabCommunity),
        ),
        body: const CommunityChallengesView(),
      ),
    );
  }
}

/// Listado de retos de otros usuarios. Necesita un [CommunityChallengesBloc]
/// por encima (lo usa también la pestaña «Comunidad»).
class CommunityChallengesView extends StatefulWidget {
  const CommunityChallengesView({super.key});

  @override
  State<CommunityChallengesView> createState() =>
      _CommunityChallengesViewState();
}

class _CommunityChallengesViewState extends State<CommunityChallengesView>
    with ErrorsMessageMixin {
  final _search = TextEditingController();
  Timer? _debounce;

  CommunityChallengesBloc get _bloc => context.read<CommunityChallengesBloc>();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _filter({ChallengeType? type, String? search}) => _bloc.add(
    CommunityChallengesEvent.filtersChanged(type: type, search: search),
  );

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _filter(type: _bloc.state.type, search: value.trim());
    });
  }

  void _onEffect(BuildContext context, CommunityChallengesEffect effect) {
    switch (effect) {
      case CommunityChallengeCloned(:final challenge):
        context.showActionSnack(
          context.localizations.challengesCloned,
          actionLabel: context.localizations.challengesViewCloned,
          onAction: () => context.push(ChallengesPaths.detail(challenge.id)),
        );
      case CommunityChallengesActionFailed(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CommunityChallengesBloc, CommunityChallengesState>(
      listenWhen: (_, s) => s.effect != null,
      listener: (context, state) => _onEffect(context, state.effect!),
      builder: (context, state) {
        if (state.status == CommunityChallengesStatus.failure &&
            state.challenges.isEmpty) {
          return AppErrorView(
            error: state.error!,
            onRetry: () => _bloc.add(const CommunityChallengesEvent.started()),
          );
        }
        final loading =
            state.status == CommunityChallengesStatus.loading ||
            state.listLoading;
        final filtered =
            state.type != null || (state.search?.trim().isNotEmpty ?? false);
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              _bloc.add(const CommunityChallengesEvent.loadMoreRequested());
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              _bloc.add(const CommunityChallengesEvent.refreshed());
              await _bloc.stream.first;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                TokensSpacing.m,
                TokensSpacing.m,
                TokensSpacing.xxl * 2,
              ),
              children: [
                ChallengeContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Qué es esta pestaña y qué hacer en ella, de un vistazo.
                      Text(
                        l10n.challengesCommunityIntro,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      ValueListenableBuilder(
                        valueListenable: _search,
                        builder: (context, value, _) => TextField(
                          controller: _search,
                          onChanged: _onSearch,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: l10n.challengesSearchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: value.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.challengesSearchClear,
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      _search.clear();
                                      _filter(type: state.type, search: '');
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.s),
                      Wrap(
                        spacing: TokensSpacing.s,
                        runSpacing: TokensSpacing.xs,
                        children: [
                          FilterChip(
                            label: Text(l10n.challengesFilterAll),
                            selected: state.type == null,
                            onSelected: (_) => _filter(search: state.search),
                          ),
                          if (context.allowedChallengeTypes.length > 1)
                            for (final t in context.allowedChallengeTypes)
                              FilterChip(
                                avatar: Icon(t.icon, size: TokensSize.iconXs),
                                label: Text(t.label(context)),
                                selected: state.type == t,
                                onSelected: (_) => _filter(
                                  type: state.type == t ? null : t,
                                  search: state.search,
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      if (loading)
                        AppSkeletonGroup(
                          child: Column(
                            children: [
                              for (var i = 0; i < 3; i++)
                                const Padding(
                                  padding: EdgeInsets.only(
                                    bottom: TokensSpacing.s,
                                  ),
                                  child: AppSkeleton(height: 132),
                                ),
                            ],
                          ),
                        )
                      else if (state.challenges.isEmpty && filtered)
                        AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: l10n.challengesEmptyFilteredTitle,
                          message: l10n.challengesEmptyFilteredMessage,
                          action: AppSecondaryButton(
                            label: l10n.challengesFilterClear,
                            onPressed: () {
                              _search.clear();
                              _filter(search: '');
                            },
                          ),
                        )
                      else if (state.challenges.isEmpty)
                        AppEmptyState(
                          icon: Icons.groups_outlined,
                          title: l10n.challengesCommunityEmptyTitle,
                          message: l10n.challengesCommunityEmptyMessage,
                        )
                      else ...[
                        for (final c in state.challenges)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensSpacing.s,
                            ),
                            child: ChallengeCard(
                              challenge: c,
                              cloning: state.cloningId == c.id,
                              onTap: () =>
                                  context.push(ChallengesPaths.detail(c.id)),
                              onClone: () => _bloc.add(
                                CommunityChallengesEvent.cloneRequested(c.id),
                              ),
                            ),
                          ),
                        if (state.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(TokensSpacing.m),
                            child: AppLoadingView(),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
