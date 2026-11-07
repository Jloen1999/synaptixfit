import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/routine_summary_card.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../bloc/community_bloc.dart';

/// Rutinas de la comunidad (públicas y de amigos).
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CommunityBloc>()..add(const CommunityEvent.started()),
      child: const _CommunityView(),
    );
  }
}

class _CommunityView extends StatefulWidget {
  const _CommunityView();

  @override
  State<_CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<_CommunityView> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<CommunityBloc>().add(CommunityEvent.queryChanged(text));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CommunityBloc, CommunityState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        final bloc = context.read<CommunityBloc>();
        return Scaffold(
          appBar: AppPageBar(title: Text(l10n.trainingCommunityTitle)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.s,
                  TokensSpacing.m,
                  0,
                ),
                child: TrainingContent(
                  child: AppSearchField(
                    label: l10n.trainingSearchRoutines,
                    onChanged: _onQuery,
                  ),
                ),
              ),
              SizedBox(
                height: context.scaled(56),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensSpacing.m,
                    vertical: TokensSpacing.xs,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: TokensSpacing.xs),
                      child: ChoiceChip(
                        label: Text(l10n.trainingAllGoals),
                        selected: state.goal == null,
                        onSelected: (_) =>
                            bloc.add(const CommunityEvent.goalChanged(null)),
                      ),
                    ),
                    for (final g in TrainingGoal.values)
                      Padding(
                        padding: const EdgeInsets.only(right: TokensSpacing.xs),
                        child: ChoiceChip(
                          label: Text(g.label(l10n)),
                          selected: state.goal == g,
                          onSelected: (_) =>
                              bloc.add(CommunityEvent.goalChanged(g)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: switch (state.status) {
                  CommunityStatus.loading => const AppSkeletonList(height: 120),
                  CommunityStatus.failure => AppErrorView(
                    error: state.error!,
                    onRetry: () => bloc.add(const CommunityEvent.refreshed()),
                  ),
                  // Con algo escrito, «sin resultados» y no «la comunidad
                  // está vacía» (vocabulario, fila Buscador).
                  CommunityStatus.ready
                      when state.items.isEmpty && state.query.trim().isNotEmpty =>
                    AppSearchEmpty(query: state.query),
                  CommunityStatus.ready when state.items.isEmpty =>
                    AppEmptyState(
                      icon: Icons.groups_rounded,
                      title: l10n.trainingCommunityEmptyTitle,
                      message: l10n.trainingCommunityEmptyMessage,
                    ),
                  CommunityStatus.ready => RefreshIndicator(
                    onRefresh: () async {
                      bloc.add(const CommunityEvent.refreshed());
                      await bloc.stream.firstWhere((s) => !s.refreshing);
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 300) {
                          bloc.add(const CommunityEvent.moreRequested());
                        }
                        return false;
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(TokensSpacing.m),
                        itemCount:
                            state.items.length + (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: TokensSpacing.s),
                        itemBuilder: (context, i) {
                          if (i >= state.items.length) {
                            return const AppLoadingView();
                          }
                          final r = state.items[i];
                          final cloning = state.cloningId == r.id;
                          return TrainingContent(
                            child: RoutineSummaryCard(
                              routine: r,
                              showAuthor: true,
                              onTap: () =>
                                  context.push(TrainingPaths.routine(r.id)),
                              trailing: cloning
                                  ? const Padding(
                                      padding: EdgeInsets.all(TokensSpacing.s),
                                      child: SizedBox.square(
                                        dimension: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      tooltip: l10n.trainingClone,
                                      onPressed: state.cloningId != null
                                          ? null
                                          : () => bloc.add(
                                              CommunityEvent.cloneRequested(
                                                r.id,
                                              ),
                                            ),
                                      icon: const Icon(Icons.download_rounded),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
