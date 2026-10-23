import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/challenge_status.dart';
import '../../../../../domain/enums/challenge_tasks_filter.dart';
import '../../../../../domain/enums/challenge_type.dart';
import '../../../../../domain/models/challenges/challenge_query.dart';
import '../../../../../domain/models/challenges/challenge_summary.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../challenges_routes.dart';
import '../../community_challenges/bloc/community_challenges_bloc.dart';
import '../../community_challenges/page/community_challenges_page.dart';
import '../../quick_challenge/page/quick_challenge_sheet.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/challenge_content_width.dart';
import '../../widgets/challenge_feedback.dart';
import '../../widgets/challenge_focus.dart';
import '../../widgets/challenge_labels.dart';
import '../../widgets/pending_milestone_tile.dart';
import '../bloc/challenges_list_bloc.dart';

/// Pestaña Retos: «Mis retos» y «Comunidad», con FAB «Nuevo reto».
class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ChallengesListBloc>()
                ..add(const ChallengesListEvent.started()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<CommunityChallengesBloc>()
                ..add(const CommunityChallengesEvent.started()),
        ),
      ],
      child: const _ChallengesView(),
    );
  }
}

class _ChallengesView extends StatelessWidget {
  const _ChallengesView();

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<ChallengesListBloc>();
    final result = await showQuickChallengeSheet(context);
    if (!context.mounted || result == null) return;
    context.showSnack(context.localizations.challengesCreated);
    bloc.add(const ChallengesListEvent.refreshed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppPageBar(
          title: Text(l10n.challengesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.challengesTabMine),
              Tab(text: l10n.challengesTabCommunity),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _create(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.challengesNew),
        ),
        body: const TabBarView(
          children: [_MineTab(), CommunityChallengesView()],
        ),
      ),
    );
  }
}

class _MineTab extends StatefulWidget {
  const _MineTab();

  @override
  State<_MineTab> createState() => _MineTabState();
}

class _MineTabState extends State<_MineTab> with ErrorsMessageMixin {
  /// Retos a partir de los que se muestra el buscador.
  static const _searchThreshold = 5;

  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  ChallengesListBloc get _bloc => context.read<ChallengesListBloc>();

  void _setQuery(ChallengeQuery query) =>
      _bloc.add(ChallengesListEvent.queryChanged(query));

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _setQuery(_bloc.state.query.copyWith(search: value.trim()));
    });
  }

  Future<void> _open(String challengeId) async {
    await context.push(ChallengesPaths.detail(challengeId));
    if (mounted) _bloc.add(const ChallengesListEvent.refreshed());
  }

  void _onEffect(BuildContext context, ChallengesListEffect effect) {
    final l10n = context.localizations;
    switch (effect) {
      case ChallengesListMilestoneCompleted(
        :final xpDelta,
        :final unlockedCount,
        :final challengeCompleted,
        :final account,
      ):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        context.showSnack(
          challengeFeedbackMessage(
            context,
            base: challengeCompleted
                ? l10n.challengesChallengeDone
                : l10n.challengesMilestoneDone,
            xpDelta: xpDelta,
            unlockedCount: unlockedCount,
          ),
        );
      case ChallengesListActionFailed(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChallengesListBloc, ChallengesListState>(
      listenWhen: (_, s) => s.effect != null,
      listener: (context, state) => _onEffect(context, state.effect!),
      builder: (context, state) {
        if (state.status == ChallengesListStatus.loading) {
          return const _LoadingList();
        }
        if (state.status == ChallengesListStatus.failure &&
            state.challenges.isEmpty) {
          return AppErrorView(
            error: state.error!,
            onRetry: () => _bloc.add(const ChallengesListEvent.started()),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              _bloc.add(const ChallengesListEvent.loadMoreRequested());
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              _bloc.add(const ChallengesListEvent.refreshed());
              await _bloc.stream.firstWhere((s) => !s.listLoading);
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
                      if (state.pending.isNotEmpty) ...[
                        AppSectionHeader(
                          title: context.localizations.challengesPendingTitle,
                        ),
                        for (final p in state.pending)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensSpacing.s,
                            ),
                            child: PendingMilestoneTile(
                              pending: p,
                              busy: state.busyMilestoneIds.contains(
                                p.milestone.id,
                              ),
                              onComplete: () => _bloc.add(
                                ChallengesListEvent.pendingCompleted(p),
                              ),
                              onOpen: () => _open(p.challengeId),
                            ),
                          ),
                        const SizedBox(height: TokensSpacing.l),
                      ],
                      AppSectionHeader(
                        title: context.localizations.challengesListTitle,
                        actionLabel: state.query.isFiltered
                            ? context.localizations.challengesFilterClear
                            : null,
                        onAction: () {
                          _search.clear();
                          _setQuery(const ChallengeQuery());
                        },
                      ),
                      // El buscador solo aparece cuando hay bastantes retos
                      // (o ya hay una búsqueda escrita): con pocos, estorba.
                      if (state.summary.total > _searchThreshold ||
                          _search.text.isNotEmpty) ...[
                        _SearchField(
                          controller: _search,
                          onChanged: _onSearch,
                          onClear: () {
                            _search.clear();
                            _setQuery(state.query.copyWith(search: null));
                          },
                        ),
                        const SizedBox(height: TokensSpacing.s),
                      ],
                      _Filters(
                        query: state.query,
                        summary: state.summary,
                        onChanged: _setQuery,
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      ..._listContent(context, state),
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

  List<Widget> _listContent(BuildContext context, ChallengesListState state) {
    final l10n = context.localizations;
    if (state.listLoading) {
      return [
        AppSkeletonGroup(
          child: Column(
            children: [
              for (var i = 0; i < 3; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: TokensSpacing.s),
                  child: AppSkeleton(height: 132),
                ),
            ],
          ),
        ),
      ];
    }
    if (state.status == ChallengesListStatus.failure) {
      return [
        AppErrorView(
          error: state.error!,
          onRetry: () => _bloc.add(const ChallengesListEvent.refreshed()),
        ),
      ];
    }
    if (state.challenges.isEmpty) {
      final filtered = state.query.isFiltered;
      return [
        AppEmptyState(
          icon: Icons.flag_outlined,
          title: filtered
              ? l10n.challengesEmptyFilteredTitle
              : l10n.challengesEmptyTitle,
          message: filtered
              ? l10n.challengesEmptyFilteredMessage
              : l10n.challengesEmptyMessage,
          // Sin filtros no hay botón propio: «Nuevo reto» ya es el botón
          // flotante, y dos acciones iguales juntas confunden.
          action: filtered
              ? AppSecondaryButton(
                  label: l10n.challengesFilterClear,
                  onPressed: () {
                    _search.clear();
                    _setQuery(const ChallengeQuery());
                  },
                )
              : null,
        ),
      ];
    }
    return [
      for (final c in state.challenges)
        Padding(
          padding: const EdgeInsets.only(bottom: TokensSpacing.s),
          child: ChallengeCard(challenge: c, onTap: () => _open(c.id)),
        ),
      if (state.loadingMore)
        const Padding(
          padding: EdgeInsets.all(TokensSpacing.m),
          child: AppLoadingView(),
        ),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: l10n.challengesSearchHint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.challengesSearchClear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
        ),
      ),
    );
  }
}

/// Filtros del listado. Los de estado, con su número, quedan a la vista (así
/// no hace falta una fila aparte de cifras); tipo y tareas van en la hoja de
/// «Filtros» para que la fila no se llene de chips.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.query,
    required this.summary,
    required this.onChanged,
  });

  final ChallengeQuery query;
  final ChallengeSummary summary;
  final ValueChanged<ChallengeQuery> onChanged;

  Future<void> _openSheet(BuildContext context, List<ChallengeType> types) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => BlocProvider.value(
          value: context.read<ChallengesListBloc>(),
          child: _FiltersSheet(types: types),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // Con un solo enfoque no hay tipos entre los que filtrar.
    final allowed = context.allowedChallengeTypes;
    final types = allowed.length > 1 ? allowed : const <ChallengeType>[];
    final extra = _FiltersSheet.activeCount(query, types);
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: TokensSpacing.s),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(
                  l10n.challengesFilterAll,
                  query.status == null,
                  () => onChanged(query.copyWith(status: null)),
                ),
                for (final s in ChallengeStatus.values)
                  chip(
                    l10n.challengesFilterWithCount(
                      s.pluralLabel(context),
                      switch (s) {
                        ChallengeStatus.active => summary.active,
                        ChallengeStatus.completed => summary.completed,
                        ChallengeStatus.expired => summary.expired,
                      },
                    ),
                    query.status == s,
                    () => onChanged(
                      query.copyWith(status: query.status == s ? null : s),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // El número de filtros activos va en la propia etiqueta («Filtros
        // (2)»): se ve y el lector de pantalla lo lee, sin depender del color.
        ActionChip(
          avatar: const Icon(Icons.tune_rounded),
          label: Text(
            extra > 0
                ? l10n.challengesFilterWithCount(l10n.challengesFilters, extra)
                : l10n.challengesFilters,
          ),
          backgroundColor: extra > 0 ? context.colors.primaryContainer : null,
          onPressed: () => _openSheet(context, types),
        ),
      ],
    );
  }
}

/// Hoja de filtros secundarios (tipo y tareas). Lee y cambia la consulta del
/// [ChallengesListBloc] en vivo: el listado de detrás se actualiza al tocar.
class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet({required this.types});

  /// Tipos entre los que elegir; vacío si el enfoque solo permite uno.
  final List<ChallengeType> types;

  /// Filtros de la hoja que están activos (el de tipo solo cuenta si se ve).
  static int activeCount(ChallengeQuery q, List<ChallengeType> types) =>
      (types.isNotEmpty && q.type != null ? 1 : 0) + (q.tasks != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<ChallengesListBloc>();
    void update(ChallengeQuery Function(ChallengeQuery) change) =>
        bloc.add(ChallengesListEvent.queryChanged(change(bloc.state.query)));
    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.textStyles.titleSmall),
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: chips,
          ),
        ],
      ),
    );
    return BlocSelector<
      ChallengesListBloc,
      ChallengesListState,
      ChallengeQuery
    >(
      selector: (state) => state.query,
      builder: (context, query) {
        final tasks = query.tasks;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.m,
              0,
              TokensSpacing.m,
              TokensSpacing.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.challengesFilters,
                    style: context.textStyles.titleLarge,
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
                if (types.isNotEmpty)
                  section(l10n.challengesFieldType, [
                    for (final t in types)
                      FilterChip(
                        label: Text(t.label(context)),
                        selected: query.type == t,
                        onSelected: (_) => update(
                          (q) => q.copyWith(type: q.type == t ? null : t),
                        ),
                      ),
                  ]),
                section(l10n.challengesFormSectionTasks, [
                  for (final (filter, label) in [
                    (
                      ChallengeTasksFilter.withTasks,
                      l10n.challengesFilterWithTasks,
                    ),
                    (
                      ChallengeTasksFilter.withoutTasks,
                      l10n.challengesFilterWithoutTasks,
                    ),
                  ])
                    FilterChip(
                      label: Text(label),
                      selected: tasks == filter,
                      onSelected: (_) => update(
                        (q) => q.copyWith(
                          tasks: q.tasks == filter ? null : filter,
                        ),
                      ),
                    ),
                ]),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: TokensSpacing.s,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: [
                    if (activeCount(query, types) > 0)
                      TextButton(
                        onPressed: () =>
                            update((q) => q.copyWith(type: null, tasks: null)),
                        child: Text(l10n.challengesFilterClear),
                      ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonClose),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonGroup(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: const [
          ChallengeContentWidth(
            child: Column(
              children: [
                AppSkeleton(height: 104),
                SizedBox(height: TokensSpacing.l),
                AppSkeleton(height: 64),
                SizedBox(height: TokensSpacing.s),
                AppSkeleton(height: 64),
                SizedBox(height: TokensSpacing.l),
                AppSkeleton(height: 132),
                SizedBox(height: TokensSpacing.s),
                AppSkeleton(height: 132),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
